# FoldReady — porting report: isowords

**Dry run — review the patches, then re-run with `--apply`.**

## UIScene lifecycle · REVIEW (check the diff)

- Scene lifecycle already present.

## Replace UIScreen.main.bounds · REVIEW (check the diff)

- Sources/CubeCore/CubeSceneView.swift: 4 UIScreen.main.bounds read(s) remain — replace with the scene's effective geometry.
- Sources/Styleguide/AdaptiveSize.swift: 1 UIScreen.main.bounds read(s) remain — replace with the scene's effective geometry.
- UIScreen.main is deprecated in iOS 27; reads must come from the window scene / effective geometry.

```diff
--- a/Sources/GameOverFeature/GameOverView.swift
+++ b/Sources/GameOverFeature/GameOverView.swift
@@ -805,1 +805,1 @@
+        .frame(maxWidth: .infinity)
-        .frame(width: UIScreen.main.bounds.size.width)
```

## Root NavigationStack → NavigationSplitView · REVIEW (check the diff)

- Sources/AppFeature/AppView.swift: body root is not a bare NavigationStack (TabView/ZStack/Group/sheet) — left as-is.
- Sources/GameCore/Views/GameView.swift: body root is not a bare NavigationStack (TabView/ZStack/Group/sheet) — left as-is.

## State preservation across fold transitions · MANUAL (suggested)

- Tests/AppFeatureTests/TurnBasedTests.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Sources/GameOverFeature/GameOverView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Sources/MultiplayerFeature/PastGamesView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Sources/AppFeature/GameCenterCore.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Sources/GameCore/GameCore.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Sources/GameCore/Views/GameFooterView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Sources/HomeFeature/Marquee.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Sources/HomeFeature/Home.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Sources/DemoFeature/Demo.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Sources/ActiveGamesFeature/ActiveGamesView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Sources/ActiveGamesFeature/ActiveGameCard.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Sources/TrailerFeature/Trailer.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Sources/Styleguide/GradientBlend.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Sources/Styleguide/SettingsForm.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Sources/LeaderboardFeature/LeaderboardResultsView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Sources/SettingsFeature/SettingsView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Sources/SettingsFeature/AppearanceSettingsView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Sources/VocabFeature/Vocab.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Sources/ComposableGameCenter/LiveKey.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Sources/ComposableGameCenter/Interface.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Sources/ChangelogFeature/ChangelogView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Pattern: @SceneStorage("selection") var selection: String? — survives the scene geometry change.

## De-hardcode fixed frames · MANUAL (suggested)

- Sources/GameOverFeature/GameOverView.swift: 2 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- Sources/GameOverFeature/Confetti.swift: 2 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- Sources/OnboardingFeature/OnboardingStepView.swift: 2 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- Sources/GameCore/Views/PlayersAndScoresView.swift: 2 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- Sources/CubeCore/NubView.swift: 5 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- Sources/ActiveGamesFeature/ActiveGameCard.swift: 1 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- Sources/SettingsFeature/SettingsView.swift: 1 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- Sources/SettingsFeature/AppearanceSettingsView.swift: 1 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.

