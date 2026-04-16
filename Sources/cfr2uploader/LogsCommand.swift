import ArgumentParser
import CFR2Core
import Foundation

struct LogsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "logs",
        abstract: "读取最近的 R2 S3 API 交互日志。"
    )

    @Option(name: .long, help: "最多显示多少条日志，默认 20。")
    var limit: Int = 20

    func run() throws {
        let store = R2RequestLogStore()
        let entries = try store.loadEntries(limit: max(limit, 1))

        if entries.isEmpty {
            print("暂无 R2 API 日志，日志文件路径：\(store.logFileURL.path(percentEncoded: false))")
            return
        }

        print("日志文件：\(store.logFileURL.path(percentEncoded: false))")
        for entry in entries {
            let statusCode = entry.statusCode.map(String.init) ?? "-"
            print("[\(entry.timestamp.ISO8601Format())] \(entry.outcome.rawValue.uppercased()) \(entry.method) \(statusCode) \(entry.durationMilliseconds)ms")
            print("key: \(entry.objectKey)")
            print("url: \(entry.requestURL)")
            print("message: \(entry.message)")
            if let responseBodyPreview = entry.responseBodyPreview, !responseBodyPreview.isEmpty {
                print("response: \(responseBodyPreview)")
            }
            print("")
        }
    }
}
