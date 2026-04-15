import AppKit
import CFR2Core
import Foundation

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
}
