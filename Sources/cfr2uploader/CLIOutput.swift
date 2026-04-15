import CFR2Core
import Foundation

enum CLIOutput {
    static func render(result: UploadResult, format: UploadOutputFormat) -> String {
        switch format {
        case .url:
            return result.publicURL.absoluteString
        case .markdown:
            return result.markdown
        }
    }
}
