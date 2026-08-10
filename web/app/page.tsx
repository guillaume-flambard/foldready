import Link from "next/link";
import { APPS, GRADE_COLOR, type AppScore } from "@/lib/data";
import { ScoreGauge } from "@/components/ScoreGauge";

export default function LandingPage() {
  const hero = APPS[0];
  return (
    <main className="wrap">
      <header className="hero">
        <div>
          <span className="kicker">Launching Sept 2026 · iOS 27</span>
          <h1>Your iOS app, ready for the iPhone Fold.</h1>
          <p className="lede">
            A static + pixel audit that scores your app 0–100 against the foldable
            requirements, estimates the port in hours, and ships it featured-ready on
            the 7.8in inner display.
          </p>
          <div className="ctas">
            <a className="btn btn-pri" href="#pricing">Score my app free</a>
            <a className="btn btn-ghost" href="#how">Read the methodology</a>
          </div>
          <p className="proof-note">
            <span className="row">
              <span className="mono" style={{ color: "var(--gA)" }}>91</span>
              <span className="mono" style={{ color: "var(--gB)" }}>78</span>
              <span className="mono" style={{ color: "var(--gC)" }}>59</span>
            </span>
            Open-source apps already indexed
          </p>
        </div>
        <div>
          <ScoreGauge score={hero.score} grade={hero.grade} size={300} />
        </div>
      </header>

      <section className="proof">
        <p className="lab">The Fold-Ready Index so far</p>
        <div className="row">
          {APPS.map((a: AppScore) => (
            <Link className="app" key={a.slug} href={`/report/${a.slug}`}>
              <span className="n" style={{ color: GRADE_COLOR[a.grade] }}>{a.score}</span>
              <span className="nm">{a.name}<span className="mono">{a.grade}</span></span>
            </Link>
          ))}
        </div>
      </section>

      <section className="block" id="how">
        <div className="sec-head-land">
          <p className="lab">What you get</p>
          <h2>A measurement, a plan, and a ship date.</h2>
          <p>One pipeline from source tree to featured-ready. Each tier feeds the next, so you never re-explain your app.</p>
        </div>
        <div className="offer">
          <div className="ocard">
            <span className="ico">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M5 16a7 7 0 1 1 14 0"/><path d="M12 16l4-5.5"/><circle cx="12" cy="16" r="1.4" fill="currentColor" stroke="none"/></svg>
            </span>
            <h3>Static audit</h3>
            <p>Seven checks against the iOS 27 foldable requirements. You get a 0–100 Fold-Ready Score, a grade, and a port estimate in hours — in minutes, not weeks.</p>
            <span className="tag">self-serve · free</span>
          </div>
          <div className="ocard">
            <span className="ico">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><rect x="4" y="4" width="16" height="16" rx="4"/><circle cx="12" cy="12" r="3.2"/><path d="M9 9l-1.5-1.5M15 9l1.5-1.5M9 15l-1.5 1.5M15 15l1.5 1.5" strokeWidth="1.2"/></svg>
            </span>
            <h3>Captured-layout pass</h3>
            <p>We build your app and open it on the 7.8in inner display. Every finding cites file:line, so your team ships fixes instead of reading essays.</p>
            <span className="tag">in the full report</span>
          </div>
          <div className="ocard">
            <span className="ico">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><rect x="3" y="5" width="18" height="14" rx="2.5"/><path d="M12 5v14"/><path d="M6.5 12l2.2 2.2 4.6-4.6"/></svg>
            </span>
            <h3>Porting service</h3>
            <p>Engineers who shipped foldable UI port your app behind a fixed price and a date. Featured-ready on day one, QA'd on device, before launch.</p>
            <span className="tag">fixed price</span>
          </div>
        </div>
      </section>

      <section className="block" id="pricing">
        <div className="sec-head-land">
          <p className="lab">Pricing</p>
          <h2>Pay for the port, not the guesswork.</h2>
          <p>Audit yourself for free. Buy the captured pass when you need receipts. Let us port it when you need it shipped.</p>
        </div>
        <div className="pricing">
          <div className="pcard">
            <h3>Self-serve audit</h3>
            <p className="price">Free</p>
            <p className="what">Score and hours estimate, generated from your source tree.</p>
            <ul>
              <li>7 static checks, weighted</li>
              <li>0–100 score · A–F grade</li>
              <li>Port estimate in hours</li>
              <li>Findings with file:line</li>
            </ul>
            <a className="btn btn-sec" href="#pricing">Score it yourself</a>
          </div>
          <div className="pcard featured">
            <span className="flag">Recommended</span>
            <h3>Full report</h3>
            <p className="price">$349 <small>/ app</small></p>
            <p className="what">The static audit plus a captured-layout pass with receipts and a roadmap.</p>
            <ul>
              <li>Everything in self-serve</li>
              <li>Captured 7.8in layout pass</li>
              <li>Findings with file:line</li>
              <li>Remediation roadmap by effort</li>
              <li>Re-score included for 90 days</li>
            </ul>
            <a className="btn btn-pri" href="#pricing">Buy full report</a>
          </div>
          <div className="pcard">
            <h3>Porting service</h3>
            <p className="price">From $4,900</p>
            <p className="what">A fixed-price port by engineers who shipped foldable UI.</p>
            <ul>
              <li>Full report included</li>
              <li>Sidebar + adaptive navigation</li>
              <li>Fold-state &amp; scene lifecycles</li>
              <li>QA on device · ship-by date</li>
            </ul>
            <a className="btn btn-sec" href="#pricing">Talk to us</a>
          </div>
        </div>
      </section>

      <section className="block" id="objections" style={{ borderBottom: 0 }}>
        <div className="sec-head-land">
          <p className="lab">Why port</p>
          <h2>The objections we hear, measured.</h2>
        </div>
        <div className="obj">
          <div className="ocard2">
            <p className="q">Parallel View already runs every app — why port?</p>
            <p className="a">It runs them — squeezed into the narrow column. Porting opts your app into the full inner display: a real sidebar on wide, scene lifecycles that survive the hinge, and a Fold-Ready Score you can print in your App Store listing.</p>
          </div>
          <div className="ocard2">
            <p className="q">Can a static check really judge how my UI looks?</p>
            <p className="a">The Fold-Ready audit is static plus a captured-layout pass: we build your app, open it on a 7.8in display, and pixel-check the frames. Findings cite file:line, not vibes.</p>
          </div>
          <div className="ocard2">
            <p className="q">We have no foldable hardware and no time.</p>
            <p className="a">You don't need either. The audit runs headless on your CI and returns an hours estimate; device QA is part of the porting tier, not your problem to source.</p>
          </div>
          <div className="ocard2">
            <p className="q">We're SwiftUI already — aren't we safe?</p>
            <p className="a">Mostly — the framework check is worth only 15% of the score. Navigation and layout carry the weight, and the index shows pure-SwiftUI apps still dropping to C for a single squeezed tab bar.</p>
          </div>
        </div>
      </section>
    </main>
  );
}
