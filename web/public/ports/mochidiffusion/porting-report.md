# FoldReady — porting report: MochiDiffusion

**Dry run — review the patches, then re-run with `--apply`.**

## UIScene lifecycle · REVIEW (check the diff)

- Scene lifecycle already present.

## Replace UIScreen.main.bounds · REVIEW (check the diff)

- UIScreen.main is deprecated in iOS 27; reads must come from the window scene / effective geometry.

## Root NavigationStack → NavigationSplitView · REVIEW (check the diff)

- No root NavigationStack without an existing NavigationSplitView found.

## State preservation across fold transitions · MANUAL (suggested)

- Mochi Diffusion/Support/ImageRepository.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Mochi Diffusion/Views/JobQueueView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Mochi Diffusion/Views/InspectorView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Mochi Diffusion/Views/SidebarView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Mochi Diffusion/Views/GalleryView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Mochi Diffusion/Views/FilterTagView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Pattern: @SceneStorage("selection") var selection: String? — survives the scene geometry change.

## De-hardcode fixed frames · MANUAL (suggested)

- Mochi Diffusion/Views/GalleryToolbarView.swift: 4 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- Mochi Diffusion/Views/GalleryItemView.swift: 2 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- Mochi Diffusion/Views/SidebarControls/ControlNetView.swift: 1 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- Mochi Diffusion/Views/SidebarControls/StartingImageView.swift: 1 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.

