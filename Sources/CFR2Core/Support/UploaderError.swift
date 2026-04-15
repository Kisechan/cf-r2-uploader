import Foundation

public enum UploaderError: LocalizedError, Sendable, Equatable {
    case configNotFound(URL)
    case invalidConfig(String)
    case credentialsNotFound(profile: String)
    case fileNotFound(URL)
    case unsupportedFileType(URL)
    case invalidPublicBaseURL(String)
    case uploadFailed(statusCode: Int?, message: String)
    case responseDecodeFailed
    case cancelled
    case underlying(String)

    public var errorDescription: String? {
        switch self {
        case .configNotFound(let url):
            return "找不到配置文件：\(url.path)"
        case .invalidConfig(let message):
            return "配置无效：\(message)"
        case .credentialsNotFound(let profile):
            return "Keychain 中找不到 profile=\(profile) 的凭据"
        case .fileNotFound(let url):
            return "找不到文件：\(url.path)"
        case .unsupportedFileType(let url):
            return "只支持上传图片文件：\(url.lastPathComponent)"
        case .invalidPublicBaseURL(let value):
            return "公开访问地址无效：\(value)"
        case .uploadFailed(let statusCode, let message):
            if let statusCode {
                return "上传失败（HTTP \(statusCode)）：\(message)"
            }
            return "上传失败：\(message)"
        case .responseDecodeFailed:
            return "服务端响应无法解析"
        case .cancelled:
            return "操作已取消"
        case .underlying(let message):
            return message
        }
    }
}
