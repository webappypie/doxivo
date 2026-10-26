# Master Product Requirements Document

**Version:** 1.0  
**Status:** Approved product direction; technical dependencies require Phase 00 validation.

## 1. Product vision

Build a premium-quality, mobile-first document scanner and PDF toolkit for Android and iOS. Users can capture paper documents, enhance scans, create and transform PDFs, extract searchable text, organize files, and securely export documents without uploading document content to a server.

## 2. Target users

- Students and exam candidates.
- Office employees and remote workers.
- Teachers, freelancers, and consultants.
- Small businesses and self-employed professionals.
- People who frequently submit forms, receipts, IDs, and signed documents.
- Privacy-conscious users who prefer local processing.

## 3. Core value proposition

1. A single place for scanning and common PDF tasks.
2. Fast, predictable interactions with premium visual quality.
3. Offline document processing and local-first storage.
4. Safe handling of originals and clear export outcomes.
5. Free useful functionality with optional one-time ad removal.
6. No subscription and no mandatory account.

## 4. Platforms and implementation

- Flutter shared UI and application logic.
- Native Kotlin/Android and Swift/iOS adapters for platform-specific capabilities.
- Replaceable PDF engine behind an internal interface.
- Local SQLite metadata and managed filesystem storage.
- On-device OCR only.
- Ads and store billing isolated from document processing.

Minimum OS versions and library versions are intentionally not fixed until Phase 00 validates the dependency matrix.

## 5. Launch scope

All approved P0, P1, and P2 features are intended for the initial public launch. Development is phased for risk control, but P1/P2 are not silently removed from the launch scope. If a feature cannot meet quality, offline, legal, or security requirements, it must be explicitly reported as a release blocker or be formally descoped with owner approval.

### P0 — Core launch features
- Single- and multi-page scanning.
- Automatic document edge detection where supported; manual crop fallback.
- Perspective correction, rotation, retake, reorder, delete.
- Enhancement presets: original, color, grayscale, black-and-white.
- JPG/PNG to PDF with paper size, orientation, margins, and ordering.
- PDF viewer with zoom, page navigation, and thumbnails.
- Merge, split, rotate, and reorder PDF pages.
- PDF-to-image export.
- Compression presets and actual output-size reporting.
- OCR and text extraction for validated offline languages.
- Searchable PDF output where technically supported.
- Signature drawing and placement.
- Text/image watermark.
- Password-protected PDF creation.
- Local document library, recent files, rename, delete, favorites.
- File import, save, share, and print integration.
- Background jobs, progress, cancellation, safe temporary files, and recovery.
- Ads and one-time lifetime ad-removal purchase.
- Core workflows must work offline.

### P1 — Advanced launch features
- Hindi and English OCR/search, subject to measured language support.
- ID card/passport layouts and front/back composition.
- Receipt scanning and receipt-oriented enhancement.
- Batch conversion and batch processing.
- Permanent redaction that removes underlying content.
- Fill supported PDF form fields and checkboxes.
- Page numbers, headers, and footers.
- Local folders, tags, smart categories, and OCR-assisted naming.
- Private folder/app lock with platform-appropriate key management.
- Batch rename and bulk export.
- Print settings and convenient scan-to-share actions.

### P2 — Advanced launch features
- Table recognition and export to CSV/XLSX.
- Local PDF version comparison.
- Local document reminders/expiry reminders.
- Advanced batch workflows and configurable presets.
- Optional local Wi-Fi transfer to a desktop without cloud upload, if it can be secured and tested.
- Additional form-field detection and table extraction improvements.

P2 features may have narrower explicitly documented format support than core tools. Each must still be implemented and tested if retained in the launch commitment.

## 6. Out of scope

- Cloud document storage/sync.
- Server-side OCR or AI.
- Mandatory account/login.
- Subscription billing.
- Server collaboration or team workspaces.
- Uploading documents to WAPCentral, Firebase, analytics, or advertising providers.
- Full word-processor-style PDF editing.
- Claims of perfect OCR, universal PDF compatibility, or guaranteed compression ratios.

## 7. Product principles

- Offline-first: core local operations must not need a network.
- Privacy by design: no document content leaves the device.
- Source preservation: never overwrite originals by default.
- Honest feedback: show actual progress, output size, and errors.
- Graceful degradation: unsupported features fail clearly without corrupting source data.
- Accessible by default: readable type, screen-reader labels, contrast, and scalable text.
- Platform fit: shared UX with native capabilities where they provide real value.

## 8. Quality attributes

- Responsive UI during heavy operations.
- Bounded memory usage and controlled concurrency.
- Reliable cancellation and cleanup.
- Recoverable file writes.
- Clear error mapping and diagnostics without sensitive content.
- Testable modules and replaceable engines.
- Maintained dependency/license inventory.
- No unresolved critical or high-severity release-blocking security issue.

## 9. Monetization

Free app includes ads. One non-consumable lifetime purchase removes app-controlled ads permanently subject to store purchase/refund/revocation rules. There is no subscription. Do not paywall basic file creation, export, or access to user-owned documents.

## 10. Success metrics

Measure without collecting document content:
- Crash-free sessions and processing-job completion rates.
- Median and p95 duration for representative operations.
- Failed exports and cancellation rates.
- OCR quality on a fixed synthetic/consented test corpus.
- Store rating, uninstall rate, and user-reported defects.
- Purchase success/restoration reliability.
- Battery and memory behavior on reference devices.

Analytics must not contain filenames, OCR text, document contents, signatures, passwords, or sensitive document-derived data.

## 11. Launch gates

- All launch-scope feature acceptance criteria pass.
- PDF output integrity verified.
- Offline and network inspection tests pass.
- Commercial licenses reviewed and documented.
- Ads and lifetime purchase verified on each store.
- Accessibility and localization checks complete.
- Privacy disclosures match actual SDK behavior.
- Release signing and store compliance verified.
- No known data-loss, document-upload, or critical security defects.
