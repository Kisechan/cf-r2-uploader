import Foundation
import UniformTypeIdentifiers

public enum MIMETypeResolver {
    public static func resolveContentType(for fileURL: URL) throws -> String {
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else {
            throw UploaderError.fileNotFound(fileURL)
        }

        let contentType = try fileURL.resourceValues(forKeys: [.contentTypeKey]).contentType
        let inferredType = contentType ?? UTType(filenameExtension: fileURL.pathExtension)
        return inferredType?.preferredMIMEType ?? "application/octet-stream"
    }
}
