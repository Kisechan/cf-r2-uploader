import Foundation

public struct HistoryStore {
    public let fileManager: FileManager
    public let url: URL
    public let maxItems: Int

    public init(
        fileManager: FileManager = .default,
        url: URL = ConfigStore.applicationSupportDirectory.appendingPathComponent("history.json"),
        maxItems: Int = 50
    ) {
        self.fileManager = fileManager
        self.url = url
        self.maxItems = maxItems
    }

    public func load() throws -> [UploadHistoryItem] {
        guard fileManager.fileExists(atPath: url.path()) else {
            return []
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([UploadHistoryItem].self, from: data)
    }

    public func save(_ items: [UploadHistoryItem]) throws {
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(items)
        try data.write(to: url, options: .atomic)
    }

    public func append(result: UploadResult, fileName: String) throws {
        var items = try load()
        items.insert(
            UploadHistoryItem(
                fileName: fileName,
                objectKey: result.objectKey,
                publicURL: result.publicURL,
                uploadedAt: result.uploadedAt
            ),
            at: 0
        )

        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }

        try save(items)
    }
}
