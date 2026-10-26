# AI Agent Handoff Contract

## Mission

Implement the Document Scanner + PDF Toolkit according to the repository documentation. Deliver a polished, reliable Android and iOS app with local document processing and no cloud document uploads.

## Required reading order

1. `README.md`
2. `docs/PRD/MASTER_PRD.md`
3. `docs/PRD/FEATURE_SPECIFICATIONS.md`
4. `docs/Architecture/SYSTEM_ARCHITECTURE.md`
5. `docs/Architecture/PDF_ENGINE_DECISION.md`
6. `docs/Security/PRIVACY_AND_SECURITY.md`
7. `docs/UI_UX/DESIGN_SYSTEM.md`
8. The active phase prompt and its dependencies.

## Operating rules

- Inspect the actual repository, git status, existing conventions, and build configuration before editing.
- Do not assume files, services, package IDs, Firebase IDs, API keys, or SDKs exist.
- Do not silently overwrite user files or configuration.
- Do not commit, push, publish, or release unless explicitly instructed.
- Do not install arbitrary packages without checking maintenance, license, platform support, and offline behavior.
- Do not use placeholders, mock results, or fake success paths in production features.
- A button is not a completed feature: implement the real operation and verify output.
- Never send documents, OCR text, signatures, filenames, or document metadata to cloud services or analytics.
- Keep secrets out of source control and logs.
- Do not disable tests, analysis rules, security checks, or error handling to make a build pass.
- Do not proceed past a phase's exit criteria without reporting blockers and asking for approval when a decision is required.

## Required workflow per phase

1. Inspect the repository and phase dependencies.
2. Summarize the implementation plan briefly.
3. Implement a small coherent vertical slice at a time.
4. Run formatter, static analysis, unit tests, widget tests, integration tests where feasible, and platform builds.
5. Fix root causes; report any test that cannot run and why.
6. Verify real output files using independent readers/tools where possible.
7. Review privacy, performance, accessibility, and platform differences.
8. Update docs, ADRs, and changelog.
9. Report files changed, tests run/results, limitations, risks, and next steps.

## Phase completion report template

- Phase and scope:
- Implemented features:
- Files/modules changed:
- Tests run and results:
- Android build status:
- iOS build status:
- Offline/privacy verification:
- Performance observations:
- Known issues or unsupported cases:
- Dependency/license changes:
- Documentation updated:
- Recommended next action:

## Conflict handling

If the repository conflicts with these documents, do not blindly overwrite. Identify the conflict, assess the safest compatible option, and document a decision. If a decision changes product scope, privacy, licensing, security, or monetization, request approval.
