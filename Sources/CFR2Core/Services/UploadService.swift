import Foundation

public final class UploadService: Sendable {
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

        let contentType = try MIMETypeResolver.resolveImage(for: fileURL)
        let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
        let data = try Data(contentsOf: fileURL)
        let item = UploadItem(
            fileURL: fileURL,
            originalFilename: fileURL.lastPathComponent,
            contentType: contentType,
            fileSize: (attributes[.size] as? NSNumber)?.int64Value ?? Int64(data.count)
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
