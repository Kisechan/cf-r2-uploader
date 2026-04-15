import Foundation

public struct ResolvedProfile: Sendable, Equatable {
    public var name: String
    public var config: R2Config
    public var credentials: R2Credentials

    public init(name: String, config: R2Config, credentials: R2Credentials) {
        self.name = name
        self.config = config
        self.credentials = credentials
    }
}
