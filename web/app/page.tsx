import Link from "next/link";

export default function LandingPage() {
  return (
    <main className="wrap">
      <header className="hero">
        <div>
          <span className="kicker">Human review · source evidence and test coverage</span>
          <h1>Know what breaks when your iPhone app resizes.</h1>
          <p className="lede">Apple can help fix resizing code. FoldReady helps you decide what matters: review risky source patterns, prioritize three critical user journeys, and document which behaviors still need real-device or simulator testing.</p>
          <div className="ctas">
            <Link className="btn btn-pri" href="/get-scored">Request a review · $349</Link>
            <a className="btn btn-ghost" href="https://github.com/guillaume-flambard/foldready/blob/main/docs/sales-one-pager.md">See a review example</a>
          </div>
        </div>
        <div className="ocard">
          <h2>What you can request today</h2>
          <p>For $349: one code revision, up to three agreed user journeys, a human-reviewed source risk list, explicit blind spots and a prioritized verification and remediation plan.</p>
          <p>Simulator pose testing and code fixes are <strong>not included</strong> in the review. They require a buildable app, a working test environment and a separate scope. No device compatibility certification.</p>
          <a href="https://developer.apple.com/iphone-duo/">Apple tools and availability</a>
        </div>
      </header>


      <section className="block" id="example">
        <div className="sec-head-land">
          <p className="lab">Evidence, not just scores</p>
          <h2>Fewer false alarms. Clearer decisions.</h2>
          <p>See how a historical IceCubesApp source audit becomes an actionable human review, without claiming an unperformed iPhone Duo test.</p>
        </div>
        <div className="offer">
          <div className="ocard"><h3>Window dimensions</h3><p>Six reports of `UIScreen.main.bounds` were grouped into one possible scene-sizing cause, with an exact reproduction question.</p></div>
          <div className="ocard"><h3>Hidden wide-screen navigation</h3><p>An iPad/Mac device check might conceal an extra column. Verify the size class in the running app before editing.</p></div>
          <div className="ocard"><h3>State and false positives</h3><p>A flagged file was a genuine scanner false positive. Actual scroll and selection continuity remain untested until an app run.</p></div>
        </div>
        <p className="spec" style={{ marginTop: 18 }}>Historical source review only; exact app revision not pinned; no Duo runtime verdict.{" "}
          <a href="https://github.com/guillaume-flambard/foldready/blob/main/docs/sample-review.md">See the full annotated example</a>.
        </p>
        <p className="spec" style={{ marginTop: 8 }}>
          Executed synthetic-app evidence: an iOS 27 UIKit launch crash fixed with UIScene,
          followed by a real passing foreground interaction test.{" "}
          <a href="https://github.com/guillaume-flambard/foldready/blob/main/docs/ios27-scene-runtime-case-study.md">
            Read the verified before/after case study
          </a>.
          This is not a Duo folding test or a client success story.
        </p>
      </section>
      <section className="block" id="how">
        <div className="sec-head-land">
          <p className="lab">How the review works</p>
          <h2>A report your team can act on.</h2>
          <p>For iOS teams protecting forms, navigation, editing and other critical flows across changing window sizes.</p>
        </div>
        <div className="offer">
          <div className="ocard"><h3>1. Agree the scope</h3><p>Agree one app revision, up to three journeys, your code access method and a delivery date before payment.</p></div>
          <div className="ocard"><h3>2. Separate evidence from assumptions</h3><p>Group duplicate signals, dismiss false positives and explain user impact. We never mark an unexecuted simulator journey as passed.</p></div>
          <div className="ocard"><h3>3. Decide the next change</h3><p>Receive priorities, a pose-specific verification checklist and work orders for your team or coding agent. Fixes and runtime validation are separate.</p></div>
        </div>
      </section>

      <section className="block" id="pricing">
        <div className="sec-head-land"><p className="lab">Pricing</p><h2>Start with a scoped review.</h2><p>The paid service covers analysis and human judgement. The scanner remains free and local.</p></div>
        <div className="pricing">
          <div className="pcard">
            <h3>Source scanner</h3><p className="price">Free</p>
            <p className="what">Run locally without uploading private source code.</p>
            <ul><li>Layout and navigation checks with Apple sources</li><li>Versioned score and unvalidated effort estimate</li><li>Local reports and regression policies</li><li>Work orders for reviewed changes</li></ul>
            <pre className="snippet"><code>{`- uses: guillaume-flambard/foldready@v0`}</code></pre>
            <a className="btn btn-sec" href="https://github.com/guillaume-flambard/foldready#usage">Get the CLI</a>
          </div>
          <div className="pcard featured">
            <span className="flag">Human review</span><h3>Readiness review</h3><p className="price">$349 <small>/ app</small></p>
            <p className="what">One source revision and up to three agreed journeys; no runtime pose test included.</p>
            <ul><li>Source findings reviewed for relevance</li><li>SDK and build assumptions documented</li><li>Available screenshots reviewed in context</li><li>Prioritized fixes and Duo test checklist</li><li>One follow-up review of the same scope within 30 days</li></ul>
            <Link className="btn btn-pri" href="/get-scored">Request the source review</Link>
          </div>
          <div className="pcard">
            <h3>Corrections and validation</h3><p className="price">Scoped quote</p>
            <p className="what">Optional implementation and reproduced tests on an agreed, available environment.</p>
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
          <div className="ocard2"><p className="q">Why use this alongside Apple tooling?</p><p className="a">Apple's App Resizability skill in Xcode 27.1 supports SwiftUI and UIKit code changes. FoldReady provides source evidence, an optional CI gate and a human-reviewed priority order. Neither a scanner score nor an automated fix is a compatibility certificate.</p></div>
          <div className="ocard2"><p className="q">When can Duo testing happen?</p><p className="a">Xcode 27.1 and Device Hub are available from Apple. A paid simulator pass is scoped separately after confirming a buildable app and a working local device/runtime. Every delivery identifies the journeys and configurations actually tested.</p></div>
        </div>
        <p className="spec">Sources, checked 25 October 2026: <a href="https://developer.apple.com/news/?id=kkphp5qo">Apple Xcode 27.1 and Device Hub</a> · <a href="https://developer.apple.com/videos/play/tech-talks/111461/">Prepare your app for iPhone Duo</a> · <a href="https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications">iPhone Duo screenshot specifications (April 2027 SDK-specific requirement)</a>.</p>
        <p className="spec"><Link href="/ranking">Source audits of twenty open-source apps</Link>. Scores are labelled by contract; they are source signals, not Duo runtime verdicts.</p>
      </section>
    </main>
  );
}
