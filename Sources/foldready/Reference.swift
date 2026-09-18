import Foundation

/// Apple-authoritative sources every scored check is derived from.
///
/// The rule (`openspec/specs/evidence/sourcing`): a check that contributes to the score
/// must cite Apple documentation, a WWDC session, or a technical note. A claim Apple has
/// not published is either labelled as unconfirmed where it appears, or removed. Every
/// URL here was verified to resolve before being added.
enum Reference {
    static let prepareDuo = "https://developer.apple.com/videos/play/tech-talks/111461/"
    static let adaptiveDuo = "https://developer.apple.com/videos/play/tech-talks/111463/"

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

    /// Interface idiom: Apple directs apps to branch on size class rather than idiom.
    static let interfaceIdiom =
        "https://developer.apple.com/documentation/uikit/uidevice/userinterfaceidiom"

    /// Supported interface orientations, the Info.plist key that locks an app to a shape.
    static let interfaceOrientations =
        "https://developer.apple.com/documentation/bundleresources/information-property-list/uisupportedinterfaceorientations"

    /// `@SceneStorage`: per-scene state that survives a scene being torn down and rebuilt.
    static let sceneStorage = "https://developer.apple.com/documentation/swiftui/scenestorage"

    /// Apple's iPhone Duo preparation guidance. Carries the build floor (Xcode 27.1 or
    /// later to use all of the inner display) and names the four surfaces a custom
    /// layout has to handle. Referenced by the scored `build-toolchain` check.
    static let duoPreparation =
        "https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo"

    /// Reserved regions: the fold division and the camera occlusion a custom layout must
    /// query with `GeometryProxy.reservedRegions(...)` or `UIView.reservedRegions(...)`.
    static let reservedRegions =
        "https://developer.apple.com/documentation/swiftui/geometryproxy/reservedregions(kind:options:layoutdirectionbehavior:)"

    /// Arrangement views: `ArrangementView` and `UIArrangementViewController`, which
    /// arrange panes around the fold with `.split` and `.overlay`.
    static let arrangementViews =
        "https://developer.apple.com/documentation/swiftui/arrangementview"

    /// Vertical bars: `EnvironmentValues.toolbarVerticalEdge` and
    /// `UITraitCollection.verticalBarEdge`, the side placement the system uses on Duo.
    static let verticalBars =
        "https://developer.apple.com/documentation/swiftui/environmentvalues/toolbarverticaledge"

    /// Choosing a camera by the direction it faces: the active display can change as the
    /// device opens, closes or rotates.
    static let cameraDirection =
        "https://developer.apple.com/documentation/avkit/choosing-a-camera-by-the-direction-it-faces"
}
