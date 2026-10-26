# PDF and Image Test Corpus

Create synthetic or properly licensed test documents. Do not use private user documents.

## Corpus groups
- Basic: one-page text PDF, multipage PDF, blank page, rotated page.
- Image-heavy: photo scans, high-resolution images, mixed image sizes.
- Digital: selectable text, embedded fonts, vector shapes, hyperlinks.
- Advanced: annotations, forms, metadata, attachments, encrypted files.
- Invalid: truncated file, malformed object table, unsupported encryption.
- International: Unicode filenames, Hindi/English mixed text, non-Latin text if supported.
- OCR quality: skew, blur, shadows, low contrast, varied fonts and table layouts.
- Redaction: unique canary strings in visible text, hidden text layers, metadata, attachments where supported.
- Scale: increasing page counts and file sizes within realistic device limits.

## Expected outputs
For each fixture, record checksum, origin/license, expected page count, orientation, known text, supported operations and expected limitations.

## Integrity checks
- Reopen generated files independently.
- Verify page count/order/orientation.
- Check text extraction where applicable.
- Compare rendered output against expected visual tolerances.
- Verify encrypted output rejects incorrect passwords.
- Verify redacted canary strings cannot be searched or extracted from supported cases.
- Ensure failed operations leave no misleading final file.
