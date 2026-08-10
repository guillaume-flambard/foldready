# FoldReady — porting report: isowords

**Dry run — review the patches, then re-run with `--apply`.**

## UIScene lifecycle · REVIEW (check the diff)

- Scene lifecycle already present.

## Replace UIScreen.main.bounds · REVIEW (check the diff)

- Sources/GameOverFeature/GameOverView.swift: 1 UIScreen.main.bounds read(s) remain — replace with the scene's effective geometry.
- Sources/CubeCore/CubeSceneView.swift: 4 UIScreen.main.bounds read(s) remain — replace with the scene's effective geometry.
- Sources/Styleguide/AdaptiveSize.swift: 1 UIScreen.main.bounds read(s) remain — replace with the scene's effective geometry.
- UIScreen.main is deprecated in iOS 27; reads must come from the window scene / effective geometry.

## NavigationStack → NavigationSplitView · REVIEW (check the diff)

- Sources/AppFeature/AppView.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- Sources/AppFeature/AppView.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.
- Sources/GameCore/Views/GameView.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- Sources/GameCore/Views/GameView.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.

```diff
--- a/Sources/AppFeature/AppView.swift
+++ b/Sources/AppFeature/AppView.swift
@@ -313,1 +313,1 @@
+        NavigationSplitView { NavigationStack {
-        NavigationStack {
@@ -335,1 +335,1 @@
+      } } detail: { Color.clear }
-      }
--- a/Sources/GameCore/Views/GameView.swift
+++ b/Sources/GameCore/Views/GameView.swift
@@ -145,1 +145,1 @@
+        NavigationSplitView { NavigationStack {
-        NavigationStack {
@@ -148,1 +148,1 @@
+      } } detail: { Color.clear }
-      }
```

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

