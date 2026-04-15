import Foundation

public struct UploadHistoryItem: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var fileName: String
    public var objectKey: String
    public var publicURL: URL
    public var uploadedAt: Date

    public init(
        id: UUID = UUID(),
        fileName: String,
        objectKey: String,
        publicURL: URL,
        uploadedAt: Date
    ) {
        self.id = id
        self.fileName = fileName
        self.objectKey = objectKey
        self.publicURL = publicURL
        self.uploadedAt = uploadedAt
    }
}
