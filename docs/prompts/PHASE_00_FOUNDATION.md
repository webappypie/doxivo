# Phase 00 — Foundation and Proof of Concept

## Mission
Inspect the repository and resolve architecture risks before building full features.

## Read first
README, MASTER_PRD, FEATURE_SPECIFICATIONS, SYSTEM_ARCHITECTURE, PDF_ENGINE_DECISION, OCR_ARCHITECTURE, PRIVACY_AND_SECURITY, TEST_STRATEGY, WAPCentral guide if present.

## Tasks
1. Inspect repository and report current state without destructive changes.
2. Confirm app name/IDs are unresolved unless explicitly provided.
3. Compare scanner options for Android/iOS, including first-use offline behavior.
4. Evaluate at least two PDF engine candidates if practical, including license and platform coverage.
5. Prototype image-to-PDF, merge, split, render, encryption and compression.
6. Evaluate offline OCR for intended languages on both platforms.
7. Select local database, state management and dependency-injection approach.
8. Establish fixture corpus and initial performance baselines.
9. Write ADRs with evidence and open risks.
10. Configure formatting, static analysis, unit-test harness and CI checks if repository supports them.

## Restrictions
- Do not implement the full application yet.
- Do not invent credentials or identifiers.
- Do not commit/push.
- Do not select a library without license review.
- Do not make network-dependent scanner/OCR the only path without approved offline behavior.

## Exit criteria
- PDF engine decision supported by POC and license review.
- Scanner approach documented for both platforms.
- OCR languages and offline setup verified or explicitly marked as blockers.
- Minimum OS/toolchain compatibility matrix proposed.
- Architecture decisions recorded.
- Initial tests run and results reported.

## Report
Use the Phase Completion Report in AI_AGENT_HANDOFF.md. Stop for approval if a product/privacy/licensing decision remains unresolved.
