import Foundation

public struct CoreAssembly {
    public let configStore: ConfigStore
    public let keychainStore: KeychainStore
    public let historyStore: HistoryStore
    public let logStore: R2RequestLogStore
    public let uploadService: UploadService

    public init(
        configStore: ConfigStore = .init(),
        keychainStore: KeychainStore = .init(),
        historyStore: HistoryStore = .init(),
        logStore: R2RequestLogStore = .init(),
        uploadService: UploadService? = nil
    ) {
        self.configStore = configStore
        self.keychainStore = keychainStore
        self.historyStore = historyStore
        self.logStore = logStore
        self.uploadService = uploadService ?? .init(client: R2Client(logStore: logStore))
    }

    public func resolvedProfile(
        profileName: String? = nil,
        configURL: URL? = nil,
        includeEnvironmentFallback: Bool = true
    ) throws -> ResolvedProfile {
        do {
            let (name, config) = try configStore.resolveProfile(named: profileName, from: configURL)
            let credentials = try keychainStore.loadCredentials(forProfile: name)
            return ResolvedProfile(name: name, config: config, credentials: credentials)
        } catch let error as UploaderError {
            if includeEnvironmentFallback,
               case .configNotFound = error,
               let profile = try EnvironmentBootstrap.resolvedProfile()
            {
                return profile
            }

            throw error
        }
    }
}
