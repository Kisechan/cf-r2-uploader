import Foundation

public struct R2RequestLogStore: @unchecked Sendable {
    public let fileManager: FileManager
    public let logFileURL: URL

    public init(
        fileManager: FileManager = .default,
        logFileURL: URL = ConfigStore.applicationSupportDirectory
            .appendingPathComponent("logs", isDirectory: true)
            .appendingPathComponent("r2-api.log")
    ) {
        self.fileManager = fileManager
        self.logFileURL = logFileURL
    }

    public func append(_ entry: R2RequestLogEntry) throws {
        try fileManager.createDirectory(
            at: logFileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(entry)

        if !fileManager.fileExists(atPath: logFileURL.path(percentEncoded: false)) {
            try data.write(to: logFileURL, options: .atomic)
            try Data("\n".utf8).append(to: logFileURL)
            return
        }

        let handle = try FileHandle(forWritingTo: logFileURL)
        defer {
            try? handle.close()
        }
        try handle.seekToEnd()
        try handle.write(contentsOf: data)
        try handle.write(contentsOf: Data("\n".utf8))
    }

    public func loadEntries(limit: Int? = nil) throws -> [R2RequestLogEntry] {
        guard fileManager.fileExists(atPath: logFileURL.path(percentEncoded: false)) else {
            return []
        }

        let data = try Data(contentsOf: logFileURL)
        guard let raw = String(data: data, encoding: .utf8), !raw.isEmpty else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let entries = raw
            .split(whereSeparator: \.isNewline)
            .compactMap { line in
                try? decoder.decode(R2RequestLogEntry.self, from: Data(line.utf8))
            }

        if let limit {
            return Array(entries.suffix(limit)).reversed()
        }

        return entries
    }
}

private extension Data {
    func append(to fileURL: URL) throws {
        let handle = try FileHandle(forWritingTo: fileURL)
        defer {
            try? handle.close()
        }
        try handle.seekToEnd()
        try handle.write(contentsOf: self)
    }
}
