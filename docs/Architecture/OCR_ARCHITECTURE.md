# OCR Architecture

## Goal
On-device OCR and text search with no document-content uploads.

## Design
- Define an `OcrService` interface with capability discovery.
- Normalize input images and page coordinates.
- Return recognized text, page geometry, language, status, and optional confidence.
- Store results locally only when the user chooses a workflow that needs them.
- Index text locally for search; provide deletion/re-indexing behavior.
- Generate searchable PDFs with a text layer aligned to rendered page content.
- Keep OCR engine replaceable and separate from PDF rendering.

## Language support
Hindi and English are desired launch languages. Actual support is conditional on tested offline language availability on both platforms. Do not assume identical OCR engines or accuracy on Android and iOS. The UI must list verified languages and explain any required local model setup.

## Quality evaluation
Build a representative corpus with printed and photographed text, mixed lighting, skew, blur, low contrast, tables, Hindi/English mixed text and varied fonts. Report character error rate (CER) by language and image condition. Set release thresholds after baseline measurements; do not fabricate accuracy claims.

## Privacy
- No OCR text in analytics or crash logs.
- No cloud OCR fallback.
- Do not send document-derived content to ad, billing, remote-config or notification services.
- Deleting a document must define whether its OCR index and cached text are also deleted.
