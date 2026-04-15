import Foundation

public struct UploaderConfiguration: Codable, Sendable, Equatable {
    public var version: Int
    public var defaultProfile: String
    public var profiles: [String: R2Config]

    public init(
        version: Int = 1,
        defaultProfile: String = "default",
        profiles: [String: R2Config] = [:]
    ) {
        self.version = version
        self.defaultProfile = defaultProfile
        self.profiles = profiles
    }
}
