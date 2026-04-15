import Foundation

public enum PublicURLBuilder {
    public static func build(baseURL: URL, objectKey: String) throws -> URL {
        guard let scheme = baseURL.scheme, ["http", "https"].contains(scheme) else {
            throw UploaderError.invalidPublicBaseURL(baseURL.absoluteString)
        }

        let trimmedBase = baseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let encodedPath = objectKey
            .split(separator: "/", omittingEmptySubsequences: true)
            .map { component -> String in
                String(component).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String(component)
            }
            .joined(separator: "/")

        guard let url = URL(string: "\(trimmedBase)/\(encodedPath)") else {
            throw UploaderError.invalidPublicBaseURL(baseURL.absoluteString)
        }

        return url
    }
}
