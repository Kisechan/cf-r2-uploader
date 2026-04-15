import Foundation

public struct ConfigStore {
    public let fileManager: FileManager
    public let defaultURL: URL

    public init(
        fileManager: FileManager = .default,
        defaultURL: URL = ConfigStore.defaultConfigURL
    ) {
        self.fileManager = fileManager
        self.defaultURL = defaultURL
    }

    public static var applicationSupportDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CFR2Uploader", isDirectory: true)
    }

    public static var defaultConfigURL: URL {
        applicationSupportDirectory.appendingPathComponent("config.json")
    }

    public func load(from explicitURL: URL? = nil) throws -> UploaderConfiguration {
        let url = explicitURL ?? defaultURL
        guard fileManager.fileExists(atPath: url.path()) else {
            throw UploaderError.configNotFound(url)
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let configuration = try decoder.decode(UploaderConfiguration.self, from: data)

        try validate(configuration: configuration)
        return configuration
    }

    public func save(_ configuration: UploaderConfiguration, to explicitURL: URL? = nil) throws {
        try validate(configuration: configuration)

        let url = explicitURL ?? defaultURL
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(configuration)
        try data.write(to: url, options: .atomic)
    }

    public func resolveProfile(named profileName: String?, from explicitURL: URL? = nil) throws -> (String, R2Config) {
        let configuration = try load(from: explicitURL)
        let name = profileName ?? configuration.defaultProfile

        guard let profile = configuration.profiles[name] else {
            throw UploaderError.invalidConfig("找不到 profile=\(name)")
        }

        return (name, profile)
    }

    public func validate(configuration: UploaderConfiguration) throws {
        if configuration.version != 1 {
            throw UploaderError.invalidConfig("仅支持 version=1")
        }

        if configuration.profiles.isEmpty {
            throw UploaderError.invalidConfig("profiles 不能为空")
        }

        if configuration.profiles[configuration.defaultProfile] == nil {
            throw UploaderError.invalidConfig("defaultProfile 不存在")
        }

        for (name, config) in configuration.profiles {
            try ConfigStore.validate(profile: name, config: config)
        }
    }

    public static func validate(profile: String, config: R2Config) throws {
        if profile.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw UploaderError.invalidConfig("profile 名称不能为空")
        }

        if config.accountID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw UploaderError.invalidConfig("[\(profile)] accountID 不能为空")
        }

        if config.bucket.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw UploaderError.invalidConfig("[\(profile)] bucket 不能为空")
        }

        if config.publicBaseURL.host()?.isEmpty != false {
            throw UploaderError.invalidPublicBaseURL(config.publicBaseURL.absoluteString)
        }

        if config.publicBaseURL.scheme.flatMap({ ["http", "https"].contains($0) }) != true {
            throw UploaderError.invalidPublicBaseURL(config.publicBaseURL.absoluteString)
        }
    }
}
