import Foundation

enum FixtureLoader {
    static func loadFixture(_ name: String, ext: String = "txt") throws -> String {
        let url = Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "Fixtures")!
        return try String(contentsOf: url, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
