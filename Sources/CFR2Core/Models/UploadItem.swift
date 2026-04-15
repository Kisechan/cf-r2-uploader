import Foundation

public struct UploadItem: Sendable, Equatable {
    public var fileURL: URL
    public var originalFilename: String
    public var contentType: String
    public var fileSize: Int64

    public init(
        fileURL: URL,
        originalFilename: String,
        contentType: String,
        fileSize: Int64
    ) {
        self.fileURL = fileURL
        self.originalFilename = originalFilename
        self.contentType = contentType
        self.fileSize = fileSize
    }
}
