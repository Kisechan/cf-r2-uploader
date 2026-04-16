import Foundation

public struct R2RequestLogEntry: Codable, Sendable, Identifiable, Equatable {
    public enum Outcome: String, Codable, Sendable {
        case success
        case failure
    }

    public var id: UUID
    public var timestamp: Date
    public var method: String
    public var requestURL: String
    public var objectKey: String
    public var contentType: String
    public var payloadSize: Int
    public var requestHeaders: [String: String]
    public var statusCode: Int?
    public var responseHeaders: [String: String]
    public var responseBodyPreview: String?
    public var durationMilliseconds: Int
    public var outcome: Outcome
    public var message: String

    public init(
        id: UUID = UUID(),
        timestamp: Date,
        method: String,
        requestURL: String,
        objectKey: String,
        contentType: String,
        payloadSize: Int,
        requestHeaders: [String: String],
        statusCode: Int?,
        responseHeaders: [String: String] = [:],
        responseBodyPreview: String? = nil,
        durationMilliseconds: Int,
        outcome: Outcome,
        message: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.method = method
        self.requestURL = requestURL
        self.objectKey = objectKey
        self.contentType = contentType
        self.payloadSize = payloadSize
        self.requestHeaders = requestHeaders
        self.statusCode = statusCode
        self.responseHeaders = responseHeaders
        self.responseBodyPreview = responseBodyPreview
        self.durationMilliseconds = durationMilliseconds
        self.outcome = outcome
        self.message = message
    }
}
