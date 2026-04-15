import CFR2Core
import Foundation
import Testing

struct PublicURLBuilderTests {
    @Test
    func appendsObjectKeyToBaseURL() throws {
        let baseURL = try #require(URL(string: "https://img.example.com"))
        let url = try PublicURLBuilder.build(baseURL: baseURL, objectKey: "uploads/2024/04/test image.png")

        #expect(url.absoluteString == "https://img.example.com/uploads/2024/04/test%20image.png")
    }
}
