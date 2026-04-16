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
    @Published private(set) var recentLogs: [R2RequestLogEntry] = []
    @Published private(set) var isConfigured = false
    @Published private(set) var canUploadFromClipboard = false
    @Published private(set) var activeProfileName = "default"

    private let assembly: CoreAssembly
    private let notifier: AppNotifier
    private var transientStateTask: Task<Void, Never>?

    init(assembly: CoreAssembly = .init()) {
        self.assembly = assembly
        self.notifier = AppNotifier()

        Task {
            await reload()
        }
    }

    var statusIconName: String {
        switch state {
        case .idle:
            return isConfigured ? "photo.stack.fill" : "gearshape.fill"
        case .uploading:
            return "arrow.triangle.2.circlepath.circle.fill"
        case .succeeded:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.circle.fill"
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

    var isUploading: Bool {
        if case .uploading = state {
            return true
        }
        return false
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
        recentLogs = (try? assembly.logStore.loadEntries(limit: 5)) ?? []
        canUploadFromClipboard = AppClipboard.hasUploadableImage()
    }

    func selectAndUpload() {
        Task {
            do {
                guard let fileURL = selectImage() else {
                    return
                }

                try await upload(
                    fileURL: fileURL,
                    displayName: fileURL.lastPathComponent,
                    cleanupURL: nil
                )
            } catch let error as UploaderError {
                handle(error: error)
            } catch {
                handle(error: .underlying(error.localizedDescription))
            }
        }
    }

    func uploadFromClipboard() {
        Task {
            do {
                let item = try AppClipboard.makeUploadItemFromPasteboard()
                try await upload(
                    fileURL: item.fileURL,
                    displayName: item.displayName,
                    cleanupURL: item.temporaryFileURL
                )
            } catch let error as UploaderError {
                handle(error: error)
            } catch {
                handle(error: .underlying(error.localizedDescription))
            }
        }
    }

    func openLogFile() {
        let logFileURL = assembly.logStore.logFileURL
        if FileManager.default.fileExists(atPath: logFileURL.path(percentEncoded: false)) {
            NSWorkspace.shared.open(logFileURL)
        } else {
            NSWorkspace.shared.open(logFileURL.deletingLastPathComponent())
        }
    }

    func refreshClipboardAvailability() {
        canUploadFromClipboard = AppClipboard.hasUploadableImage()
    }

    private func selectImage() -> URL? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.prompt = "上传"

        return panel.runModal() == .OK ? panel.url : nil
    }

    private func upload(
        fileURL: URL,
        displayName: String,
        cleanupURL: URL?
    ) async throws {
        defer {
            if let cleanupURL {
                try? FileManager.default.removeItem(at: cleanupURL)
            }
            refreshClipboardAvailability()
        }

        transientStateTask?.cancel()
        state = .uploading

        let profile = try assembly.resolvedProfile()
        let result = try await assembly.uploadService.upload(
            fileURL: fileURL,
            config: profile.config,
            credentials: profile.credentials
        )

        try? assembly.historyStore.append(result: result, fileName: displayName)
        AppClipboard.copy(result: result, format: profile.config.defaultOutput)

        activeProfileName = profile.name
        isConfigured = true
        recentItems = (try? assembly.historyStore.load()) ?? []
        recentLogs = (try? assembly.logStore.loadEntries(limit: 5)) ?? []
        state = .succeeded(result)

        notifier.notifyUploadSucceeded(fileName: displayName, url: result.publicURL)
        scheduleReturnToIdle()
    }

    private func handle(error: UploaderError) {
        if case .configNotFound = error {
            isConfigured = false
        } else if case .invalidConfig = error {
            isConfigured = false
        } else if case .credentialsNotFound = error {
            isConfigured = false
        }

        recentLogs = (try? assembly.logStore.loadEntries(limit: 5)) ?? recentLogs
        state = .failed(error.localizedDescription)
        notifier.notifyUploadFailed(message: error.localizedDescription)
        scheduleReturnToIdle()
    }

    private func scheduleReturnToIdle() {
        transientStateTask?.cancel()
        transientStateTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            if !Task.isCancelled {
                state = .idle
            }
        }
    }
}
