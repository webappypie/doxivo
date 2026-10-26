# PDF Engine Selection — Phase 00 Decision Gate

## Status
**Not yet selected.** Do not allow the coding agent to make an unreviewed final selection.

## Required capabilities

Evaluate each candidate for:
- Render/view PDFs and thumbnails.
- Create PDFs from images.
- Merge, split, rotate, reorder.
- Compression/optimization.
- Extract text and metadata.
- Annotations, signature placement and watermarks.
- Password encryption and opening encrypted files.
- Forms, redaction, comparison, table workflows where applicable.
- Android and iOS support, including supported OS versions.
- Large-file behavior and memory footprint.
- Commercial licensing and redistribution obligations.
- Offline behavior and any native/runtime downloads.
- Accessibility, stability, maintenance, and testability.

## Evaluation process

1. Create a small proof-of-concept app for Android and iOS.
2. Evaluate at least two plausible candidates if practical.
3. Test the same fixed corpus and operations for each.
4. Independently reopen generated output.
5. Benchmark representative small, medium and large files.
6. Review license text and any copyleft/commercial obligations.
7. Document unsupported formats and feature limitations.
8. Record final selection in an ADR.

## Decision matrix

Score each category 1–5 and weight security/licensing, correctness, platform coverage, and offline behavior heavily.

| Category | Weight |
|---|---:|
| Correctness and output integrity | 25% |
| Required feature coverage | 20% |
| Android/iOS support | 15% |
| License and commercial distribution | 15% |
| Performance/memory | 10% |
| Offline operation | 10% |
| Maintenance and testability | 5% |

A candidate with an unacceptable license or unverified security behavior is disqualified regardless of score.

## Security-specific rules

- Do not implement PDF encryption with custom cryptography.
- Do not call visual covering “redaction.”
- Do not assume a PDF library can preserve every annotation/form/embedded object.
- Do not claim password protection until an independent reader confirms the result.
- Do not rasterize every page to simplify implementation without explicitly evaluating text, vector, accessibility, size, and quality consequences.
