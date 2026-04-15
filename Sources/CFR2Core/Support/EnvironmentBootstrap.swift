import Foundation

enum EnvironmentBootstrap {
    static func resolvedProfile() throws -> ResolvedProfile? {
        let environment = ProcessInfo.processInfo.environment
        let requiredKeys = [
            "CFR2_ACCOUNT_ID",
            "CFR2_BUCKET",
            "CFR2_PUBLIC_BASE_URL",
            "CFR2_ACCESS_KEY_ID",
            "CFR2_SECRET_ACCESS_KEY",
        ]

        let missingKeys = requiredKeys.filter { environment[$0]?.isEmpty != false }
        guard missingKeys.count != requiredKeys.count else {
            return nil
        }

        if !missingKeys.isEmpty {
            throw UploaderError.invalidConfig("环境变量缺失：\(missingKeys.joined(separator: ", "))")
        }

        guard let publicBaseURLString = environment["CFR2_PUBLIC_BASE_URL"],
              let publicBaseURL = URL(string: publicBaseURLString)
        else {
            throw UploaderError.invalidPublicBaseURL(environment["CFR2_PUBLIC_BASE_URL"] ?? "")
        }

        let config = R2Config(
            accountID: environment["CFR2_ACCOUNT_ID"] ?? "",
            bucket: environment["CFR2_BUCKET"] ?? "",
            publicBaseURL: publicBaseURL,
            keyPrefix: environment["CFR2_KEY_PREFIX"] ?? "uploads",
            defaultOutput: UploadOutputFormat(rawValue: environment["CFR2_DEFAULT_OUTPUT"] ?? "url") ?? .url,
            cacheControl: environment["CFR2_CACHE_CONTROL"] ?? "public, max-age=31536000, immutable"
        )

        try ConfigStore.validate(profile: "default", config: config)

        let credentials = R2Credentials(
            accessKeyID: environment["CFR2_ACCESS_KEY_ID"] ?? "",
            secretAccessKey: environment["CFR2_SECRET_ACCESS_KEY"] ?? ""
        )

        return ResolvedProfile(name: "default", config: config, credentials: credentials)
    }
}
