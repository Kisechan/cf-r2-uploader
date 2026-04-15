import CFR2Core
import Foundation
import Testing

struct ConfigStoreTests {
    @Test
    func savesAndLoadsConfiguration() throws {
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let configURL = tempDirectory.appendingPathComponent("config.json")
        let store = ConfigStore(defaultURL: configURL)
        let configuration = UploaderConfiguration(
            defaultProfile: "default",
            profiles: [
                "default": R2Config(
                    accountID: "account-id",
                    bucket: "images",
                    publicBaseURL: try #require(URL(string: "https://img.example.com"))
                )
            ]
        )

        try store.save(configuration)
        let loaded = try store.load()

        #expect(loaded == configuration)
    }
}
