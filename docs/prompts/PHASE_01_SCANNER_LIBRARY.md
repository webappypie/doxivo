# Phase 01 — Scanner and Local Library

## Preconditions
Phase 00 approved. PDF/scanner dependencies and licenses documented.

## Tasks
- Implement app shell, navigation, design tokens and shared components.
- Implement scanner adapters behind ScannerService.
- Implement capture, manual crop, perspective correction, rotate, retake and multi-page review.
- Implement enhancement presets and source preservation.
- Create PDF from captured pages.
- Implement local document metadata repository and managed file storage.
- Implement import, rename, delete, favorites, recents, share and print paths.
- Implement basic PDF viewer and thumbnails.
- Implement permission-denied and import fallback flows.
- Add unit, widget, integration and real-device tests.

## Acceptance
- Complete scan-to-save-to-share flow works on Android and iOS.
- Output opens independently and page order matches review order.
- Airplane-mode workflow passes under documented setup conditions.
- UI remains responsive during processing.
- Source files are preserved and temporary files cleaned.
- Accessibility and dark mode reviewed.

## Stop conditions
Do not proceed if scanner requires unverified cloud processing, if output integrity fails, or if a critical platform gap is unresolved.
