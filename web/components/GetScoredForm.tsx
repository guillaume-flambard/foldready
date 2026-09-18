"use client";

import { useState } from "react";

export function GetScoredForm() {
  const [appName, setAppName] = useState("");
  const [repo, setRepo] = useState("");
  const [email, setEmail] = useState("");
  const [journeys, setJourneys] = useState("");
  const [sent, setSent] = useState(false);
  const [copied, setCopied] = useState(false);

  const cliCmd = "foldready <local-source-directory> --json --open";

  function submit(e: React.FormEvent) {
    e.preventDefault();
    const subject = encodeURIComponent(`FoldReady readiness review: ${appName.trim() || "my app"}`);
    const body = encodeURIComponent(
      `App: ${appName.trim()}\nRepo / source: ${repo.trim()}\nEmail: ${email.trim()}\nCritical journeys: ${journeys.trim()}\n\nI would like to discuss the $349 readiness review. Please confirm the scope, test environments and delivery date before work starts.`
    );
    window.location.href = `mailto:hello@memolabs.dev?subject=${subject}&body=${body}`;
    setSent(true);
  }

  async function copyCmd() {
    try {
      await navigator.clipboard.writeText(cliCmd);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {}
  }

  return (
    <div className="gs-grid">
      <form className="gs-form" onSubmit={submit}>
        <label className="field">
          <span>App name</span>
          <input value={appName} onChange={(e) => setAppName(e.target.value)} placeholder="MyApp" required />
        </label>
        <label className="field">
          <span>Repository URL <em>optional</em></span>
          <input value={repo} onChange={(e) => setRepo(e.target.value)} placeholder="https://github.com/org/my-app" />
        </label>
        <label className="field">
          <span>Work email</span>
          <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="you@company.com" required />
        </label>
        <label className="field"><span>Up to three critical journeys</span><textarea value={journeys} onChange={(e) => setJourneys(e.target.value)} placeholder="For example: sign in, checkout, account settings" required /></label>
        <button className="btn btn-pri" type="submit" style={{ width: "100%" }}>Prepare review request</button>
        <p className="spec" style={{ marginTop: 10 }}>
          Opens an email draft. Sending it requests a scope discussion; no payment is taken. You do not need to share private source code in this form.
        </p>
      </form>

      <div className="gs-cli">
        <h3 style={{ font: "700 18px/1.2 var(--font-display)", marginBottom: 8 }}>Prefer to run it yourself?</h3>
        <p className="spec" style={{ marginBottom: 12 }}>The audit CLI is free and local. Run it on your source tree, then send us the report.</p>
        <div className="copybox">
          <code>{cliCmd}</code>
          <button type="button" className="btn btn-sec" onClick={copyCmd} style={{ padding: "8px 14px", fontSize: 13 }}>
            {copied ? "Copied" : "Copy"}
          </button>
        </div>
        <p className="spec" style={{ marginTop: 12 }}>
          Then: <code>foldready &lt;repo&gt; --open</code> opens the HTML report, and{" "}
          <code>foldready port &lt;repo&gt;</code> prepares a patch proposal and work order for review.
        </p>
        {sent && (
          <p className="chip ready" style={{ marginTop: 14 }}>
            <span className="dot" /> Email draft requested. If your mail client did not open, email hello@memolabs.dev. Nothing has been sent automatically.
          </p>
        )}
      </div>
    </div>
  );
}
