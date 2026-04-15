import CFR2Core
import Foundation
import Testing

struct KeyBuilderTests {
    @Test
    func objectKeyUsesPrefixDateAndStableSuffix() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let builder = KeyBuilder(
            calendar: calendar,
            now: {
                Date(timeIntervalSince1970: 1_710_408_000) // 2024-03-14 12:00:00 UTC
            },
            randomSuffix: { "deadbeef" }
        )

        let key = builder.makeObjectKey(
            fileURL: URL(fileURLWithPath: "/tmp/Hello World.png"),
            keyPrefix: "uploads"
        )

        #expect(key == "uploads/2024/03/14/hello-world-deadbeef.png")
    }
}
