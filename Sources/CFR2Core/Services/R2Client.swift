import CryptoKit
import Foundation

public protocol R2ObjectUploading: Sendable {
    func putObject(
        data: Data,
        key: String,
        contentType: String,
        cacheControl: String,
        config: R2Config,
        credentials: R2Credentials
    ) async throws -> String?
}

public struct R2Client: R2ObjectUploading, Sendable {
    private let clock: @Sendable () -> Date

    public init(clock: @escaping @Sendable () -> Date = Date.init) {
        self.clock = clock
    }

    public func putObject(
        data: Data,
        key: String,
        contentType: String,
        cacheControl: String,
        config: R2Config,
        credentials: R2Credentials
    ) async throws -> String? {
        let timestamp = clock()
        let payloadHash = SHA256.hash(data: data).hexString
        let shortDate = Self.shortDateFormatter.string(from: timestamp)
        let amzDate = Self.timestampFormatter.string(from: timestamp)
        let host = config.endpointURL.host() ?? ""
        let canonicalURI = Self.canonicalURI(bucket: config.bucket, key: key)
        let credentialScope = "\(shortDate)/auto/s3/aws4_request"

        var headers: [String: String] = [
            "cache-control": cacheControl,
            "content-disposition": "inline",
            "content-length": "\(data.count)",
            "content-type": contentType,
            "host": host,
            "x-amz-content-sha256": payloadHash,
            "x-amz-date": amzDate,
        ]

        let signedHeaders = headers.keys.sorted().joined(separator: ";")
        let canonicalHeaders = headers
            .sorted { $0.key < $1.key }
            .map { "\($0.key):\($0.value.trimmingCharacters(in: .whitespacesAndNewlines))\n" }
            .joined()
        let canonicalRequest = [
            "PUT",
            canonicalURI,
            "",
            canonicalHeaders,
            signedHeaders,
            payloadHash,
        ].joined(separator: "\n")
        let canonicalRequestHash = SHA256.hash(data: Data(canonicalRequest.utf8)).hexString
        let stringToSign = [
            "AWS4-HMAC-SHA256",
            amzDate,
            credentialScope,
            canonicalRequestHash,
        ].joined(separator: "\n")
        let signingKey = Self.signingKey(secretAccessKey: credentials.secretAccessKey, shortDate: shortDate)
        let signature = Data(HMAC<SHA256>.authenticationCode(for: Data(stringToSign.utf8), using: signingKey)).hexString

        headers["authorization"] = "AWS4-HMAC-SHA256 Credential=\(credentials.accessKeyID)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(signature)"

        guard let requestURL = URL(string: "\(config.endpointURL.absoluteString)\(canonicalURI)") else {
            throw UploaderError.underlying("无法构造 R2 上传地址")
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "PUT"
        request.httpBody = data
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        do {
            let (responseData, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw UploaderError.responseDecodeFailed
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                let message = String(data: responseData, encoding: .utf8) ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                throw UploaderError.uploadFailed(statusCode: httpResponse.statusCode, message: message)
            }

            return httpResponse.value(forHTTPHeaderField: "ETag")
        } catch let error as UploaderError {
            throw error
        } catch {
            throw UploaderError.underlying(error.localizedDescription)
        }
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return formatter
    }()

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()

    private static func canonicalURI(bucket: String, key: String) -> String {
        let encodedBucket = encodePathComponent(bucket)
        let encodedKey = key
            .split(separator: "/", omittingEmptySubsequences: false)
            .map { encodePathComponent(String($0)) }
            .joined(separator: "/")
        return "/\(encodedBucket)/\(encodedKey)"
    }

    private static func encodePathComponent(_ value: String) -> String {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    private static func signingKey(secretAccessKey: String, shortDate: String) -> SymmetricKey {
        let secret = Data(("AWS4" + secretAccessKey).utf8)
        let dateKey = hmac(key: secret, value: shortDate)
        let regionKey = hmac(key: dateKey, value: "auto")
        let serviceKey = hmac(key: regionKey, value: "s3")
        let signingKey = hmac(key: serviceKey, value: "aws4_request")
        return SymmetricKey(data: signingKey)
    }

    private static func hmac(key: Data, value: String) -> Data {
        let key = SymmetricKey(data: key)
        let signature = HMAC<SHA256>.authenticationCode(for: Data(value.utf8), using: key)
        return Data(signature)
    }
}

private extension Digest {
    var hexString: String {
        self.map { String(format: "%02x", $0) }.joined()
    }
}

private extension DataProtocol {
    var hexString: String {
        self.map { String(format: "%02x", $0) }.joined()
    }
}
