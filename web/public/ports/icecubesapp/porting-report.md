# FoldReady — porting report: IceCubesApp

**Dry run — review the patches, then re-run with `--apply`.**

## UIScene lifecycle · REVIEW (check the diff)

- Scene lifecycle already present.

## Replace UIScreen.main.bounds · REVIEW (check the diff)

- Packages/DesignSystem/Sources/DesignSystem/SceneDelegate.swift: 6 UIScreen.main.bounds read(s) remain — replace with the scene's effective geometry.
- UIScreen.main is deprecated in iOS 27; reads must come from the window scene / effective geometry.

## NavigationStack → NavigationSplitView · REVIEW (check the diff)

- IceCubesApp/App/Tabs/Settings/AddAccountsView.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- IceCubesApp/App/Tabs/Settings/AddAccountsView.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.
- IceCubesApp/App/Tabs/TagGroup/EditTagGroupView.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- IceCubesApp/App/Tabs/TagGroup/EditTagGroupView.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.
- IceCubesApp/App/Tabs/NavigationSheet.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- IceCubesApp/App/Tabs/NavigationSheet.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.
- IceCubesApp/App/Tabs/Timeline/AddRemoteTimelineView.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- IceCubesApp/App/Tabs/Timeline/AddRemoteTimelineView.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.
- IceCubesApp/App/Report/ReportView.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- IceCubesApp/App/Report/ReportView.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.
- Packages/MediaUI/Sources/MediaUI/MediaUIView.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- Packages/MediaUI/Sources/MediaUI/MediaUIView.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.
- Packages/MediaUI/Sources/MediaUI/MediaUIAttachmentVideoView.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- Packages/MediaUI/Sources/MediaUI/MediaUIAttachmentVideoView.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.
- Packages/Lists/Sources/Lists/AddAccounts/ListAddAccountView.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- Packages/Lists/Sources/Lists/AddAccounts/ListAddAccountView.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.
- Packages/Lists/Sources/Lists/Edit/ListEditView.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- Packages/Lists/Sources/Lists/Edit/ListEditView.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.
- Packages/Lists/Sources/Lists/Create/ListCreateView.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- Packages/Lists/Sources/Lists/Create/ListCreateView.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.
- Packages/AppAccount/Sources/AppAccount/AppAccountsSelectorView.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- Packages/AppAccount/Sources/AppAccount/AppAccountsSelectorView.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.
- Packages/Account/Sources/Account/Filters/FiltersListView.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- Packages/Account/Sources/Account/Filters/FiltersListView.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.
- Packages/Account/Sources/Account/Edit/EditRelationshipNoteView.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- Packages/Account/Sources/Account/Edit/EditRelationshipNoteView.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.
- Packages/Account/Sources/Account/Edit/EditAccountView.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- Packages/Account/Sources/Account/Edit/EditAccountView.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.
- Packages/Timeline/Sources/Timeline/View/TimelineContentFilterView.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- Packages/Timeline/Sources/Timeline/View/TimelineContentFilterView.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.
- Packages/Notifications/Sources/Notifications/List/NotificationsPolicyView.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- Packages/Notifications/Sources/Notifications/List/NotificationsPolicyView.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.
- Packages/StatusKit/Sources/StatusKit/History/StatusEditHistoryView.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- Packages/StatusKit/Sources/StatusKit/History/StatusEditHistoryView.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.
- Packages/StatusKit/Sources/StatusKit/Editor/Drafts/DraftsListView.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- Packages/StatusKit/Sources/StatusKit/Editor/Drafts/DraftsListView.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.
- Packages/StatusKit/Sources/StatusKit/Editor/Components/MediaEditView.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- Packages/StatusKit/Sources/StatusKit/Editor/Components/MediaEditView.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.
- Packages/StatusKit/Sources/StatusKit/Editor/Components/CustomEmojisView.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- Packages/StatusKit/Sources/StatusKit/Editor/Components/CustomEmojisView.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.
- Packages/StatusKit/Sources/StatusKit/Editor/Components/LanguageSheetView.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- Packages/StatusKit/Sources/StatusKit/Editor/Components/LanguageSheetView.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.
- Packages/StatusKit/Sources/StatusKit/Editor/MainView.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- Packages/StatusKit/Sources/StatusKit/Editor/MainView.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.
- Packages/StatusKit/Sources/StatusKit/Share/StatusRowShareAsImageView.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- Packages/StatusKit/Sources/StatusKit/Share/StatusRowShareAsImageView.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.
- Packages/StatusKit/Sources/StatusKit/Share/StatusRowSelectableTextView.swift: wrapped the root NavigationStack in a NavigationSplitView — the list becomes the sidebar, detail is a placeholder.
- Packages/StatusKit/Sources/StatusKit/Share/StatusRowSelectableTextView.swift: move selection-driven content into the detail column and add .adaptiveSidebar() at the scene root.

```diff
--- a/IceCubesApp/App/Tabs/Settings/AddAccountsView.swift
+++ b/IceCubesApp/App/Tabs/Settings/AddAccountsView.swift
@@ -57,1 +57,1 @@
+    NavigationSplitView { NavigationStack {
-    NavigationStack {
@@ -159,1 +159,1 @@
+  } } detail: { Color.clear }
-  }
--- a/IceCubesApp/App/Tabs/TagGroup/EditTagGroupView.swift
+++ b/IceCubesApp/App/Tabs/TagGroup/EditTagGroupView.swift
@@ -25,1 +25,1 @@
+    NavigationSplitView { NavigationStack {
-    NavigationStack {
@@ -79,1 +79,1 @@
+  } } detail: { Color.clear }
-  }
--- a/IceCubesApp/App/Tabs/NavigationSheet.swift
+++ b/IceCubesApp/App/Tabs/NavigationSheet.swift
@@ -17,1 +17,1 @@
+    NavigationSplitView { NavigationStack {
-    NavigationStack {
@@ -23,1 +23,1 @@
+  } } detail: { Color.clear }
-  }
--- a/IceCubesApp/App/Tabs/Timeline/AddRemoteTimelineView.swift
+++ b/IceCubesApp/App/Tabs/Timeline/AddRemoteTimelineView.swift
@@ -26,1 +26,1 @@
+    NavigationSplitView { NavigationStack {
-    NavigationStack {
@@ -88,1 +88,1 @@
+  } } detail: { Color.clear }
-  }
--- a/IceCubesApp/App/Report/ReportView.swift
+++ b/IceCubesApp/App/Report/ReportView.swift
@@ -19,1 +19,1 @@
+    NavigationSplitView { NavigationStack {
-    NavigationStack {
@@ -69,1 +69,1 @@
+  } } detail: { Color.clear }
-  }
--- a/Packages/MediaUI/Sources/MediaUI/MediaUIView.swift
+++ b/Packages/MediaUI/Sources/MediaUI/MediaUIView.swift
@@ -15,1 +15,1 @@
+    NavigationSplitView { NavigationStack {
-    NavigationStack {
@@ -57,1 +57,1 @@
+  } } detail: { Color.clear }
-  }
--- a/Packages/MediaUI/Sources/MediaUI/MediaUIAttachmentVideoView.swift
+++ b/Packages/MediaUI/Sources/MediaUI/MediaUIAttachmentVideoView.swift
@@ -154,1 +154,1 @@
+    NavigationSplitView { NavigationStack {
-    NavigationStack {
@@ -195,1 +195,1 @@
+  } } detail: { Color.clear }
-  }
--- a/Packages/Lists/Sources/Lists/AddAccounts/ListAddAccountView.swift
+++ b/Packages/Lists/Sources/Lists/AddAccounts/ListAddAccountView.swift
@@ -21,1 +21,1 @@
+    NavigationSplitView { NavigationStack {
-    NavigationStack {
@@ -75,1 +75,1 @@
+  } } detail: { Color.clear }
-  }
--- a/Packages/Lists/Sources/Lists/Edit/ListEditView.swift
+++ b/Packages/Lists/Sources/Lists/Edit/ListEditView.swift
@@ -21,1 +21,1 @@
+    NavigationSplitView { NavigationStack {
-    NavigationStack {
@@ -111,1 +111,1 @@
+  } } detail: { Color.clear }
-  }
--- a/Packages/Lists/Sources/Lists/Create/ListCreateView.swift
+++ b/Packages/Lists/Sources/Lists/Create/ListCreateView.swift
@@ -23,1 +23,1 @@
+    NavigationSplitView { NavigationStack {
-    NavigationStack {
@@ -70,1 +70,1 @@
+  } } detail: { Color.clear }
-  }
--- a/Packages/AppAccount/Sources/AppAccount/AppAccountsSelectorView.swift
+++ b/Packages/AppAccount/Sources/AppAccount/AppAccountsSelectorView.swift
@@ -129,1 +129,1 @@
+    NavigationSplitView { NavigationStack {
-    NavigationStack {
@@ -181,1 +181,1 @@
+  } } detail: { Color.clear }
-  }
--- a/Packages/Account/Sources/Account/Filters/FiltersListView.swift
+++ b/Packages/Account/Sources/Account/Filters/FiltersListView.swift
@@ -21,1 +21,1 @@
+    NavigationSplitView { NavigationStack {
-    NavigationStack {
@@ -90,1 +90,1 @@
+  } } detail: { Color.clear }
-  }
--- a/Packages/Account/Sources/Account/Edit/EditRelationshipNoteView.swift
+++ b/Packages/Account/Sources/Account/Edit/EditRelationshipNoteView.swift
@@ -21,1 +21,1 @@
+    NavigationSplitView { NavigationStack {
-    NavigationStack {
@@ -53,1 +53,1 @@
+  } } detail: { Color.clear }
-  }
--- a/Packages/Account/Sources/Account/Edit/EditAccountView.swift
+++ b/Packages/Account/Sources/Account/Edit/EditAccountView.swift
@@ -20,1 +20,1 @@
+    NavigationSplitView { NavigationStack {
-    NavigationStack {
@@ -55,1 +55,1 @@
+  } } detail: { Color.clear }
-  }
--- a/Packages/Timeline/Sources/Timeline/View/TimelineContentFilterView.swift
+++ b/Packages/Timeline/Sources/Timeline/View/TimelineContentFilterView.swift
@@ -18,1 +18,1 @@
+    NavigationSplitView { NavigationStack {
-    NavigationStack {
@@ -65,1 +65,1 @@
+  } } detail: { Color.clear }
-  }
--- a/Packages/Notifications/Sources/Notifications/List/NotificationsPolicyView.swift
+++ b/Packages/Notifications/Sources/Notifications/List/NotificationsPolicyView.swift
@@ -15,1 +15,1 @@
+    NavigationSplitView { NavigationStack {
-    NavigationStack {
@@ -125,1 +125,1 @@
+  } } detail: { Color.clear }
-  }
--- a/Packages/StatusKit/Sources/StatusKit/History/StatusEditHistoryView.swift
+++ b/Packages/StatusKit/Sources/StatusKit/History/StatusEditHistoryView.swift
@@ -21,1 +21,1 @@
+    NavigationSplitView { NavigationStack {
-    NavigationStack {
@@ -64,1 +64,1 @@
+  } } detail: { Color.clear }
-  }
--- a/Packages/StatusKit/Sources/StatusKit/Editor/Drafts/DraftsListView.swift
+++ b/Packages/StatusKit/Sources/StatusKit/Editor/Drafts/DraftsListView.swift
@@ -18,1 +18,1 @@
+      NavigationSplitView { NavigationStack {
-      NavigationStack {
@@ -57,1 +57,1 @@
+    } } detail: { Color.clear }
-    }
--- a/Packages/StatusKit/Sources/StatusKit/Editor/Components/MediaEditView.swift
+++ b/Packages/StatusKit/Sources/StatusKit/Editor/Components/MediaEditView.swift
@@ -30,1 +30,1 @@
+      NavigationSplitView { NavigationStack {
-      NavigationStack {
@@ -127,1 +127,1 @@
+    } } detail: { Color.clear }
-    }
--- a/Packages/StatusKit/Sources/StatusKit/Editor/Components/CustomEmojisView.swift
+++ b/Packages/StatusKit/Sources/StatusKit/Editor/Components/CustomEmojisView.swift
@@ -17,1 +17,1 @@
+      NavigationSplitView { NavigationStack {
-      NavigationStack {
@@ -63,1 +63,1 @@
+    } } detail: { Color.clear }
-    }
--- a/Packages/StatusKit/Sources/StatusKit/Editor/Components/LanguageSheetView.swift
+++ b/Packages/StatusKit/Sources/StatusKit/Editor/Components/LanguageSheetView.swift
@@ -18,1 +18,1 @@
+      NavigationSplitView { NavigationStack {
-      NavigationStack {
@@ -42,1 +42,1 @@
+    } } detail: { Color.clear }
-    }
--- a/Packages/StatusKit/Sources/StatusKit/Editor/MainView.swift
+++ b/Packages/StatusKit/Sources/StatusKit/Editor/MainView.swift
@@ -47,1 +47,1 @@
+      NavigationSplitView { NavigationStack {
-      NavigationStack {
@@ -55,1 +55,1 @@
+    } } detail: { Color.clear }
-    }
--- a/Packages/StatusKit/Sources/StatusKit/Share/StatusRowShareAsImageView.swift
+++ b/Packages/StatusKit/Sources/StatusKit/Share/StatusRowShareAsImageView.swift
@@ -18,1 +18,1 @@
+    NavigationSplitView { NavigationStack {
-    NavigationStack {
@@ -56,1 +56,1 @@
+  } } detail: { Color.clear }
-  }
--- a/Packages/StatusKit/Sources/StatusKit/Share/StatusRowSelectableTextView.swift
+++ b/Packages/StatusKit/Sources/StatusKit/Share/StatusRowSelectableTextView.swift
@@ -11,1 +11,1 @@
+    NavigationSplitView { NavigationStack {
-    NavigationStack {
@@ -27,1 +27,1 @@
+  } } detail: { Color.clear }
-  }
```

## State preservation across fold transitions · MANUAL (suggested)

- IceCubesApp/App/Tabs/Settings/AboutView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- IceCubesApp/App/Tabs/Settings/AccountSettingView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- IceCubesApp/App/Tabs/Settings/WishlistView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- IceCubesApp/App/Tabs/Settings/AddAccountsView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- IceCubesApp/App/Tabs/Settings/IconSelectorView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- IceCubesApp/App/Tabs/Settings/InstanceInfoView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- IceCubesApp/App/Tabs/TagGroup/EditTagGroupView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- IceCubesApp/App/Tabs/NotificationTab.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- IceCubesApp/App/Tabs/Tabs.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- IceCubesApp/App/Tabs/MessagesTab.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- IceCubesApp/App/Tabs/Timeline/AddRemoteTimelineView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- IceCubesApp/App/Tabs/Timeline/TimelineTab.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- IceCubesApp/App/Router/AppRegistry.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- IceCubesActionExtension/ActionRequestHandler.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- IceCubesAppIntents/ListEntity.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- IceCubesAppIntents/TabIntent.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/MediaUI/Sources/MediaUI/MediaUIView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/MediaUI/Sources/MediaUI/MediaUIZoomableContainer.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/DesignSystem/Sources/DesignSystem/Views/NextPageView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/DesignSystem/Sources/DesignSystem/Views/ScrollToView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/DesignSystem/Sources/DesignSystem/Views/ThemePreviewView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Lists/Package.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Lists/Sources/Lists/AddAccounts/ListAddAccountViewModel.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Lists/Sources/Lists/AddAccounts/ListAddAccountView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Lists/Sources/Lists/Edit/ListEditView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Lists/Sources/Lists/Edit/ListEditViewModel.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Lists/Sources/Lists/Create/ListCreateView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/AppAccount/Sources/AppAccount/AppAccountsSelectorView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Models/Tests/ModelsTests/HTMLStringTests.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Models/Sources/Models/List.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Explore/Sources/Explore/Sections/SuggestedAccountsSection.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Explore/Sources/Explore/Sections/TrendingTagsSection.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Explore/Sources/Explore/ExploreView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Explore/Sources/Explore/Components/QuickAccessView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Explore/Sources/Explore/Components/TrendingLinksListView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Explore/Sources/Explore/Components/TagsListView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Explore/Sources/Explore/SearchResultsView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Env/Sources/Env/CurrentAccount.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Env/Sources/Env/Router.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Conversations/Sources/Conversations/Detail/ConversationDetailView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Conversations/Sources/Conversations/List/ConversationsListDataSource.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Conversations/Sources/Conversations/List/ConversationsListRow.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Conversations/Sources/Conversations/List/ConversationsListState.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Conversations/Sources/Conversations/List/ConversationsListView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Account/Sources/Account/Filters/FiltersListView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Account/Sources/Account/Metrics/AccountMetricsView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Account/Sources/Account/Lists/ListsListView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Account/Sources/Account/StatusesLists/AccountStatusesFetcher.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Account/Sources/Account/StatusesLists/AccountStatusesListView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Account/Sources/Account/AccountsList/AccountsListView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Account/Sources/Account/AccountsList/AccountsListViewModel.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Account/Sources/Account/AccountsList/AccountsListRow.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Account/Sources/Account/Tags/FollowedTagsListView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Account/Sources/Account/Detail/AccountDetailView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Account/Sources/Account/Detail/Tabs/MediaTab.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Account/Sources/Account/Detail/Tabs/StatusesTab.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Account/Sources/Account/Detail/Tabs/RepliesTab.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Account/Sources/Account/Detail/Tabs/BookmarksTab.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Account/Sources/Account/Detail/Tabs/FavoritesTab.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Account/Sources/Account/Detail/Tabs/BoostsTab.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Account/Sources/Account/Detail/Tabs/Base/AnyStatusesListView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Account/Sources/Account/Detail/MediaGrid/AccountDetailMediaGridView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Account/Sources/Account/Detail/Components/AccountDetailToolbar.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Account/Sources/Account/Detail/Components/FamiliarFollowersView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Account/Sources/Account/Detail/Components/AccountStatsView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Account/Sources/Account/Detail/Components/FeaturedTagsView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Account/Sources/Account/Detail/AccountDetailHeaderView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Timeline/Sources/Timeline/TimelineFilter.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Timeline/Sources/Timeline/View/TimelineQuickAccessPills.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Timeline/Sources/Timeline/View/TimelineContentFilterView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Timeline/Sources/Timeline/View/TimelineView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Timeline/Sources/Timeline/View/TimelineTagGroupheaderView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Timeline/Sources/Timeline/View/TimelineListView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/NetworkClient/Sources/NetworkClient/Endpoint/Accounts.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/NetworkClient/Sources/NetworkClient/Endpoint/Lists.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Notifications/Sources/Notifications/Requests/NotificationsRequestsListView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Notifications/Sources/Notifications/Row/NotificationRowMainLabelView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Notifications/Sources/Notifications/Row/NotificationRowContentView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Notifications/Sources/Notifications/List/NotificationsListDataSource.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Notifications/Sources/Notifications/List/NotificationsListView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/Notifications/Sources/Notifications/List/NotificationsListState.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/StatusKit/Sources/StatusKit/Row/StatusRowAccessibilityLabel.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/StatusKit/Sources/StatusKit/Row/Subviews/StatusRowDetailView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/StatusKit/Sources/StatusKit/Row/Subviews/StatusRowTagsView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/StatusKit/Sources/StatusKit/Row/Subviews/StatusRowMediaPreviewView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/StatusKit/Sources/StatusKit/Row/StatusRowView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/StatusKit/Sources/StatusKit/Detail/StatusDetailView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/StatusKit/Sources/StatusKit/List/StatusesListView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/StatusKit/Sources/StatusKit/History/StatusEditHistoryView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/StatusKit/Sources/StatusKit/Editor/Drafts/DraftsListView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/StatusKit/Sources/StatusKit/Editor/Components/AutoComplete/ExpandedView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/StatusKit/Sources/StatusKit/Editor/Components/AutoComplete/AutoCompleteView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/StatusKit/Sources/StatusKit/Editor/Components/MediaView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/StatusKit/Sources/StatusKit/Editor/Components/MediaPickerPanelView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/StatusKit/Sources/StatusKit/Editor/Components/CustomEmojisView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/StatusKit/Sources/StatusKit/Editor/Components/AccessoryView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/StatusKit/Sources/StatusKit/Editor/Components/LanguageSheetView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/StatusKit/Sources/StatusKit/Editor/MainView.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Packages/StatusKit/Sources/StatusKit/Editor/ToolbarItems.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- IceCubesAppWidgetsExtension/IceCubesAppWidgetsExtensionBundle.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- IceCubesAppWidgetsExtension/ListsWidget/ListsWidgetConfiguration.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- IceCubesAppWidgetsExtension/ListsWidget/ListsWidget.swift: add @SceneStorage for selection/scroll so the fold transition keeps user state.
- Pattern: @SceneStorage("selection") var selection: String? — survives the scene geometry change.

## De-hardcode fixed frames · MANUAL (suggested)

- IceCubesApp/App/Tabs/Settings/AboutView.swift: 4 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- IceCubesApp/App/Tabs/Settings/SupportAppView.swift: 2 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- IceCubesApp/App/Tabs/Settings/SettingsTab.swift: 1 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- Packages/DesignSystem/Sources/DesignSystem/Views/ThemePreviewView.swift: 2 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- Packages/DesignSystem/Sources/DesignSystem/Views/TagChartView.swift: 1 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- Packages/DesignSystem/Sources/DesignSystem/Views/AccountPopoverView.swift: 2 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- Packages/AppAccount/Sources/AppAccount/AppAccountView.swift: 1 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- Packages/AppAccount/Sources/AppAccount/AppAccountsSelectorView.swift: 1 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- Packages/Conversations/Sources/Conversations/List/ConversationsListRow.swift: 1 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- Packages/Account/Sources/Account/Detail/Components/AccountStatsView.swift: 1 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- Packages/Account/Sources/Account/Detail/Components/AccountAvatarView.swift: 1 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- Packages/Notifications/Sources/Notifications/Requests/NotificationsRequestsListView.swift: 2 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- Packages/Notifications/Sources/Notifications/Row/NotificationRowIconView.swift: 1 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- Packages/StatusKit/Sources/StatusKit/Row/Subviews/StatusRowCardView.swift: 1 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- Packages/StatusKit/Sources/StatusKit/Editor/Components/CustomEmojisView.swift: 2 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- Packages/StatusKit/Sources/StatusKit/Editor/Components/AccessoryView.swift: 8 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- IceCubesAppWidgetsExtension/Shared/PostsWidgetView.swift: 2 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.
- IceCubesAppWidgetsExtension/AccountWidget/AccountWidgetView.swift: 1 hardcoded frame(s) — prefer .containerRelativeFrame, GeometryReader, or intrinsic sizes.

