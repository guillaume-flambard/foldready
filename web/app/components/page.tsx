import type { Metadata } from "next";
import { APPS } from "@/lib/data";
import { ScoreGauge } from "@/components/ScoreGauge";
import { ScoreCard, SegBar, CheckBar } from "@/components/ScoreCard";
import { href } from "@/lib/href";

export const metadata: Metadata = {
  title: "FoldReady · Design System v2",
  description: "Component catalog for FoldReady — all 12 components on dark and light.",
};

const PALETTE = [
  ["Ink", "#0F172A", "canvas"], ["Ink 2", "#0B1220", "inset"], ["Panel", "#1E293B", "card"],
  ["Panel 2", "#24344D", "hover"], ["Slate 1", "#334155", "border"], ["Slate 2", "#475569", "line"],
  ["Screen Blue", "#0EA5E9", "accent"], ["Sky", "#7DD3FC", "hover"], ["Ready Green", "#22C55E", "ready"],
  ["Text", "#E2E8F0", "primary"], ["Dim", "#94A3B8", "secondary"],
];

type RampEntry = [string, string, string, React.CSSProperties];

const RAMP: RampEntry[] = [
  ["Display / 64", "Your app, ready.", "Space Grotesk 700 · -0.03em", { font: "700 64px/1 var(--font-display)", letterSpacing: "-.03em" }],
  ["Display / 32", "Fold-Ready Score", "Space Grotesk 700", { font: "700 32px/1.1 var(--font-display)", letterSpacing: "-.02em" }],
  ["Body / 17", "A static and pixel audit of your iOS source tree.", "Inter 400 · 1.6", { font: "400 17px/1.6 var(--font-body)" }],
  ["Body / 13", "Adaptive navigation / sidebar", "Inter 500", { font: "500 13px/1.5 var(--font-body)" }],
  ["Data / 15", "214 h · 42 findings · 78.0", "JetBrains Mono · tabular", { font: "700 15px/1.4 var(--font-mono)" }],
  ["Caption / 11", "Parallel view opt-in", "Inter 600 · +0.08em caps", { font: "600 11px/1.4 var(--font-body)", letterSpacing: ".08em", textTransform: "uppercase", color: "var(--dim)" }],
];

const SPACING = [4, 8, 12, 16, 24, 32, 48, 64];
const ic = APPS[1];

export default function ComponentsPage() {
  return (
    <main className="wrap">
      <header className="head">
        <span className="kicker">Product design system · v2</span>
        <h1>FoldReady design system</h1>
        <p className="lede">
          FoldReady is a precision instrument: an audit that scores and ports iOS apps for
          the iPhone Fold. The system speaks like a calibrated tool — monospaced
          measurements, hairline structure, one vivid accent that means focus. Nothing
          bounces, nothing pleads; the numbers carry the confidence.
        </p>
        <div className="meta">
          <span>Components <b className="mono">12</b></span>
          <span>Themes <b>Dark · Light</b></span>
          <span>Tokens <b className="mono">22</b></span>
          <span>Accents <b className="mono">2</b> · blue + green(ready)</span>
          <span>Launch <b>Sept 2026</b></span>
        </div>
      </header>

      <section className="block" id="tokens">
        <div className="sec-head"><h2>Tokens</h2><span className="id">DESIGN.md</span></div>
        <p className="spec" style={{ marginBottom: 16 }}>Colors · type · spacing · radius · motion · grade bands. Toggle the theme in the nav to view both variants.</p>
        <div className="swgrid">
          {PALETTE.map(([nm, hex, role]) => (
            <div className="sw" key={nm as string}>
              <div className="chipc" style={{ background: hex as string }} />
              <div className="nm">{nm}</div>
              <div className="vl">{hex} · {role}</div>
            </div>
          ))}
        </div>
        <div className="grades">
          <span className="gchip a">A</span><span className="gchip b">B</span>
          <span className="gchip c">C</span><span className="gchip d">D</span><span className="gchip f">F</span>
          <span className="spec" style={{ alignSelf: "center" }}>Grade = letter + color, always together. A Ready Green · F Red.</span>
        </div>
        <div className="ramp">
          {RAMP.map(([pt, sample, val, style]) => (
            <div className="r" key={pt as string}>
              <span className="pt">{pt}</span>
              <span className="sample" style={style as React.CSSProperties}>{sample}</span>
              <span className="val">{val}</span>
            </div>
          ))}
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 24, marginTop: 28 }}>
          <div>
            <p className="spec" style={{ marginBottom: 8 }}>Spacing · 4px base</p>
            {SPACING.map((px) => (
              <div className="space" key={px}>
                <span className="nm">{String(px).padStart(2, "0")}</span>
                <span className="ln" style={{ width: px }} />
                <span className="px">{px}px</span>
              </div>
            ))}
          </div>
          <div>
            <p className="spec" style={{ marginBottom: 8 }}>Radius</p>
            <div className="rp">
              {[0, 8, 14, 999].map((r) => (
                <div className="rpill" key={r} style={{ borderRadius: r === 999 ? 999 : r }}>{r === 999 ? "999" : r}</div>
              ))}
            </div>
            <p className="spec" style={{ margin: "20px 0 8px" }}>Motion</p>
            <div className="rp">
              <div className="mcell"><div className="t">State change</div><span className="spec">150ms · ease-out · fade + 4–8px slide</span></div>
              <div className="mcell"><div className="t">Gauge lands</div><span className="spec">spring · cubic-bezier(.16,1,.3,1) · once</span></div>
            </div>
          </div>
        </div>
      </section>

      <section className="block" id="gallery" style={{ borderBottom: 0 }}>
        <div className="sec-head"><h2>Components</h2><span className="id">01 — 12</span></div>

        <div className="frame" style={{ marginBottom: 16 }}>
          <div className="comphead"><span className="no">01</span><h3>Score gauge</h3><span className="spec">Arc · mono value · grade color · lands on load</span></div>
          <ScoreGauge score={78} grade="A" size={240} />
        </div>

        <div className="frame" style={{ marginBottom: 16 }}>
          <div className="comphead"><span className="no">02</span><h3>Score card</h3><span className="spec">Grade chip · risk · hours · weak checks</span></div>
          <ScoreCard app={ic} rank={2} />
        </div>

        <div className="frame" style={{ marginBottom: 16 }}>
          <div className="comphead"><span className="no">03</span><h3>Check bar</h3><span className="spec">10-step segmented bar · one per foldable check</span></div>
          <div style={{ display: "flex", flexDirection: "column", gap: 12, maxWidth: 560 }}>
            <CheckBar label="Adaptive layout" score={93} weight="w 0.20" color="var(--blue)" />
            <CheckBar label="Parallel View opt-in" score={100} weight="w 0.10" color="var(--green)" />
            <CheckBar label="Adaptive navigation" score={40} weight="w 0.20" color="var(--gD)" />
          </div>
        </div>

        <div className="frame" style={{ marginBottom: 16 }}>
          <div className="comphead"><span className="no">04</span><h3>Finding row</h3><span className="spec">Severity · check · message · file:line</span></div>
          <div className="row2">
            <div className="frow">
              <span className="chip sev-m"><span className="dot" />Major</span>
              <span className="chk">Adaptive layout</span>
              <span className="msg">UIScreen.main.bounds is a fixed geometry read; use the scene coordinate space.</span>
              <span className="file">SceneDelegate.swift:11</span>
            </div>
            <div className="frow">
              <span className="chip sev-n"><span className="dot" />Minor</span>
              <span className="chk">Fold state</span>
              <span className="msg">Hardcoded frame width/height literals will not reflow on the 7.8in inner display.</span>
              <span className="file">GalleryToolbarView.swift:31</span>
            </div>
          </div>
        </div>

        <div className="frame" style={{ marginBottom: 16 }}>
          <div className="comphead"><span className="no">05</span><h3>Stat card</h3><span className="spec">Label + large mono value</span></div>
          <div className="row3">
            <div className="stat"><span className="l">Est. port</span><span className="v">214<span className="u">h</span></span></div>
            <div className="stat"><span className="l">Findings</span><span className="v">37</span></div>
            <div className="stat"><span className="l">Risk</span><span className="v" style={{ color: "var(--green)" }}>low</span></div>
            <div className="stat"><span className="l">Swift files</span><span className="v">424</span></div>
          </div>
        </div>

        <div className="frame" style={{ marginBottom: 16 }}>
          <div className="comphead"><span className="no">06</span><h3>Button</h3><span className="spec">Primary · secondary · ghost · disabled</span></div>
          <div className="row3" style={{ alignItems: "center" }}>
            <a className="btn btn-pri" href="#gallery">Score my app</a>
            <a className="btn btn-sec" href="#gallery">Read the methodology</a>
            <a className="btn btn-ghost" href="#gallery">View report</a>
            <button className="btn btn-pri" disabled>Disabled</button>
          </div>
        </div>

        <div className="frame" style={{ marginBottom: 16 }}>
          <div className="comphead"><span className="no">07</span><h3>Chip / pill</h3><span className="spec">Severity · weak check · tag · grade</span></div>
          <div className="row3" style={{ alignItems: "center" }}>
            <span className="chip sev-b"><span className="dot" />Blocker</span>
            <span className="chip sev-m"><span className="dot" />Major</span>
            <span className="chip sev-n"><span className="dot" />Minor</span>
            <span className="chip ready">Ready</span>
            <span className="chip weak">Sidebar 40</span>
            <span className="gchip a">A</span>
            <span className="gchip c">C</span>
          </div>
        </div>

        <div className="frame" style={{ marginBottom: 16 }}>
          <div className="comphead"><span className="no">08</span><h3>Table</h3><span className="spec">Hairline rows · mono cells · numbers right-aligned</span></div>
          <table className="tbl">
            <thead><tr><th>App</th><th>Grade</th><th>Score</th><th>Risk</th><th>Port</th><th className="r">Findings</th></tr></thead>
            <tbody>
              {APPS.map((a) => (
                <tr key={a.slug}>
                  <td className="mono">{a.name}</td>
                  <td><span className={`gchip ${a.grade.toLowerCase()}`}>{a.grade}</span></td>
                  <td className="r mono">{a.score}</td>
                  <td>{a.risk}</td>
                  <td className="r mono">{a.hours}h</td>
                  <td className="r mono">{a.findings}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className="frame" style={{ marginBottom: 16 }}>
          <div className="comphead"><span className="no">09</span><h3>Report page shell</h3><span className="spec">Full shell → /report/icecubesapp</span></div>
          <div className="report">
            <div className="rh">
              <span className="name">IceCubesApp</span>
              <span className="meta">Dimillian/IceCubesApp</span>
              <span className="stamp" style={{ ["--g" as string]: "var(--gA)", marginLeft: "auto" }}>
                <span className="ck"><svg width="9" height="9" viewBox="0 0 24 24" aria-hidden="true"><path d="M6 12.5 L10.2 16.5 L18 8" fill="none" stroke="#052E16" strokeWidth="3.4" strokeLinecap="round" strokeLinejoin="round"/></svg></span>
                A · Ready
              </span>
            </div>
            <div className="rbody">
              <div style={{ display: "flex", flexDirection: "column", gap: 20, alignItems: "center" }}>
                <ScoreGauge score={78} grade="A" size={240} />
              </div>
              <div className="checklist" style={{ display: "flex", flexDirection: "column", gap: 10 }}>
                <CheckBar label="Adaptive layout" score={93} color="var(--blue)" />
                <CheckBar label="Parallel View" score={100} color="var(--green)" />
                <CheckBar label="Navigation" score={40} color="var(--gD)" />
                <CheckBar label="SwiftUI / UIKit" score={91} color="var(--blue)" />
              </div>
            </div>
          </div>
        </div>

        <div className="frame" style={{ marginBottom: 16 }}>
          <div className="comphead"><span className="no">11</span><h3>Nav</h3><span className="spec">Mark + wordmark · links · one primary CTA</span></div>
          <div className="nav" style={{ border: "1px solid var(--line)", borderRadius: 12, padding: "0 18px", height: 64 }}>
            <a className="brand" href={href("/")}><span style={{ fontSize: 18 }} className="wordmark">foldready</span></a>
            <div className="links"><a href={href("/ranking")}>Index</a><a href={href("/report/icecubesapp")}>Reports</a><a href={href("/components")} aria-current="page">Design system</a></div>
            <div className="right"><a className="btn btn-pri" style={{ padding: "10px 18px", fontSize: 14 }} href={href("/#pricing")}>Get scored</a></div>
          </div>
        </div>

        <div className="frame">
          <div className="comphead"><span className="no">12</span><h3>Empty · no weak checks</h3><span className="spec">Confident, never empty</span></div>
          <div className="empty">
            <span className="tile">
              <svg width="24" height="24" viewBox="0 0 24 24" aria-hidden="true"><path d="M6 12.5 L10.2 16.5 L18 8" fill="none" stroke="#052E16" strokeWidth="3.2" strokeLinecap="round" strokeLinejoin="round"/></svg>
            </span>
            <h4>All 7 checks pass</h4>
            <p>Zero findings across every foldable check. MochiDiffusion is ready for the 7.8in inner display — no port required.</p>
            <a className="btn btn-sec" href={href("/report/mochidiffusion")}>Download clean report</a>
          </div>
        </div>
      </section>
    </main>
  );
}
