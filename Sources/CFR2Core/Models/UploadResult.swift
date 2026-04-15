import Foundation

public struct UploadResult: Sendable, Equatable {
    public var bucket: String
    public var objectKey: String
    public var publicURL: URL
    public var etag: String?
    public var contentType: String
    public var uploadedAt: Date
    public var markdown: String

    public init(
        bucket: String,
        objectKey: String,
        publicURL: URL,
        etag: String?,
        contentType: String,
        uploadedAt: Date
    ) {
        self.bucket = bucket
        self.objectKey = objectKey
        self.publicURL = publicURL
        self.etag = etag
        self.contentType = contentType
        self.uploadedAt = uploadedAt
        self.markdown = "![\(objectKey)](\(publicURL.absoluteString))"
    }
}
