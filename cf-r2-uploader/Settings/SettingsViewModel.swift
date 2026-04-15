import Combine
import CFR2Core
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var profileName = "default"
    @Published var accountID = ""
    @Published var bucket = ""
    @Published var publicBaseURL = ""
    @Published var keyPrefix = "uploads"
    @Published var cacheControl = "public, max-age=31536000, immutable"
    @Published var defaultOutput: UploadOutputFormat = .url
    @Published var accessKeyID = ""
    @Published var secretAccessKey = ""
    @Published var statusMessage = ""

    private let configStore: ConfigStore
    private let keychainStore: KeychainStore

    init(
        configStore: ConfigStore = .init(),
        keychainStore: KeychainStore = .init()
    ) {
        self.configStore = configStore
        self.keychainStore = keychainStore
        reload()
    }

    func reload() {
        do {
            let configuration = try configStore.load()
            profileName = configuration.defaultProfile

            if let config = configuration.profiles[configuration.defaultProfile] {
                accountID = config.accountID
                bucket = config.bucket
                publicBaseURL = config.publicBaseURL.absoluteString
                keyPrefix = config.keyPrefix
                cacheControl = config.cacheControl
                defaultOutput = config.defaultOutput
            }

            if let credentials = try? keychainStore.loadCredentials(forProfile: profileName) {
                accessKeyID = credentials.accessKeyID
                secretAccessKey = credentials.secretAccessKey
            }

            statusMessage = ""
        } catch {
            statusMessage = "尚未保存配置，先填写后点击保存。"
        }
    }

    func save() {
        do {
            guard let publicURL = URL(string: publicBaseURL) else {
                throw UploaderError.invalidPublicBaseURL(publicBaseURL)
            }

            let config = R2Config(
                accountID: accountID,
                bucket: bucket,
                publicBaseURL: publicURL,
                keyPrefix: keyPrefix,
                defaultOutput: defaultOutput,
                cacheControl: cacheControl
            )

            let configuration = UploaderConfiguration(
                defaultProfile: profileName,
                profiles: [profileName: config]
            )

            try configStore.save(configuration)
            try keychainStore.save(
                credentials: R2Credentials(accessKeyID: accessKeyID, secretAccessKey: secretAccessKey),
                forProfile: profileName
            )
            statusMessage = "配置已保存到 \(configStore.defaultURL.path())"
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
