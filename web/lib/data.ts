export type Grade = "A" | "B" | "C" | "D" | "F";

export interface Checks {
  adaptive: number;
  parallel: number;
  nav: number;
  scene: number;
  fold: number;
  state: number;
  framework: number;
}

export interface AppScore {
  name: string;
  slug: string;
  score: number;
  grade: Grade;
  risk: "low" | "medium" | "high";
  hours: number;
  swiftFiles: number;
  findings: number;
  repo: string;
  checks: Checks;
}

export const CHECK_LABELS: Record<keyof Checks, string> = {
  adaptive: "Adaptive",
  parallel: "ParallelView",
  nav: "Sidebar",
  scene: "Scene",
  fold: "Adaptive geometry",
  state: "State",
  framework: "SwiftUI",
};

export const CHECK_WEIGHTS: Record<keyof Checks, string> = {
  adaptive: "w 0.22",
  parallel: "w 0.08",
  nav: "w 0.25",
  scene: "w 0.15",
  fold: "w 0.12",
  state: "w 0.08",
  framework: "w 0.10",
};

export const GRADE_COLOR: Record<Grade, string> = {
  A: "var(--gA)",
  B: "var(--gB)",
  C: "var(--gC)",
  D: "var(--gD)",
  F: "var(--gF)",
};

export const APPS: AppScore[] = [
  { name: "MochiDiffusion", slug: "mochidiffusion", score: 92, grade: "A", risk: "low", hours: 27.5, swiftFiles: 58, findings: 0, repo: "cjnevin/mochi-diffusion", checks: { adaptive: 93, parallel: 100, nav: 100, scene: 100, fold: 70, state: 70, framework: 100 } },
  { name: "IceCubesApp", slug: "icecubesapp", score: 72, grade: "B", risk: "low", hours: 214, swiftFiles: 424, findings: 37, repo: "Dimillian/IceCubesApp", checks: { adaptive: 93, parallel: 100, nav: 40, scene: 100, fold: 30, state: 70, framework: 91 } },
  { name: "isowords", slug: "isowords", score: 76, grade: "A", risk: "low", hours: 185.5, swiftFiles: 388, findings: 30, repo: "pointfreeco/isowords", checks: { adaptive: 95, parallel: 100, nav: 40, scene: 100, fold: 65, state: 70, framework: 89 } },
  { name: "MovieSwiftUI", slug: "movieswiftui", score: 63, grade: "B", risk: "low", hours: 76, swiftFiles: 105, findings: 18, repo: "Dimillian/MovieSwiftUI", checks: { adaptive: 85, parallel: 100, nav: 40, scene: 20, fold: 70, state: 70, framework: 97 } },
  { name: "Dime", slug: "dime", score: 56, grade: "C", risk: "medium", hours: 80, swiftFiles: 94, findings: 38, repo: "noahsark769/Dime", checks: { adaptive: 0, parallel: 100, nav: 40, scene: 100, fold: 70, state: 70, framework: 90 } },
  { name: "Open Food Facts", slug: "openfoodfacts", score: 50, grade: "C", risk: "medium", hours: 86, swiftFiles: 218, findings: 3, repo: "openfoodfacts/openfoodfacts-ios", checks: { adaptive: 98, parallel: 100, nav: 50, scene: 20, fold: 20, state: 30, framework: 0 } },
];

export const appBySlug = (slug: string) => APPS.find((a) => a.slug === slug);

export interface FindingRow {
  severity: "Blocker" | "Major" | "Minor";
  check: string;
  message: string;
  file: string;
}

export interface RoadmapStep {
  title: string;
  body: string;
  hours: number;
  pct: number; // fraction of total effort
}

export interface ReportDetail {
  summary: string;
  breakdownNotes: Record<keyof Checks, string>;
  findings: FindingRow[];
  roadmap: RoadmapStep[];
}

const ICECUBES: ReportDetail = {
  summary:
    "A passing grade for the 7.8in inner display. One structural gap pulls the score down: navigation runs on stacked tabs, so the inner display won't gain a sidebar. Worth fixing before launch — see the roadmap.",
  breakdownNotes: {
    adaptive: "34 hardcoded frames · 6 UIScreen.main.bounds reads across 424 files",
    parallel: "Parallel View not blocked · w 0.10",
    nav: "0 NavigationSplitView · 0 sidebar opt-ins · 31 stacks",
    scene: "SwiftUI @main App scene · w 0.10",
    fold: "0 fold-state reads · 5 adaptive geometry",
    state: "0 @SceneStorage · 0 restoration · 42 view models",
    framework: "265 SwiftUI files · 26 UIKit files",
  },
  findings: [
    { severity: "Major", check: "Navigation", message: "NavigationStack without NavigationSplitView: the list/detail panes will not gain a sidebar on the inner display.", file: "TimelineTab.swift" },
    { severity: "Major", check: "Navigation", message: "NavigationStack without NavigationSplitView: the list/detail panes will not gain a sidebar on the inner display.", file: "MessagesTab.swift" },
    { severity: "Major", check: "Navigation", message: "NavigationStack without NavigationSplitView: the list/detail panes will not gain a sidebar on the inner display.", file: "ProfileTab.swift" },
    { severity: "Major", check: "Navigation", message: "NavigationStack without NavigationSplitView: the list/detail panes will not gain a sidebar on the inner display.", file: "ExploreTab.swift" },
    { severity: "Major", check: "Navigation", message: "NavigationStack without NavigationSplitView: the list/detail panes will not gain a sidebar on the inner display.", file: "SettingsTab.swift" },
    { severity: "Major", check: "Navigation", message: "NavigationStack without NavigationSplitView: the list/detail panes will not gain a sidebar on the inner display.", file: "MediaUIView.swift" },
    { severity: "Major", check: "Adaptive layout", message: "UIScreen.main.bounds is a fixed geometry read; use the scene coordinate space.", file: "SceneDelegate.swift:11" },
    { severity: "Major", check: "Adaptive layout", message: "UIScreen.main.bounds is a fixed geometry read; use the scene coordinate space.", file: "SceneDelegate.swift:12" },
    { severity: "Major", check: "Adaptive layout", message: "UIScreen.main.bounds is a fixed geometry read; use the scene coordinate space.", file: "SceneDelegate.swift:44" },
    { severity: "Minor", check: "Adaptive layout", message: "Hardcoded frame (width and height literals) will not reflow on the 7.8 inch inner display.", file: "AboutView.swift:35" },
    { severity: "Minor", check: "Adaptive layout", message: "Hardcoded frame (width and height literals) will not reflow on the 7.8 inch inner display.", file: "TagChartView.swift:26" },
    { severity: "Minor", check: "State", message: "No explicit scroll/selection state preservation. A fold transition can rebuild the view hierarchy; state held only in views is lost.", file: "app-wide" },
  ],
  roadmap: [
    { title: "SwiftUI / UIKit boundary", body: "Box the 26 UIKit files behind representable wrappers so the foldable renderer treats them as one surface.", hours: 6, pct: 0.06 },
    { title: "Parallel View verification", body: "Capture inner-display layouts at 7.8in on a device and confirm the opt-in holds for every tab.", hours: 8, pct: 0.08 },
    { title: "State preservation", body: "Add @SceneStorage and scenePhase restoration across the 42 view models so the fold keeps every scroll position.", hours: 24, pct: 0.25 },
    { title: "Adaptive layout pass", body: "Resolve the 34 hardcoded frames and 6 UIScreen.main.bounds reads to the scene coordinate space.", hours: 38, pct: 0.4 },
    { title: "Adaptive geometry pass", body: "Add size-class reads and respond to didUpdateEffectiveGeometry across the 5 adaptive sites so the layout reflows, not letterboxes, on wide canvases.", hours: 42, pct: 0.44 },
    { title: "Sidebar & adaptive navigation", body: "Replace the 31 stacked tabs with NavigationSplitView and a sidebar opt-in — the single largest lift, and the one that earns the featured look on the inner display.", hours: 96, pct: 1 },
  ],
};

function genericReport(app: AppScore): ReportDetail {
  const weak: Record<string, string> = {};
  (Object.keys(app.checks) as (keyof Checks)[]).forEach((k) => {
    if (app.checks[k] < 70) weak[k] = app.checks[k] + "";
  });
  const findings: FindingRow[] = [];
  if (app.checks.nav < 70) findings.push({ severity: "Major", check: "Navigation", message: "NavigationStack without NavigationSplitView: the list/detail panes will not gain a sidebar on the inner display.", file: "app-wide" });
  if (app.checks.adaptive < 70) findings.push({ severity: "Major", check: "Adaptive layout", message: "Hardcoded frames or UIScreen.main.bounds reads will not reflow on the 7.8 inch inner display.", file: "app-wide" });
  if (app.checks.fold < 70) findings.push({ severity: "Minor", check: "Fold state", message: "No fold-state or adaptive geometry handling; the app will run via Parallel View without a fold posture opinion.", file: "app-wide" });
  if (findings.length === 0) findings.push({ severity: "Minor", check: "State", message: "No explicit state preservation audit surfaced in this pass.", file: "app-wide" });
  const roadmap: RoadmapStep[] = [
    { title: "Parallel View verification", body: "Capture inner-display layouts and confirm the opt-in holds.", hours: 8, pct: 0.08 },
    { title: "Adaptive navigation", body: "Adopt NavigationSplitView and the sidebar opt-in for the list/detail flows.", hours: Math.max(24, Math.round(app.hours * 0.45)), pct: 0.45 },
    { title: "Layout + state pass", body: "Resolve hardcoded geometry and add scene restoration.", hours: Math.max(16, Math.round(app.hours * 0.3)), pct: 0.3 },
  ];
  return {
    summary: `${app.name} scores ${app.score}/${app.grade}. ${Object.keys(weak).length} of 7 checks sit under the 70% bar; the plan below closes them.`,
    breakdownNotes: {
      adaptive: app.checks.adaptive + "% adaptive coverage",
      parallel: app.checks.parallel === 100 ? "Parallel View not blocked" : "verify opt-in",
      nav: app.checks.nav + "% sidebar readiness",
      scene: app.checks.scene === 100 ? "SwiftUI @main App scene" : "scene lifecycle needs work",
      fold: app.checks.fold + "% fold-state coverage",
      state: app.checks.state + "% state preservation",
      framework: app.checks.framework + "% SwiftUI",
    },
    findings,
    roadmap,
  };
}

export function reportDetail(app: AppScore): ReportDetail {
  return app.slug === "icecubesapp" ? ICECUBES : genericReport(app);
}
