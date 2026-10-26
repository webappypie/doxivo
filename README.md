# Document Scanner + PDF Toolkit

**Project status:** Documentation baseline v1.0  
**Platforms:** Android + iOS  
**Client:** Flutter with native Kotlin/Swift integrations  
**Privacy model:** Local-first, offline document processing, no cloud document uploads  
**Monetization:** Free with ads + one-time lifetime purchase to remove ads; no subscription

> **Working name only:** “Document Scanner + PDF Toolkit” is a descriptive project name, not a finalized public brand. Confirm the app/store name before release.

## Product promise

Scan, enhance, organize, convert, secure, and manage documents directly on a phone. The core document workflows must not require an account, a server, or an internet connection after required components have been installed and verified.

## Start here

1. Read `docs/PRD/MASTER_PRD.md`.
2. Read `docs/Architecture/SYSTEM_ARCHITECTURE.md`.
3. Read `docs/Security/PRIVACY_AND_SECURITY.md`.
4. Read `docs/Architecture/PDF_ENGINE_DECISION.md` before selecting libraries.
5. Read `docs/UI_UX/DESIGN_SYSTEM.md` and `docs/UI_UX/SCREEN_SPECIFICATIONS.md`.
6. Complete Phase 00 in `docs/prompts/PHASE_00_FOUNDATION.md`.
7. Do not start feature implementation until the Phase 00 technical gates are approved.

## Documentation map

- `docs/PRD/` — product requirements, feature specifications, user stories and acceptance criteria.
- `docs/Architecture/` — architecture, PDF engine evaluation, OCR, local data and decisions.
- `docs/UI_UX/` — visual system, screen specifications and user flows.
- `docs/Security/` — privacy policy requirements and threat model.
- `docs/Monetization/` — ads and lifetime purchase requirements.
- `docs/Integration/` — WAPCentral and Firebase integration boundaries.
- `docs/Testing/` — test strategy, performance and test corpus.
- `docs/Release/` — release checklist.
- `docs/prompts/` — phase-by-phase AI coding prompts.

## Non-negotiable rules

- No cloud document processing or automatic uploads of documents, images, OCR text, filenames, or signatures.
- No subscription plan.
- Do not claim a feature works until its implementation and tests pass.
- Preserve source files by default; output operations should be safe and recoverable.
- Verify library licensing, platform compatibility, offline behavior, and store policies before release.
- Do not put private credentials, signing keys, service-account keys, or other secrets in Git.
- Do not invent Firebase identifiers, app IDs, bundle IDs, package names, or WAPCentral configuration.
- Never overwrite an existing configuration file without inspecting it and documenting the change.
- AI agents must not commit or push unless explicitly authorized.

## Local development

This documentation does not prescribe unverified package versions. Install a currently supported stable Flutter SDK, Android toolchain, Xcode on macOS, and the dependencies selected in Phase 00. Then run the commands appropriate to the checked-out project:

```bash
flutter doctor
flutter pub get
flutter analyze
flutter test
```

iOS builds and signing require macOS with a compatible Xcode installation. A remote build service may be used if the team chooses one.

## Definition of done

A feature is done only when:
1. It meets its documented acceptance criteria.
2. It handles errors, cancellation, and low-storage conditions.
3. It is tested on relevant Android and iOS paths.
4. It has no unresolved release-blocking security/privacy issue.
5. Documentation and known limitations are updated.
6. The actual generated output is validated, not just the UI.
