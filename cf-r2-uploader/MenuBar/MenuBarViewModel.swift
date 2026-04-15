import AppKit
import Combine
import CFR2Core
import Foundation
import UniformTypeIdentifiers

@MainActor
final class MenuBarViewModel: ObservableObject {
    enum UploadState {
        case idle
        case uploading
        case succeeded(UploadResult)
        case failed(String)
    }

    @Published private(set) var state: UploadState = .idle
    @Published private(set) var recentItems: [UploadHistoryItem] = []
    @Published private(set) var isConfigured = false
    @Published private(set) var activeProfileName = "default"

    private let assembly: CoreAssembly

    init(assembly: CoreAssembly = .init()) {
        self.assembly = assembly

        Task {
            await reload()
        }
    }

    var statusIconName: String {
        switch state {
        case .idle:
            return isConfigured ? "icloud" : "exclamationmark.triangle"
        case .uploading:
            return "arrow.trianglehead.2.clockwise.icloud"
        case .succeeded:
            return "checkmark.icloud"
        case .failed:
            return "xmark.icloud"
        }
    }

    var statusText: String {
        switch state {
        case .idle:
            return isConfigured ? "准备就绪" : "尚未完成配置"
        case .uploading:
            return "正在上传..."
        case .succeeded(let result):
            return "上传成功：\(result.objectKey)"
        case .failed(let message):
            return message
        }
    }

    func reload() async {
        do {
            let profile = try assembly.resolvedProfile(includeEnvironmentFallback: false)
            activeProfileName = profile.name
            isConfigured = true
        } catch {
            isConfigured = false
        }

        recentItems = (try? assembly.historyStore.load()) ?? []
    }

    func selectAndUpload() {
        Task {
            do {
                guard let fileURL = selectImage() else {
                    return
                }

                state = .uploading
                let profile = try assembly.resolvedProfile()
                let result = try await assembly.uploadService.upload(
                    fileURL: fileURL,
                    config: profile.config,
                    credentials: profile.credentials
                )

                try? assembly.historyStore.append(result: result, fileName: fileURL.lastPathComponent)
                AppClipboard.copy(result: result, format: profile.config.defaultOutput)
                recentItems = (try? assembly.historyStore.load()) ?? []
                activeProfileName = profile.name
                isConfigured = true
                state = .succeeded(result)
            } catch let error as UploaderError {
                isConfigured = false
                state = .failed(error.localizedDescription)
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    private func selectImage() -> URL? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.prompt = "上传"

        return panel.runModal() == .OK ? panel.url : nil
    }
}
