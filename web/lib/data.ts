import { INDEX_APPS } from "./index-data";

export type Grade = "A" | "B" | "C" | "D" | "F";

/**
 * The scored checks of contract v5, minus the build-toolchain floor, which the page
 * reports separately. A check the audit could not measure is carried as 100 with a
 * "not applicable" detail: it is not a zero, and the page must never render it as one.
 */
export interface Checks {
  layout: number;
  geometry: number;
  nav: number;
  state: number;
  idiom: number;
  orientation: number;
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
  confidence?: string;
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
  nav: "Standard navigation",
  state: "State preservation",
  idiom: "Interface idiom",
  orientation: "Interface orientation",
};

export const CHECK_WEIGHTS: Record<keyof Checks, string> = {
  layout: "w 0.35",
  geometry: "w 0.15",
  nav: "w 0.20",
  state: "w 0.10",
  idiom: "w 0.10",
  orientation: "w 0.10",
};

/** What each check means, in one line, for a reader who has not read the contract. */
export const CHECK_MEANING: Record<keyof Checks, string> = {
  layout:
    "Share of UI files free of fixed screen geometry. Icon-sized frames, previews and tests are not scored.",
  geometry:
    "How widely the app reads size classes and scene geometry. Absence of any read is not scored zero.",
  nav: "Standard navigation signals; sidebar placement is optional.",
  state: "Share of stateful view files with detected restoration signals; behavior is untested.",
  idiom: "Share of UI files free of layout branching on the device idiom.",
  orientation: "Whether the app adapts to scene geometry rather than branching on interface orientation.",
};

/** Versioned heuristic bands, never runtime behavior. */
export const GRADE_MEANING: Record<Grade, string> = {
  A: "source score 85 to 100",
  B: "source score 65 to 84",
  C: "source score 45 to 64",
  D: "source score 25 to 44",
  F: "source score below 25",
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

/** Source trees with conditional lifecycle signals awaiting build confirmation. */
export const BLOCKED_APPS = APPS.filter((a) => a.blockers.some((b) => b.stopsLaunch));

export interface RoadmapStep {
  title: string;
  body: string;
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
  const blocking = app.blockers.filter((b) => b.stopsLaunch);

  const summary = `${app.name}: ${app.score}/100 (${app.grade}), contract v5, over ${app.uiFiles} UI files. This is a versioned source summary. ${blocking.length} potential lifecycle signal(s) require build confirmation. Runtime compatibility and human priority are unassessed.`;

  const roadmap: RoadmapStep[] = [];
  if (blocking.length) {
    roadmap.push({
      title: "Confirm scene lifecycle configuration",
      body: "Confirm the reviewed target, generated declarations and linked SDK before deciding whether lifecycle migration applies. Record an actual launch separately.",
    });
  }
  if (app.checks.nav < 100) {
    roadmap.push({
      title: "Review navigation",
      body: "Inspect legacy navigation in the agreed journeys at narrow and wide sizes. A sidebar is optional; confirm a need before changing navigation.",
    });
  }
  if (app.checks.geometry < 70) {
    roadmap.push({
      title: "Size classes over device checks",
      body: "Check whether the affected layout follows scene size. Standard containers may already adapt without explicit geometry reads.",
    });
  }
  if ((app.checks.idiom ?? 100) < 100 || (app.checks.orientation ?? 100) < 100) {
    roadmap.push({
      title: "Inspect idiom and orientation assumptions",
      body: "Confirm target membership and branch intent, then exercise the affected journey across scene sizes and rotation.",
    });
  }
  if (app.checks.layout < 90) {
    roadmap.push({
      title: "Inspect fixed geometry",
      body: `${app.details.layout}. Confirm whether the fixed size is intentional and reproduce any clipping before changing it.`,
    });
  }
  if (app.checks.state < 70) {
    roadmap.push({
      title: "Test state across a resize",
      body: "Set selection, scroll and input state, resize, then revisit the journey. Record any loss before choosing a restoration change.",
    });
  }

  return { summary, roadmap };
}
