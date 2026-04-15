import Foundation
import UniformTypeIdentifiers

public enum MIMETypeResolver {
    public static func resolveImage(for fileURL: URL) throws -> String {
        guard FileManager.default.fileExists(atPath: fileURL.path()) else {
            throw UploaderError.fileNotFound(fileURL)
        }

        let contentType = try fileURL.resourceValues(forKeys: [.contentTypeKey]).contentType
        let inferredType = contentType ?? UTType(filenameExtension: fileURL.pathExtension)

        guard let inferredType, inferredType.conforms(to: .image) else {
            throw UploaderError.unsupportedFileType(fileURL)
        }

        return inferredType.preferredMIMEType ?? "application/octet-stream"
    }
}
