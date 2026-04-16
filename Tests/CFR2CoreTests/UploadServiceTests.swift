import CFR2Core
import Foundation
import Testing

private struct FakeR2Client: R2ObjectUploading {
    let etag: String?
    let expectedContentType: String

    func putObject(
        data: Data,
        key: String,
        contentType: String,
        cacheControl: String,
        config: R2Config,
        credentials: R2Credentials
    ) async throws -> String? {
        #expect(data.isEmpty == false)
        #expect(contentType == expectedContentType)
        #expect(config.bucket == "images")
        return etag
    }
}

struct UploadServiceTests {
    @Test
    func uploadsImageAndBuildsPublicURL() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).png")
        try Data([0x89, 0x50, 0x4E, 0x47]).write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let service = UploadService(
            client: FakeR2Client(etag: "\"etag-value\"", expectedContentType: "image/png"),
            keyBuilder: KeyBuilder(
                calendar: calendar,
                now: { Date(timeIntervalSince1970: 1_710_408_000) },
                randomSuffix: { "abc12345" }
            )
        )

        let result = try await service.upload(
            fileURL: tempURL,
            config: R2Config(
                accountID: "account-id",
                bucket: "images",
                publicBaseURL: try #require(URL(string: "https://img.example.com"))
            ),
            credentials: R2Credentials(accessKeyID: "id", secretAccessKey: "secret")
        )

        #expect(result.objectKey == "uploads/2024/03/14/\(tempURL.deletingPathExtension().lastPathComponent.lowercased())-abc12345.png")
        #expect(result.publicURL.absoluteString.contains("https://img.example.com/uploads/2024/03/14/"))
        #expect(result.etag == "\"etag-value\"")
    }

    @Test
    func uploadsPlainTextFile() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).txt")
        try Data("hello".utf8).write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let service = UploadService(client: FakeR2Client(etag: "\"txt-etag\"", expectedContentType: "text/plain"))

        let result = try await service.upload(
            fileURL: tempURL,
            config: R2Config(
                accountID: "account-id",
                bucket: "images",
                publicBaseURL: try #require(URL(string: "https://files.example.com"))
            ),
            credentials: R2Credentials(accessKeyID: "id", secretAccessKey: "secret")
        )

        #expect(result.objectKey.hasSuffix(".txt"))
        #expect(result.publicURL.absoluteString.contains("https://files.example.com/"))
        #expect(result.contentType == "text/plain")
    }

    @Test
    func rejectsFilesLargerThan50MB() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).bin")
        try Data(count: Int(UploadService.maximumFileSizeInBytes + 1)).write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let service = UploadService(client: FakeR2Client(etag: nil, expectedContentType: "application/octet-stream"))

        await #expect(throws: UploaderError.fileTooLarge(tempURL, maxSizeInBytes: UploadService.maximumFileSizeInBytes)) {
            _ = try await service.upload(
                fileURL: tempURL,
                config: R2Config(
                    accountID: "account-id",
                    bucket: "images",
                    publicBaseURL: try #require(URL(string: "https://files.example.com"))
                ),
                credentials: R2Credentials(accessKeyID: "id", secretAccessKey: "secret")
            )
        }
    }
}
