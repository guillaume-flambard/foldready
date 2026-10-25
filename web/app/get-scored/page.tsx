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
        <span className="kicker">Source review · $349 / app · runtime testing quoted separately</span>
        <h1>Tell us which journeys matter.</h1>
        <p className="lede">Choose a $349 human source review for one app revision and up to three critical journeys, or enquire about a separately scoped simulator test / fix. The review starts with source findings, not an unverified compatibility claim. We agree access, deliverables, price and timing before paid work.</p>
        <p className="spec">Apple's iPhone Duo simulator is available with Xcode 27.1 and Device Hub, but each test pass still requires a usable local runtime and a buildable app. Simulator testing is scoped separately; physical-device testing is not included. One follow-up review of the same scope within 30 days is included.</p>
      </header>
      <GetScoredForm />
    </main>
  );
}
