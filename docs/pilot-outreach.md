# FoldReady outreach and qualification protocol — 25 October 2026

Goal: validate *one paid, scoped, evidence-based review*, not to maximize emails sent. Prospects are researched in [prospects-2026-10-25.md](prospects-2026-10-25.md). Zero contacts or sales are recorded as of this writing. Do not send the templates automatically, and do not represent a web search as a relationship or commitment.

## Positioning

- **Problem hypothesis:** native iOS teams can patch layouts using Apple's App Resizability skill, but may still need an independently reviewable record of source risks, critical-journey coverage, and unresolved runtime checks.
- **What is provided:** FoldReady is a free, local Swift source scanner + optional CI gate; the **$349 pilot** is a scoped *human* evidence review of one code revision and up to three journeys with follow-up within 30 days. Scope, access, price, currency, payment and delivery must be agreed explicitly. Simulator validation and code changes are separate quotes.
- **What is not provided:** a source-only compatibility certificate, proof that an app is broken, an Apple-endorsed audit, a guarantee of first-run correctness, or saved developer time without measurements.
- **Competitive truth:** Apple's App Resizability skill (Xcode 27.1) supports SwiftUI + UIKit and may already solve some fixes. Ask how the team verifies the result; do not pretend Apple lacks tooling.

## Draft A — partner / iOS agency

**Subject: Reusable iPhone Duo review evidence for your iOS clients?**

Hi [name/team],

I noticed [one exact published iOS case study or service, with URL]. With iPhone Duo now shipping, I'm testing a focused question: when your team uses Xcode 27.1 and Apple's App Resizability tooling, how do you document which resize/pose journeys were actually verified, which source signals were dismissed, and what should block CI?

I maintain [FoldReady](https://github.com/guillaume-flambard/foldready), a free Swift source scanner with versioned reports and an optional CI regression gate. I'm exploring a small, white-label friendly **evidence review** to complement a native team's existing QA, not to replace it.

Would a one-page example be useful, or do you already have this covered? If it is a problem for your client handoffs, I'd be interested in learning what a useful pilot would need to prove.

Best,
Guillaume

## Draft B — independent app developer

**Subject: How are you checking iPhone Duo resize continuity for [app]?**

Hi [name/team],

I saw [concrete release / product detail, with URL] for [app]. I'm researching how independent iOS teams verify the transition from the outer display to the inner screen, especially navigation, scroll/selection state and custom safe-area controls.

I'm building [FoldReady](https://github.com/guillaume-flambard/foldready): a free local source scanner with an optional CI gate, plus a proposed human review that separates potential code issues from runtime behavior that hasn't been tested. I'm not claiming I've found a bug in [app].

How have you been validating these journeys so far? If it's useful, I can share a [one-page example](sales-one-pager.md) of the evidence format; no obligation.

Best,
Guillaume

## Discovery call — questions in order

1. What app versions / SDK / devices do you currently ship, and who decides release readiness?
2. How do you test resizing and transitions today? Can you show one reproducible acceptance record?
3. Does your native team already use Device Hub, App Resizability and CI/snapshot tests? What is missing, if anything?
4. What is the actual consequence of a missed layout/continuity bug? Which three journeys matter most?
5. Would you pay for an independent report without code changes? How much time and budget would you allocate? What purchasing process applies?
6. What would make a one-revision trial a *no*? What artifact, scope, date and evidence would make it a *yes*?

**Commercial test decision:** aim for five genuine discovery discussions, then one explicitly paid scoped review. Record actual prep, human review, build/test, remediation and follow-up hours *separately*. A website visit, a free scan, or “sounds interesting” isn't demand. If the decision maker values only code fixes and will not pay for an independent audit, stop pushing this offer or re-scope it consciously.

## Operational steps

- Look up the existing relationship/outreach log before each approach; do not duplicate earlier contact or violate a no-solicit request.
- Update `docs/outreach-log.tsv` for **actual** actions only (the initial ledger records all candidates as `not_contacted`).
- Reach out only after personalization and channel check; this file does **not** authorize automatic outreach.
- Never send private app source to a third-party service without client permission; a source review can be local.
- One app revision, three user journeys, agreed environment, no unverified runtime passes, and a written delivery date before accepting any payment.
- Retain customer sources, credentials and acceptance evidence outside this public repo.
