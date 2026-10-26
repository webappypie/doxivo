# Phase 03 — OCR and Search

## Preconditions
Phase 00 has approved offline OCR engine/language support. Phase 01 and relevant Phase 02 workflows pass.

## Tasks
- Implement OcrService with capability/language discovery.
- Run OCR locally on images and supported PDF pages.
- Show extracted text, copy/export, and meaningful failure states.
- Generate searchable PDFs with aligned text layers where supported.
- Build local filename and OCR text search.
- Add Hindi/English support only if verified on each platform.
- Implement index deletion and re-indexing.
- Add OCR corpus tests and report CER by language/condition.

## Privacy
No cloud OCR fallback. No OCR text in logs, analytics, crash reports or ad/billing integrations.

## Acceptance
Offline recognition works under documented setup. Search results map to correct document/page. Quality meets thresholds agreed from baseline. Unsupported language/model states are clear.
