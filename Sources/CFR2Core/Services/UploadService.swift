import Foundation

public final class UploadService: Sendable {
    public static let maximumFileSizeInBytes: Int64 = 50 * 1024 * 1024

    private let client: any R2ObjectUploading
    private let keyBuilder: KeyBuilder

    public init(client: any R2ObjectUploading, keyBuilder: KeyBuilder = .init()) {
        self.client = client
        self.keyBuilder = keyBuilder
    }

    public func upload(
        fileURL: URL,
        config: R2Config,
        credentials: R2Credentials
    ) async throws -> UploadResult {
        let filePath = fileURL.path(percentEncoded: false)

        guard FileManager.default.fileExists(atPath: filePath) else {
            throw UploaderError.fileNotFound(fileURL)
        }

        let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
        let fileSize = (attributes[.size] as? NSNumber)?.int64Value ?? 0

        guard fileSize <= Self.maximumFileSizeInBytes else {
            throw UploaderError.fileTooLarge(fileURL, maxSizeInBytes: Self.maximumFileSizeInBytes)
        }

        let contentType = try MIMETypeResolver.resolveContentType(for: fileURL)
        let data = try Data(contentsOf: fileURL)
        let item = UploadItem(
            fileURL: fileURL,
            originalFilename: fileURL.lastPathComponent,
            contentType: contentType,
            fileSize: fileSize == 0 ? Int64(data.count) : fileSize
        )
        let objectKey = keyBuilder.makeObjectKey(fileURL: item.fileURL, keyPrefix: config.keyPrefix)
        let etag = try await client.putObject(
            data: data,
            key: objectKey,
            contentType: item.contentType,
            cacheControl: config.cacheControl,
            config: config,
            credentials: credentials
        )
        let uploadedAt = Date()
        let publicURL = try PublicURLBuilder.build(baseURL: config.publicBaseURL, objectKey: objectKey)

        return UploadResult(
            bucket: config.bucket,
            objectKey: objectKey,
            publicURL: publicURL,
            etag: etag,
            contentType: item.contentType,
            uploadedAt: uploadedAt
        )
    }
}
