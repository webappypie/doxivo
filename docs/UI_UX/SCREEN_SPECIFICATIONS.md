# Screen Specifications

## 1. Home
- Header with app identity, settings, and optional Pro indicator.
- Primary “Scan document” action.
- Common tools: Images to PDF, Merge, Compress, OCR/Extract Text.
- Recent documents list.
- Empty state explains how to scan/import the first document.
- Ads only in approved non-editing placements and with safe reserved layout space.

## 2. Scanner camera
- Camera preview, edge overlay, capture/auto-capture indicator.
- Flash and camera switch where supported.
- Page count and thumbnail strip for multi-page session.
- Manual shutter always available where camera path supports it.
- Permission/error fallback to import.
- No ad overlay.

## 3. Scan review
- Page grid/list, reorder, rotate, retake, crop, delete.
- Enhancement presets and before/after preview.
- Add page and continue.
- Preserve captured originals until user confirms final output.

## 4. Crop and enhancement editor
- Large preview, adjustable corners, rotation, reset.
- Filter carousel with accessible labels.
- Undo/redo where supported.
- Export preview matches final processing.

## 5. PDF viewer
- Page canvas, zoom, page navigation, thumbnail rail/sheet.
- Search only where text layer exists; offer OCR action for scanned pages.
- Overflow actions for share, print, rename, duplicate, and tools.
- Handle encrypted/unsupported files gracefully.

## 6. Tool selection
- Searchable categorized tools.
- Each tool explains what it does and supported input.
- Disabled states explain the actual reason (e.g. unsupported format), not fake Pro locks.

## 7. Merge/split/reorder
- File selection and page thumbnails.
- Drag reorder with accessible alternatives.
- Validate page ranges and display output naming.
- Clear processing state and cancellation.

## 8. Compression
- Original size and page count.
- High Quality / Balanced / Small Size options.
- Plain-language explanation of expected trade-offs.
- Show actual output size and reduction only after completion.
- Save as new file.

## 9. OCR and search
- Language selection limited to verified offline languages.
- Processing progress, cancel, retry.
- Extracted text view with copy/share/export.
- Search result includes document and page reference.
- Explain that OCR can contain errors.

## 10. Signature/watermark/redaction
- Preview-first canvas.
- Select pages/range, placement and style.
- Undo/remove before export.
- Redaction includes irreversible warning and verification step.
- Clearly label drawn signatures as visual signatures, not certificate-backed digital signatures.

## 11. Library
- Search, folders, tags, favorites, recent files.
- Sort/filter controls.
- File row shows title, type, size/date where appropriate.
- Bulk selection and actions.
- Delete confirmation explains scope.

## 12. Batch processing
- Queue, per-item status, total progress, cancel/retry.
- Failed item details and retry.
- Do not discard successful outputs when another item fails.

## 13. Table extraction
- Table preview with row/column review and correction.
- Export CSV/XLSX.
- Warn when structure is uncertain.
- Sanitize formula-like exported cell values appropriately.

## 14. PDF comparison
- Select two local files.
- Side-by-side or overlay comparison.
- Label whether comparison is visual or text-based.
- Explain limitations and avoid legal-grade claims.

## 15. Local reminders
- User-selected document/date/title.
- Local notification permission state.
- Edit/delete reminder.
- No cloud scheduling or upload.

## 16. Settings
- Theme, language, default scan settings, storage usage, privacy statement, diagnostics without document content, ad preferences/consent, lifetime purchase, restore purchase, open-source licenses, feedback and about.

## Shared states
Every screen must specify loading, empty, success, error, offline, permission-denied, unsupported-input, low-storage, cancellation and accessibility states as relevant.
