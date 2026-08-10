import type { Metadata } from "next";
import Link from "next/link";
import { GetScoredForm } from "@/components/GetScoredForm";
import { APPS, GRADE_COLOR } from "@/lib/data";

export const metadata: Metadata = {
  title: "Get scored — FoldReady",
  description:
    "Request a Fold-Ready Score for your iOS app: 7 checks against the iOS 27 foldable requirements, findings with file:line, and an hours estimate. Or run the free local CLI yourself.",
};

export default function GetScoredPage() {
  const hero = APPS[0];
  return (
    <main className="wrap">
      <header className="head" style={{ paddingBottom: 40 }}>
        <span className="kicker">Fold-Ready Score · 48h turnaround</span>
        <h1>Get your app scored.</h1>
        <p className="lede">
          Seven checks against the iOS 27 foldable requirements, every blocking finding
          with file:line, and an hours estimate for the port. Request it by email, or run
          the free local CLI and send us the report.
        </p>
        <div className="legend">
          <span><b className="g" style={{ color: GRADE_COLOR[hero.grade] }}>{hero.score}</b> {hero.name} — the best app we've indexed so far</span>
        </div>
      </header>

      <GetScoredForm />

      <section className="block" style={{ borderBottom: 0 }}>
        <div className="sec-head">
          <h2>What you get</h2>
          <span className="id">the same checks as the index</span>
        </div>
        <div className="offer">
          <div className="ocard">
            <span className="ico">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M5 16a7 7 0 1 1 14 0"/><path d="M12 16l4-5.5"/><circle cx="12" cy="16" r="1.4" fill="currentColor" stroke="none"/></svg>
            </span>
            <h3>0–100 score + grade</h3>
            <p>The number a decision meeting can act on, weighted toward the public iOS 27 contract.</p>
          </div>
          <div className="ocard">
            <span className="ico">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><rect x="4" y="4" width="16" height="16" rx="4"/><circle cx="12" cy="12" r="3.2"/></svg>
            </span>
            <h3>Findings with file:line</h3>
            <p>Every hardcoded frame, UIScreen.main read, missing scene lifecycle, and navigation gap — located, not vibed.</p>
          </div>
          <div className="ocard">
            <span className="ico">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M12 15V4"/><path d="M7 9l5-5 5 5"/><path d="M5 12v7a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-7"/></svg>
            </span>
            <h3>Hours estimate</h3>
            <p>And, on request, a generated porting patch you can review before committing.</p>
          </div>
        </div>
      </section>

      <p className="spec" style={{ paddingBottom: 48 }}>
        <Link href="/ranking" style={{ color: "var(--blue)" }}>See the Fold-Ready Index</Link> · or <Link href="/" style={{ color: "var(--blue)" }}>read the full offer</Link>
      </p>
    </main>
  );
}
