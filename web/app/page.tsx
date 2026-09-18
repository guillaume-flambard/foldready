import Link from "next/link";

export default function LandingPage() {
  return (
    <main className="wrap">
      <header className="hero">
        <div>
          <span className="kicker">iPhone Duo · launch 23 October 2026</span>
          <h1>Find what needs attention before your app reaches iPhone Duo.</h1>
          <p className="lede">Review your critical journeys, identify layout risks and agree the fixes. FoldReady combines a free source scanner with a human review of your app and its test coverage.</p>
          <div className="ctas">
            <Link className="btn btn-pri" href="/get-scored">Request a review · $349</Link>
            <a className="btn btn-ghost" href="https://github.com/guillaume-flambard/foldready#usage">Run the free scanner</a>
          </div>
        </div>
        <div className="ocard">
          <h2>What is available today</h2>
          <p>Source analysis, a review of up to three agreed critical journeys, and a prioritized test and remediation plan. Existing apps can run on Duo without recompilation.</p>
          <p>Duo simulator testing depends on Xcode 27.1 beta, announced for later in September. Any later simulator pass is scoped separately. Physical-device testing is not included.</p>
          <a href="https://developer.apple.com/iphone-duo/">Apple tools and availability</a>
        </div>
      </header>

      <section className="block" id="how">
        <div className="sec-head-land">
          <p className="lab">How the review works</p>
          <h2>A report your team can act on.</h2>
          <p>For teams maintaining older UIKit apps or custom interfaces with critical flows to protect.</p>
        </div>
        <div className="offer">
          <div className="ocard"><h3>1. Agree the scope</h3><p>One app, one source revision and up to three critical journeys. Confirm access, build requirements and available test environments before work starts.</p></div>
          <div className="ocard"><h3>2. Separate evidence from assumptions</h3><p>Source signals are candidates for review. Reproduced defects include the environment, steps and evidence. Optional improvements, such as a sidebar, are listed separately.</p></div>
          <div className="ocard"><h3>3. Decide the next change</h3><p>Get a prioritized plan and a work order your team or coding agent can use. Corrections are quoted after review, with acceptance criteria for each agreed journey.</p></div>
        </div>
      </section>

      <section className="block" id="pricing">
        <div className="sec-head-land"><p className="lab">Pricing</p><h2>Start with a scoped review.</h2><p>The paid service covers analysis and human judgement. The scanner remains free and local.</p></div>
        <div className="pricing">
          <div className="pcard">
            <h3>Source scanner</h3><p className="price">Free</p>
            <p className="what">Repeatable source signals for your team and CI.</p>
            <ul><li>Layout and navigation checks with Apple sources</li><li>Heuristic score and effort estimate</li><li>Local reports and regression policies</li><li>Work orders for reviewed changes</li></ul>
            <a className="btn btn-sec" href="https://github.com/guillaume-flambard/foldready#usage">Get the CLI</a>
          </div>
          <div className="pcard featured">
            <span className="flag">Human review</span><h3>Readiness review</h3><p className="price">$349 <small>/ app</small></p>
            <p className="what">One source revision and up to three agreed critical journeys.</p>
            <ul><li>Source findings reviewed for relevance</li><li>SDK and build assumptions documented</li><li>Available screenshots reviewed in context</li><li>Prioritized fixes and Duo test checklist</li><li>One follow-up review of the same scope within 30 days</li></ul>
            <Link className="btn btn-pri" href="/get-scored">Request a review</Link>
          </div>
          <div className="pcard">
            <h3>Corrections and validation</h3><p className="price">Scoped quote</p>
            <p className="what">Implementation and testing against agreed acceptance criteria.</p>
            <ul><li>Fixes selected from the review</li><li>Build and test environment agreed in advance</li><li>Before/after evidence for tested journeys</li><li>Untested configurations explicitly listed</li></ul>
            <Link className="btn btn-sec" href="/get-scored">Discuss the scope</Link>
          </div>
        </div>
      </section>

      <section className="block" id="objections" style={{ borderBottom: 0 }}>
        <div className="sec-head-land"><p className="lab">Before you start</p><h2>What the results mean.</h2></div>
        <div className="obj">
          <div className="ocard2"><p className="q">Does every app need a port?</p><p className="a">No. Apple says existing apps run without recompilation, and standard navigation adapts automatically. The review focuses on your custom layouts and critical journeys. A sidebar is an optional design choice.</p></div>
          <div className="ocard2"><p className="q">Does a high score prove compatibility?</p><p className="a">No. Source analysis cannot prove rendering, state preservation or a successful launch. Screenshot margins can come from compatibility presentation or intentional spacing. Runtime evidence needs a named build, environment and tested journey.</p></div>
          <div className="ocard2"><p className="q">Why use this alongside Apple tooling?</p><p className="a">Apple announced the App Resizability skill for Xcode 27.1. FoldReady helps prioritize the work and record what was checked; your team can use Apple tooling to implement changes.</p></div>
          <div className="ocard2"><p className="q">When can Duo testing happen?</p><p className="a">Apple lists Xcode 27.1 beta for later in September. Confirm tool availability and build access when agreeing a simulator pass. Every delivery names the environments actually tested.</p></div>
        </div>
        <p className="spec">Sources, checked 11 September 2026: <a href="https://www.apple.com/newsroom/2026/09/apple-unveils-iphone-duo/">Apple announcement</a> · <a href="https://developer.apple.com/videos/play/tech-talks/111461/">Prepare your app for iPhone Duo</a> · <a href="https://developer.apple.com/videos/play/tech-talks/111463/">Adaptive layouts</a>.</p>
        <p className="spec"><Link href="/ranking">View historical source audits</Link>. These pre-announcement scores are archived, not current Duo compatibility results.</p>
      </section>
    </main>
  );
}
