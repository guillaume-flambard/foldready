import { INDEX_APPS } from "./index-data";

export type Grade = "A" | "B" | "C" | "D" | "F";

/** The four scored checks of contract v2. Blocking facts are not checks: see `Blocker`. */
export interface Checks {
  layout: number;
  geometry: number;
  nav: number;
  state: number;
}

/**
 * A binary fact with a consequence, reported before the score. Averaging "this app does
 * not launch" into a percentage turns a consequence into a school mark.
 */
export interface Blocker {
  id: string;
  title: string;
  consequence: string;
  reference: string;
  stopsLaunch: boolean;
  file?: string;
}

export interface FindingRow {
  severity: string;
  check: string;
  message: string;
  file: string;
}

export interface AppScore {
  name: string;
  slug: string;
  repo: string;
  score: number;
  grade: Grade;
  risk: string;
  hours: number;
  uiFiles: number;
  excludedFiles: number;
  findingCount: number;
  provisional: boolean;
  blockers: Blocker[];
  checks: Checks;
  details: Record<keyof Checks, string>;
  findings: FindingRow[];
}

export const CHECK_LABELS: Record<keyof Checks, string> = {
  layout: "Adaptive layout",
  geometry: "Adaptive geometry",
  nav: "Sidebar navigation",
  state: "State preservation",
};

export const CHECK_WEIGHTS: Record<keyof Checks, string> = {
  layout: "w 0.35",
  geometry: "w 0.35",
  nav: "w 0.20",
  state: "w 0.10",
};

/** What each check means, in one line, for a reader who has not read the contract. */
export const CHECK_MEANING: Record<keyof Checks, string> = {
  layout:
    "Share of UI files free of fixed screen geometry. Icon-sized frames, previews and tests are not scored.",
  geometry:
    "How widely the app reads size classes and scene geometry, against how much it branches on device idiom or orientation.",
  nav: "Whether any navigation container can become a sidebar when the scene is wide.",
  state: "Share of stateful views that keep scroll and selection across a scene resize.",
};

/** Absolute meanings, not ranks. Calibrated on the twenty-app corpus. */
export const GRADE_MEANING: Record<Grade, string> = {
  A: "adapts on every axis measured",
  B: "adapts on most",
  C: "reads the scene somewhere",
  D: "barely reads the scene",
  F: "does not adapt",
};

export const GRADE_COLOR: Record<Grade, string> = {
  A: "var(--gA)",
  B: "var(--gB)",
  C: "var(--gC)",
  D: "var(--gD)",
  F: "var(--gF)",
};

export const APPS: AppScore[] = INDEX_APPS;

export const appBySlug = (slug: string) => APPS.find((a) => a.slug === slug);

/** Apps whose blockers stop them launching against the iOS 27 SDK. */
export const BLOCKED_APPS = APPS.filter((a) => a.blockers.some((b) => b.stopsLaunch));

export interface RoadmapStep {
  title: string;
  body: string;
  hours: number;
  pct: number;
}

export interface ReportDetail {
  summary: string;
  roadmap: RoadmapStep[];
}

/**
 * Prose derived from the measured facts. The numbers come from the audit
 * (`index-data.ts`, generated); only the wording lives here.
 */
export function reportDetail(app: AppScore): ReportDetail {
  const checkCount = Object.keys(app.checks).length;
  const weak = (Object.keys(app.checks) as (keyof Checks)[]).filter((k) => app.checks[k] < 70);
  const blocking = app.blockers.filter((b) => b.stopsLaunch);

  const summary = blocking.length
    ? `${app.name} does not launch when built against the iOS 27 SDK: ${blocking
        .map((b) => b.title.toLowerCase())
        .join(", ")}. That comes before the score. Once resolved, ${app.score}/100 (${app.grade}) describes how well the app uses a wide scene: ${weak.length} of ${checkCount} checks sit under 70.`
    : `${app.name} scores ${app.score}/100 (${app.grade}) — ${GRADE_MEANING[app.grade]}. ${weak.length} of ${checkCount} checks sit under 70, measured over ${app.uiFiles} UI files.`;

  const roadmap: RoadmapStep[] = [];
  if (blocking.length) {
    roadmap.push({
      title: "Adopt the UIScene lifecycle",
      body: "Declare a scene manifest and a scene delegate, and build the window from the window scene. Until this lands nothing else matters: the app will not start.",
      hours: 8,
      pct: 1,
    });
  }
  if (app.checks.nav < 100) {
    roadmap.push({
      title: "Sidebar-capable navigation",
      body: "Adopt NavigationSplitView, or the UIKit tab bar sidebar placement, at the root. This is the adaptation a wide canvas is for, and the largest single lift.",
      hours: Math.max(16, Math.round(app.hours * 0.4)),
      pct: 0.4,
    });
  }
  if (app.checks.geometry < 70) {
    roadmap.push({
      title: "Size classes over device checks",
      body: "Branch layout on the horizontal size class and the scene's effective geometry rather than on device idiom or interface orientation.",
      hours: Math.max(8, Math.round(app.hours * 0.25)),
      pct: 0.25,
    });
  }
  if (app.checks.layout < 90) {
    roadmap.push({
      title: "Resolve fixed geometry",
      body: `${app.details.layout}. Read geometry from the view or the window scene so it follows a resize.`,
      hours: Math.max(6, Math.round(app.hours * 0.2)),
      pct: 0.2,
    });
  }
  if (app.checks.state < 70) {
    roadmap.push({
      title: "Preserve state across a resize",
      body: "Add @SceneStorage or state restoration so selection and scroll position survive the hierarchy being rebuilt.",
      hours: Math.max(4, Math.round(app.hours * 0.15)),
      pct: 0.15,
    });
  }

  return { summary, roadmap };
}
