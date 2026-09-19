import Link from "next/link";
import type { Metadata } from "next";
import { APPS, CHECK_LABELS, CHECK_MEANING, GRADE_COLOR, appBySlug, reportDetail, type Checks } from "@/lib/data";
import { ScoreGauge } from "@/components/ScoreGauge";
import { SeverityChip, SegBar } from "@/components/ScoreCard";
import { PageMotion } from "@/components/Motion";
import { href } from "@/lib/href";

export function generateStaticParams() {
  return APPS.map((a) => ({ slug: a.slug }));
}

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params;
  const app = appBySlug(slug);
  if (!app) return { title: "Report not found | FoldReady" };
  return {
    title: `Fold-Ready Report · ${app.name}`,
    description: `Fold-Ready audit of ${app.name} (contract v5): score ${app.score}, grade ${app.grade}, ${app.hours}h unvalidated estimate, ${app.findingCount} source signals.`,
  };
}

export default async function ReportPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const app = appBySlug(slug);
  if (!app) {
    return (
      <main className="wrap" style={{ paddingTop: 64 }}>
        <h1 style={{ font: "700 32px/1.1 var(--font-display)" }}>Report not found</h1>
        <p style={{ color: "var(--dim)", marginTop: 12 }}>
          <Link href="/ranking">Back to the Fold-Ready Index</Link>
        </p>
      </main>
    );
  }

  const detail = reportDetail(app);
  const color = GRADE_COLOR[app.grade];
  const checkKeys = Object.keys(app.checks) as (keyof Checks)[];

  const road = detail.roadmap;

  const majorCount = app.findings.filter((f) => f.severity === "critical" || f.severity === "major").length;
  const minorCount = app.findings.filter((f) => f.severity === "minor").length;
  const weakest = checkKeys.reduce<{ k: keyof Checks; v: number }>((acc, k) => {
    const v = app.checks[k] ?? 100;
    return v < acc.v ? { k, v } : acc;
  }, { k: checkKeys[0], v: 100 });

  return (
    <main className="wrap">
      <PageMotion />
      <p className="lede" style={{ paddingTop: 32 }}>Source audit under contract v5. It reports source signals, not runtime verdicts: no Duo build was run and compatibility is unverified. Re-run the current CLI on your own revision before making decisions.</p>
      <p className="spec">Hours are unvalidated heuristics, not measured delivery time or a quote. This index retains only a sample of findings and partial coverage metadata; target membership and build settings are unresolved. No human priority has been validated. Scores across contracts are not comparable.</p>
      <nav className="crumbs">
        <Link href="/ranking">Fold-Ready Index</Link>
        <span className="sep">/</span>
        <span>{app.name}</span>
      </nav>

      <header className="report-head">
        <div className="top">
          <div>
            <h1>{app.name}</h1>
            <p className="repo">{app.repo}</p>
          </div>
          <div className="acts">
            <button className="btn btn-sec" type="button">
              <svg className="ic" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 15V4"/><path d="M7 9l5-5 5 5"/><path d="M5 12v7a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-7"/></svg>
              Share
            </button>
            <button className="btn btn-pri" type="button">
              <svg className="ic" viewBox="0 0 24 24" aria-hidden="true"><path d="M20 12a8 8 0 1 1-2.34-5.66"/><path d="M20 4v4h-4"/></svg>
              Re-run audit
            </button>
          </div>
        </div>
        <p className="gen">
          FoldReady CLI · result contract v5 · {app.uiFiles} UI files audited, {app.excludedFiles} excluded (tests, previews, vendored)
        </p>
      </header>

      {app.blockers.length > 0 && (
        <section className="block" data-reveal>
          <div className="sec-head">
            <h2>Before the score</h2>
            <span className="id">source signals · require confirmation</span>
          </div>
          <div className="blockers">
            {app.blockers.map((b) => (
              <div key={b.id} className={"blocker" + (b.stopsLaunch ? "" : " optout")}>
                <span className="tag">{b.stopsLaunch ? "POTENTIAL BLOCKER" : "OPT-OUT SIGNAL"}</span>
                <h3>{b.title}{b.file ? <code> {b.file}</code> : null}</h3>
                <p>{b.consequence}</p>
                <a className="src" href={b.reference} rel="noopener noreferrer" target="_blank">Apple source</a>
              </div>
            ))}
          </div>
        </section>
      )}

      <section className="hero-grid">
        <ScoreGauge score={app.score} grade={app.grade} size={260} />
        <div className="hero-right">
          <span className="stamp" style={{ ["--g" as string]: color }}>
            <span className="ck">
              <svg width="9" height="9" viewBox="0 0 24 24" aria-hidden="true"><path d="M6 12.5 L10.2 16.5 L18 8" fill="none" stroke="#052E16" strokeWidth="3.4" strokeLinecap="round" strokeLinejoin="round"/></svg>
            </span>
            {app.grade} · source score band
          </span>
          <p style={{ color: "var(--dim)", fontSize: 14, maxWidth: "58ch", marginTop: 18 }}>{detail.summary}</p>
          <div className="hero-side">
            <div className="stat"><span className="l">Heuristic risk</span><span className="v" style={{ color: app.risk === "low" ? "var(--green)" : app.risk === "medium" ? "var(--gC)" : "var(--gF)" }}>{app.risk}</span></div>
            <div className="stat"><span className="l">Unvalidated estimate</span><span className="v">{app.hours}<span className="u">h</span></span></div>
            <div className="stat"><span className="l">Findings</span><span className="v">{app.findingCount}</span></div>
          </div>
        </div>
      </section>

      <section className="block" data-reveal>
        <div className="sec-head">
          <h2>Check breakdown</h2>
          <span className="id">6 displayed checks · see CLI for full coverage</span>
        </div>
        <div>
          {checkKeys.map((k) => {
            const s = app.checks[k] ?? 100;
            const ok = s >= 70;
            return (
              <div className="chkrow" key={k}>
                <div className="nm">
                  <h3>{CHECK_LABELS[k]}</h3>
                  <div style={{ flex: 1 }} />
                  <span className={`chip ${ok ? "ready" : s >= 40 ? "sev-m" : "sev-b"}`}>
                    {ok ? <span className="dot" /> : null}source heuristic
                  </span>
                </div>
                <div className="m">
                  <SegBar score={s} color={ok ? "var(--green)" : s >= 40 ? "var(--gD)" : "var(--gF)"} />
                  <span className="score" style={{ color: ok ? "var(--green)" : s >= 40 ? "var(--gD)" : "var(--gF)" }}>{s}</span>
                </div>
                <p className="dt" style={{ gridColumn: "1/3" }}>{app.details[k]}. {CHECK_MEANING[k]}</p>
              </div>
            );
          })}
        </div>
      </section>

      <section className="block" data-reveal>
        <div className="sec-head">
          <h2>Findings</h2>
          <span className="id">sample · {app.findings.length} of {app.findingCount} rows</span>
        </div>
        <div className="fstats">
          <span className="fs"><i style={{ background: "var(--sevMajor)" }} />Major signals<b className="mono" style={{ color: "var(--sevMajor)" }}>{majorCount}</b></span>
          <span className="fs"><i style={{ background: "var(--dim)" }} />Minor<b className="mono">{minorCount}</b></span>
          <span className="fs"><i style={{ background: "var(--gD)" }} />Leading check<b className="mono">{CHECK_LABELS[weakest.k]} · {app.checks[weakest.k]}</b></span>
        </div>
        <table className="tbl">
          <thead>
            <tr><th style={{ width: 96 }}>Severity</th><th style={{ width: 170 }}>Check</th><th>Signal and confidence</th><th style={{ width: 230 }}>Location</th></tr>
          </thead>
          <tbody>
            {app.findings.map((f, i) => (
              <tr key={i}>
                <td><SeverityChip severity={f.severity} /></td>
                <td className="chk">{f.check}</td>
                <td className="msg">{f.message}<p>Confidence: {f.confidence ?? "not retained in this index; re-run CLI"}. Runtime: not tested.</p></td>
                <td className="file">{f.file}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <section className="block" data-reveal style={{ borderBottom: 0 }}>
        <div className="sec-head">
          <h2>Proposed review order</h2>
          <span className="note">human priority not assessed</span>
        </div>
        {road.map((s, i) => (
          <div className="road" key={i}>
            <span className="no">{String(i + 1).padStart(2, "0")}</span>
            <div>
              <h3>{s.title}</h3>
              <p>{s.body}</p>
            </div>
          </div>
        ))}
      </section>

      <p className="spec">Patch proposals are not generated in this report. Run the current CLI to prepare a reviewed work order.</p>

      <section className="block" style={{ borderBottom: 0 }}>
        <div className="band">
          <div>
            <h2>Validate the signals with a human review.</h2>
            <p>A reviewer confirms target relevance, journey impact and the next test. Re-scanning can show changed signals; it cannot prove runtime fixes.</p>
          </div>
          <div className="band-acts">
            <a className="btn btn-ghost" href="#">
              <svg className="ic" viewBox="0 0 24 24" aria-hidden="true"><path d="M20 12a8 8 0 1 1-2.34-5.66"/><path d="M20 4v4h-4"/></svg>
              Re-run audit
            </a>
            <a className="btn btn-sec" href={href("/#pricing")}>Request a review
              <svg className="ic" viewBox="0 0 24 24" aria-hidden="true"><path d="M4 12h16"/><path d="M13 6l6 6-6 6"/></svg>
            </a>
          </div>
        </div>
      </section>
    </main>
  );
}
