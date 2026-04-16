import AppKit
import ArgumentParser
import CFR2Core
import Dispatch
import Foundation

struct UploadCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "upload",
        abstract: "上传本地文件到 Cloudflare R2，并返回公开 URL 或 Markdown。"
    )

    @Argument(help: "要上传的本地文件路径。")
    var file: String

    @Option(name: .long, help: "配置文件路径，默认使用 ~/Library/Application Support/CFR2Uploader/config.json")
    var config: String?

    @Option(name: .long, help: "profile 名称，默认使用配置文件中的 defaultProfile。")
    var profile: String?

    @Option(name: .long, help: "输出格式：url 或 markdown。默认跟随配置。")
    var format: String?

    @Flag(name: .long, help: "上传成功后复制结果到剪贴板。")
    var copy = false

    mutating func run() throws {
        let file = self.file
        let config = self.config
        let profile = self.profile
        let format = self.format
        let copy = self.copy
        let semaphore = DispatchSemaphore(value: 0)
        let resultBox = CommandResultBox()

        Task.detached {
            defer { semaphore.signal() }

            do {
                let assembly = CoreAssembly()
                let fileURL = URL(fileURLWithPath: file)
                let configURL = config.map { URL(fileURLWithPath: $0) }
                let resolvedProfile = try assembly.resolvedProfile(profileName: profile, configURL: configURL)
                let result = try await assembly.uploadService.upload(
                    fileURL: fileURL,
                    config: resolvedProfile.config,
                    credentials: resolvedProfile.credentials
                )

                try? assembly.historyStore.append(result: result, fileName: fileURL.lastPathComponent)

                let outputFormat = Self.resolveOutputFormat(rawValue: format, fallback: resolvedProfile.config.defaultOutput)
                let output = CLIOutput.render(result: result, format: outputFormat)

                if copy {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(output, forType: .string)
                }

                print(output)
            } catch {
                resultBox.result = .failure(error)
                return
            }

            resultBox.result = .success(())
        }

        semaphore.wait()

        if case .failure(let error) = resultBox.result {
            throw error
        }
    }

    private static func resolveOutputFormat(rawValue: String?, fallback: UploadOutputFormat) -> UploadOutputFormat {
        guard let rawValue else {
            return fallback
        }

        return UploadOutputFormat(rawValue: rawValue.lowercased()) ?? fallback
    }
}

private final class CommandResultBox: @unchecked Sendable {
    var result: Result<Void, Error> = .success(())
}
