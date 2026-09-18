import type { Metadata } from "next";
import { GetScoredForm } from "@/components/GetScoredForm";

export const metadata: Metadata = {
  title: "Request a readiness review | FoldReady",
  description: "A $349 human review of one iOS app and up to three agreed critical journeys, with source findings, a remediation plan and explicit test coverage.",
};

export default function GetScoredPage() {
  return (
    <main className="wrap">
      <header className="head" style={{ paddingBottom: 40 }}>
        <span className="kicker">Readiness review · $349 per app</span>
        <h1>Tell us which journeys matter.</h1>
        <p className="lede">One source revision, up to three critical journeys, reviewed source signals and a prioritized test and remediation plan. We agree access, deliverables and timing before work starts.</p>
        <p className="spec">Duo simulator testing depends on Xcode 27.1 availability and is scoped separately. Physical-device testing is not included. One follow-up review of the same scope within 30 days is included.</p>
      </header>
      <GetScoredForm />
    </main>
  );
}
