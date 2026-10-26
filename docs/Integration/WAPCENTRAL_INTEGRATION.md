# WAPCentral Integration Boundary

## Source of truth
Use the user-provided `WAPCentral_App_Integration_Guide` from the repository root. Read the entire relevant guide and inspect existing SDK examples before implementing. Do not invent app IDs, x-app-key values, Firebase settings, endpoints or SDK APIs.

## Scope
WAPCentral may provide approved optional functions such as app notifications, remote configuration, promotion/cross-promotion, and ad configuration if documented by the guide and approved for this app.

## Privacy boundary
WAPCentral must never receive:
- PDF files or page images,
- OCR text or extracted tables,
- signatures or passwords,
- filenames or full local paths,
- document content or derived document metadata.

## Failure behavior
If WAPCentral is unavailable or disabled, core scanning, OCR, PDF operations, local library and export continue to work. Remote config must not be required for essential local features.

## Implementation checklist
- [ ] Read guide and identify required SDK/version/config.
- [ ] Verify app identifier and keys against supplied configuration.
- [ ] Integrate behind a small adapter.
- [ ] Avoid exposing document-layer models to integration code.
- [ ] Verify consent and ad placement rules.
- [ ] Test network-off behavior.
- [ ] Inspect traffic for accidental document data.
- [ ] Document SDK version, initialization order, permissions and troubleshooting.
