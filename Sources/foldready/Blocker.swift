import Foundation

/// A binary, verifiable condition with a stated consequence.
///
/// Blockers are deliberately outside the weighted score. Expressing "this app does not
/// launch when built against the iOS 27 SDK" as 12 points of a weighted mean converts a
/// consequence into a school mark: five apps of the twenty-app corpus are in exactly that
/// state, and no reader of a "53/100" would guess it.
struct Blocker: Sendable {
    let id: String
    let title: String
    /// What happens to the app, in plain terms.
    let consequence: String
    /// Apple source establishing the requirement.
    let reference: String
    /// Where it was found, repository-relative. Nil when the condition is an absence.
    let file: String?

    /// Whether the blocker stops the app running (as opposed to declining the canvas).
    let stopsLaunch: Bool
}

enum Blockers {

    static let sceneLifecycleMissing = "scene-lifecycle-missing"
    static let fullScreenOptOut = "full-screen-opt-out"

    /// No scene lifecycle: SwiftUI `App`, a scene delegate, or a scene manifest.
    static func sceneLifecycle(swiftFiles: [FileContent]) -> Blocker? {
        let adopted = swiftFiles.contains { file in
            (file.content.contains("@main") && file.content.contains("App:"))
                || file.content.contains(": App {")
                || file.content.contains("UIWindowSceneDelegate")
                || file.content.contains("UISceneDelegate")
                || file.content.contains("UIApplicationSceneManifest")
                || file.content.contains("UISceneConfiguration")
        }
        guard !adopted else { return nil }
        return Blocker(
            id: sceneLifecycleMissing,
            title: "No UIScene lifecycle",
            consequence: """
                An app built against the iOS 27 SDK without the scene lifecycle does not \
                launch. Apps already shipped, and apps still built against the iOS 26 SDK, \
                keep working.
                """,
            reference: Reference.sceneLifecycle,
            file: nil,
            stopsLaunch: true)
    }

    /// `UIRequiresFullScreen=true`: the app declines the canvas the quality score is about.
    static func fullScreen(plists: [FileContent]) -> Blocker? {
        for plist in plists {
            guard plist.content.contains("UIRequiresFullScreen"),
                  plist.content.range(of: #"UIRequiresFullScreen</key>\s*<true/>"#,
                      options: .regularExpression) != nil
                      || plist.content.range(of: #"UIRequiresFullScreen</key>\s*<string>YES</string>"#,
                          options: .regularExpression) != nil
            else { continue }
            return Blocker(
                id: fullScreenOptOut,
                title: "Opted out of resizable presentation",
                consequence: """
                    UIRequiresFullScreen=true opts the app out of a resizable scene, so the \
                    layout this score measures never gets the canvas.
                    """,
                reference: Reference.requiresFullScreen,
                file: plist.path,
                stopsLaunch: false)
        }
        return nil
    }
}
