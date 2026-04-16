import AppKit
import CFR2Core
import Foundation
import UniformTypeIdentifiers

struct ClipboardUploadItem {
    let fileURL: URL
    let displayName: String
    let temporaryFileURL: URL?
}

enum AppClipboard {
    static func copy(result: UploadResult, format: UploadOutputFormat) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let value: String
        switch format {
        case .url:
            value = result.publicURL.absoluteString
        case .markdown:
            value = result.markdown
        }

        pasteboard.setString(value, forType: .string)
    }

    static func hasUploadableImage() -> Bool {
        let pasteboard = NSPasteboard.general

        if let fileURL = fileURL(from: pasteboard), isImageFile(url: fileURL) {
            return true
        }

        return supportedClipboardTypes.contains { type in
            pasteboard.data(forType: NSPasteboard.PasteboardType(type.identifier)) != nil
        }
    }

    static func makeUploadItemFromPasteboard() throws -> ClipboardUploadItem {
        let pasteboard = NSPasteboard.general

        if let fileURL = fileURL(from: pasteboard), isImageFile(url: fileURL) {
            return ClipboardUploadItem(
                fileURL: fileURL,
                displayName: fileURL.lastPathComponent,
                temporaryFileURL: nil
            )
        }

        for type in supportedClipboardTypes {
            let pasteboardType = NSPasteboard.PasteboardType(type.identifier)
            guard let data = pasteboard.data(forType: pasteboardType) else {
                continue
            }

            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("CFR2UploaderClipboard", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            let fileExtension = type.preferredFilenameExtension ?? "img"
            let fileURL = directory.appendingPathComponent(
                "clipboard-\(UUID().uuidString).\(fileExtension)"
            )
            try data.write(to: fileURL, options: .atomic)

            return ClipboardUploadItem(
                fileURL: fileURL,
                displayName: "剪贴板图片.\(fileExtension)",
                temporaryFileURL: fileURL
            )
        }

        throw UploaderError.underlying("剪贴板中没有可上传的图片数据")
    }

    private static let supportedClipboardTypes: [UTType] = [
        .png,
        .jpeg,
        .gif,
        .webP,
        .heic,
        .tiff,
    ]

    private static func fileURL(from pasteboard: NSPasteboard) -> URL? {
        guard let value = pasteboard.string(forType: .fileURL) else {
            return nil
        }
        return URL(string: value)
    }

    private static func isImageFile(url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension) else {
            return false
        }
        return type.conforms(to: .image)
    }
}
