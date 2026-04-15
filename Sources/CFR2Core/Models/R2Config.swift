import Foundation

public struct R2Config: Codable, Sendable, Equatable {
    public var accountID: String
    public var bucket: String
    public var publicBaseURL: URL
    public var keyPrefix: String
    public var defaultOutput: UploadOutputFormat
    public var cacheControl: String

    public init(
        accountID: String,
        bucket: String,
        publicBaseURL: URL,
        keyPrefix: String = "uploads",
        defaultOutput: UploadOutputFormat = .url,
        cacheControl: String = "public, max-age=31536000, immutable"
    ) {
        self.accountID = accountID
        self.bucket = bucket
        self.publicBaseURL = publicBaseURL
        self.keyPrefix = keyPrefix
        self.defaultOutput = defaultOutput
        self.cacheControl = cacheControl
    }

    public var endpointURL: URL {
        URL(string: "https://\(accountID).r2.cloudflarestorage.com")!
    }
}
