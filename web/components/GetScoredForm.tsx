"use client";

import { useState } from "react";

export function GetScoredForm() {
  const [appName, setAppName] = useState("");
  const [repo, setRepo] = useState("");
  const [email, setEmail] = useState("");
  const [journeys, setJourneys] = useState("");
  const [draftPrepared, setDraftPrepared] = useState(false);
  const [reviewType, setReviewType] = useState<"source" | "validation">("source");
  const [copied, setCopied] = useState(false);

  const cliCmd = "foldready <local-source-directory> --json --open";

  function submit(e: React.FormEvent) {
    e.preventDefault();
    const subject = encodeURIComponent(`FoldReady ${reviewType === "source" ? "source review" : "validation enquiry"}: ${appName.trim() || "my app"}`);
    const body = encodeURIComponent(
      `Request type: ${reviewType === "source" ? "$349 human source review, no simulator test" : "Separate quote: runtime validation or corrections"}\nApp: ${appName.trim()}\nRepo / source: ${repo.trim()}\nEmail: ${email.trim()}\nCritical journeys: ${journeys.trim()}\n\nPlease agree scope, access, linked SDK, delivery date, testing capability and price before any paid work.`
    );
    window.location.href = `mailto:hello@memolabs.dev?subject=${subject}&body=${body}`;
    setDraftPrepared(true);
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
          <span>What do you need?</span>
          <select value={reviewType} onChange={(e) => setReviewType(e.target.value as "source" | "validation")}>
            <option value="source">Human source review — $349</option>
            <option value="validation">Discuss Duo runtime testing or fixes — quote</option>
          </select>
        </label>
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
        <button className="btn btn-pri" type="submit" style={{ width: "100%" }}>Open email draft</button>
        <p className="spec" style={{ marginTop: 10 }}>
          Opens a draft in your mail app, not a submitted website form. No message is transmitted until you press Send, no payment is taken, and private source code is not required.
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
        {draftPrepared && (
          <p className="chip ready" style={{ marginTop: 14 }}>
            <span className="dot" /> Draft requested, not sent. If your mail client did not open, email hello@memolabs.dev. Nothing has been sent automatically.
          </p>
        )}
      </div>
    </div>
  );
}
