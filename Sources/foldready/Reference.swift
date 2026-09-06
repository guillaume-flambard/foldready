import Foundation

/// Apple-authoritative sources every scored check is derived from.
///
/// The rule (`openspec/specs/evidence/sourcing`): a check that contributes to the score
/// must cite Apple documentation, a WWDC session, or a technical note. A claim Apple has
/// not published is either labelled as unconfirmed where it appears, or removed. Every
/// URL here was verified to resolve before being added.
enum Reference {
    /// WWDC26 "Modernize your UIKit app": the four resizability audit areas (scene
    /// lifecycle, main screen references, idiom checks, orientation checks), the adaptive
    /// sidebar opt-in, and the app modernization agent skill.
    static let modernizeUIKit = "https://developer.apple.com/videos/play/wwdc2026/278/"

    /// TN3187: migrating to the UIKit scene-based life cycle. UIScene is required when
    /// building against the latest SDK; an app without it does not launch.
    static let sceneLifecycle =
        "https://developer.apple.com/documentation/technotes/tn3187-migrating-to-the-uikit-scene-based-life-cycle"

    /// The `UIRequiresFullScreen` Info.plist key, which opts an app out of resizable
    /// presentation.
    static let requiresFullScreen =
        "https://developer.apple.com/documentation/bundleresources/information-property-list/uirequiresfullscreen"

    /// `UITabBarController.sidebar`: the iPhone sidebar placement opt-in.
    static let tabBarSidebar =
        "https://developer.apple.com/documentation/uikit/uitabbarcontroller/sidebar"

    /// `NavigationSplitView`: the multi-column container that gains a sidebar when the
    /// scene is wide enough.
    static let navigationSplitView =
        "https://developer.apple.com/documentation/swiftui/navigationsplitview"

    /// Horizontal size class: the trait layout decisions should branch on, rather than
    /// device idiom or interface orientation.
    static let sizeClasses =
        "https://developer.apple.com/documentation/uikit/uitraitcollection/horizontalsizeclass"

    /// `@SceneStorage`: per-scene state that survives a scene being torn down and rebuilt.
    static let sceneStorage = "https://developer.apple.com/documentation/swiftui/scenestorage"
}
