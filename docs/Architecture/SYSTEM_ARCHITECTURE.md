# System Architecture

## 1. Principles

- Feature-first modular structure.
- UI separated from application/domain logic.
- Repository interfaces isolate local data access.
- PDF/OCR/scanner engines behind replaceable interfaces.
- Platform-specific code behind adapters.
- No document backend.
- Heavy work is asynchronous, cancellable where feasible, and memory-bounded.
- Dependencies are selected through Phase 00 evidence, not guesswork.

## 2. Logical layers

### Presentation
Flutter screens, widgets, navigation, state management, themes, accessibility and view models/controllers.

### Application
Use cases, validation, job orchestration, export workflow, entitlement decisions and error mapping.

### Domain
Document/page models, operation contracts, job states, repository interfaces, supported-format rules and business invariants.

### Data and processing
SQLite repositories, local filesystem, PDF engine adapter, image pipeline, OCR adapter, search index, preferences and temporary-file manager.

### Platform adapters
Android Kotlin and iOS Swift adapters for camera/scanning, permissions, file pickers, share sheets, printing, native OCR where chosen, notifications, billing and ad SDKs.

## 3. Suggested interfaces

- `ScannerService`: initialize, capture, review, cancel, capability reporting.
- `ImageProcessingService`: crop, perspective correction, rotate, enhance, export.
- `PdfEngine`: inspect, render, create, merge, split, rotate, compress, annotate, encrypt, extract text, forms, redact and compare—only for capabilities proven by the chosen engine.
- `OcrService`: supported languages, recognize page, return text and geometry, report model availability.
- `DocumentRepository`: create/update/list/delete metadata and relationships.
- `FileStorageService`: import, copy, write temporary output, commit, export, delete and cleanup.
- `JobManager`: enqueue, progress, cancel, retry and recover.
- `EntitlementService`: current lifetime entitlement, purchase, restore and revocation/error states.
- `AdsService`: initialize, consent state, placement visibility and disablement after lifetime purchase.

Keep interfaces narrow and avoid one giant service class.

## 4. Job lifecycle

1. Validate source, permissions, available space and supported capabilities.
2. Create a unique job ID and isolated temporary workspace.
3. Execute work away from the UI thread, using isolates or native worker mechanisms as appropriate.
4. Report progress and safe cancellation checkpoints.
5. Validate output, including reopening/inspection where applicable.
6. Commit output atomically where platform/filesystem semantics allow.
7. Update metadata transactionally.
8. Clean temporary files and release native resources.
9. Record a non-sensitive result/error code.

## 5. Error model

Use typed, user-safe errors: unsupported format, corrupt input, wrong password, missing OCR language, permission denied, insufficient storage, cancelled, output unavailable, engine failure, and unexpected internal error. Do not show raw stack traces or sensitive paths in normal UI.

## 6. State management and dependency injection

Choose one maintained state-management approach during Phase 00 and use it consistently. Inject interfaces so unit tests can replace scanner, PDF engine, OCR, storage, billing, and ads. Do not couple UI widgets directly to concrete native SDK classes.

## 7. Native integration

Use Flutter plugins or platform channels where appropriate. Native calls must be asynchronous and have explicit error mapping. Validate lifecycle behavior when app backgrounds, camera permission changes, or OS interrupts processing.

## 8. Security boundaries

- PDF/image processing is local.
- Ad/billing/remote-config modules receive no document-derived data.
- Analytics, if used, records only privacy-reviewed aggregate events.
- No document path, OCR text, signature or password is attached to crash reports.
- Network inspection is part of release testing.

## 9. Dependency policy

For each dependency record name, version, license, maintenance status, platform support, offline behavior, known limitations, and replacement plan. Pin versions through the lockfile. Avoid abandoned packages and unreviewed native binaries.

## 10. Architecture decision records

Create ADRs for PDF engine, scanner approach, OCR engines/languages, database, state management, file encryption, billing/ads SDKs, and minimum OS versions. Include alternatives, evidence, consequences, and date.
