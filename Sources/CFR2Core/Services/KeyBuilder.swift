import Foundation

public struct KeyBuilder: Sendable {
    private let calendar: Calendar
    private let now: @Sendable () -> Date
    private let randomSuffix: @Sendable () -> String

    public init(
        calendar: Calendar = .init(identifier: .gregorian),
        now: @escaping @Sendable () -> Date = Date.init,
        randomSuffix: @escaping @Sendable () -> String = {
            String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8)).lowercased()
        }
    ) {
        self.calendar = calendar
        self.now = now
        self.randomSuffix = randomSuffix
    }

    public func makeObjectKey(fileURL: URL, keyPrefix: String) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: now())
        let month = String(format: "%02d", components.month ?? 1)
        let day = String(format: "%02d", components.day ?? 1)
        let fileName = fileURL.deletingPathExtension().lastPathComponent
        let ext = fileURL.pathExtension.lowercased()
        let sanitizedName = sanitize(fileName)
        let prefix = keyPrefix.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let pathPrefix = prefix.isEmpty ? "" : "\(prefix)/"

        if ext.isEmpty {
            return "\(pathPrefix)\(components.year ?? 1970)/\(month)/\(day)/\(sanitizedName)-\(randomSuffix())"
        }

        return "\(pathPrefix)\(components.year ?? 1970)/\(month)/\(day)/\(sanitizedName)-\(randomSuffix()).\(ext)"
    }

    private func sanitize(_ name: String) -> String {
        let folded = name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let scalars = folded.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) {
                return Character(scalar)
            }
            return "-"
        }

        let raw = String(scalars)
            .replacingOccurrences(of: "-+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
            .lowercased()

        return raw.isEmpty ? "image" : raw
    }
}
