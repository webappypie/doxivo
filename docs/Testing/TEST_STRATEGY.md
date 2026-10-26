# Test Strategy

## Layers
1. Unit: domain rules, file naming, crop geometry, compression result calculations, job state transitions, entitlement logic.
2. Widget: navigation, forms, dialogs, progress, empty/error/offline states, accessibility.
3. Integration: scanner, native adapters, database, import/export, OCR, PDF engine, ads and billing.
4. Golden/visual: layout across sizes, dark mode, text scaling and localization.
5. Document integrity: independent verification of generated outputs.
6. Privacy/network: prove document-derived content does not leave device.
7. Performance/stress: large files, batch jobs, memory, CPU, battery, low storage.
8. Release: signed builds, store disclosures and purchase verification.

## Mandatory fixture categories
- One-page and multipage PDFs.
- Scanned image PDFs and digitally generated PDFs.
- Mixed page sizes/orientations.
- Large high-resolution images.
- Selectable text, links, fonts, annotations and form fields.
- Encrypted PDFs and incorrect passwords.
- Corrupt/malformed PDFs.
- Unicode filenames and mixed Hindi/English text.
- Low contrast, skew, blur and shadows.
- PDFs with metadata, hidden text, attachments, or incremental updates for redaction testing.

## Test environment
Maintain representative low-, mid-, and high-end Android devices and supported iOS devices/OS versions. Record hardware, OS, app build, file fixture, operation, elapsed time, peak memory where measurable, output size, and result.

## Regression
Every fixed bug should add a test or fixture where practical. Run critical document-integrity tests on every PDF engine/dependency update.
