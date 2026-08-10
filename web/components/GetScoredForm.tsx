"use client";

import { useState } from "react";

export function GetScoredForm() {
  const [appName, setAppName] = useState("");
  const [repo, setRepo] = useState("");
  const [email, setEmail] = useState("");
  const [sent, setSent] = useState(false);
  const [copied, setCopied] = useState(false);

  const cliCmd = `foldready ${repo.trim() || "<repo>"} --name "${appName.trim() || "App"}"`;

  function submit(e: React.FormEvent) {
    e.preventDefault();
    const subject = encodeURIComponent(`Fold-Ready Score: ${appName.trim() || "my app"}`);
    const body = encodeURIComponent(
      `App: ${appName.trim()}\nRepo / source: ${repo.trim()}\nEmail: ${email.trim()}\n\nI want the Fold-Ready audit (score, findings with file:line, hours estimate).`
    );
    window.location.href = `mailto:hello@foldready.com?subject=${subject}&body=${body}`;
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
          <span>Repo URL or local path <em>optional</em></span>
          <input value={repo} onChange={(e) => setRepo(e.target.value)} placeholder="https://github.com/org/my-app or ~/code/my-app" />
        </label>
        <label className="field">
          <span>Work email</span>
          <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="you@company.com" required />
        </label>
        <button className="btn btn-pri" type="submit" style={{ width: "100%" }}>Request my Fold-Ready Score</button>
        <p className="spec" style={{ marginTop: 10 }}>
          Opens your mail client with the details prefilled. We reply within 48h with the score, every blocking finding (file:line) and an hours estimate. $349 for the full report with the captured-layout pass.
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
          <code>foldready port &lt;repo&gt; --tiers srm</code> generates the porting patch.
        </p>
        {sent && (
          <p className="chip ready" style={{ marginTop: 14 }}>
            <span className="dot" /> Mail client opened — hit send and we'll take it from there.
          </p>
        )}
      </div>
    </div>
  );
}
