import Foundation

/// One `LastUpgradeCheck` value read from a project file, with the file it came from.
struct ToolchainReading: Sendable {
    let file: String
    let value: Int
}

/// The toolchain generations read from the scanned project files.
///
/// Everything here is a literal value found in a `project.pbxproj`. It is a record of what
/// the project file says, not an inference about the toolchain that builds the app: a CI
/// machine can build with a newer Xcode than the one recorded, and `LastUpgradeCheck` only
/// changes when someone opens the project in a newer Xcode and accepts the upgrade.
struct BuildSignal: Sendable {
    let objectVersions: [Int]
    let upgradeChecks: [ToolchainReading]

    static let empty = BuildSignal(objectVersions: [], upgradeChecks: [])

    var isEmpty: Bool { objectVersions.isEmpty && upgradeChecks.isEmpty }

    var highestUpgradeCheck: Int? { upgradeChecks.map(\.value).max() }
}

/// Reads the Xcode build floor Apple states for iPhone Duo.
///
/// Apple: "Build your app with Xcode 27.1 or later to use all of the available screen space
/// on iPhone Duo. In earlier versions, your app doesn't extend under the status bar and
/// camera." The iPhone Duo simulator in Device Hub also requires Xcode 27.1.
enum BuildFloor {
    /// The `LastUpgradeCheck` generation Xcode 27.1 writes into a project file.
    static let xcode27_1Generation = 2710

    static func read(projectFiles: [FileContent]) -> BuildSignal {
        var objectVersions: [Int] = []
        var upgradeChecks: [ToolchainReading] = []
        for file in projectFiles {
            for line in file.content.split(separator: "\n", omittingEmptySubsequences: false) {
                let text = String(line)
                if let value = integer(after: "objectVersion", in: text) {
                    objectVersions.append(value)
                }
                if let value = integer(after: "LastUpgradeCheck", in: text) {
                    upgradeChecks.append(ToolchainReading(file: file.path, value: value))
                }
            }
        }
        return BuildSignal(
            objectVersions: objectVersions.sorted(),
            upgradeChecks: upgradeChecks.sorted {
                $0.file == $1.file ? $0.value < $1.value : $0.file < $1.file
            }
        )
    }

    /// The number following `key =` on a project file line, when the line carries it.
    private static func integer(after key: String, in line: String) -> Int? {
        guard let keyRange = line.range(of: key) else { return nil }
        let rest = line[keyRange.upperBound...]
        guard let equals = rest.firstIndex(of: "=") else { return nil }
        let afterEquals = rest[rest.index(after: equals)...].drop { $0 == " " || $0 == "\t" }
        let digits = afterEquals.prefix { $0.isNumber }
        guard !digits.isEmpty else { return nil }
        return Int(digits)
    }
}
