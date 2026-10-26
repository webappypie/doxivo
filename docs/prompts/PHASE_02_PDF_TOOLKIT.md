# Phase 02 — Core PDF Toolkit

## Preconditions
Phase 01 passes acceptance.

## Tasks
Implement:
- PDF import/view and thumbnails.
- Merge, split, rotate and reorder.
- Images to PDF and PDF pages to images.
- Compression presets with actual size reporting.
- Signature drawing/placement.
- Text/image watermark.
- Password-protected PDF creation.
- Processing queue, progress, cancellation and cleanup.
- Save-as, collision handling and output validation.

## Requirements
Use the approved PdfEngine abstraction. Preserve originals by default. Do not implement custom cryptography. Clearly report unsupported annotations/forms/encryption. Keep heavy work off the UI thread and bound memory.

## Tests
Use PDF_TEST_CORPUS.md. Reopen outputs independently. Verify page count/order/orientation, password behavior, compression reporting and cancellation.

## Acceptance
All P0 PDF features pass the documented fixtures on both platforms. No fake success path. Update feature specs and dependency inventory.
