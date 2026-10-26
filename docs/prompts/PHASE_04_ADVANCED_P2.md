# Phase 04 — Advanced P1/P2 Launch Features

## Scope
Complete the approved P1/P2 launch scope, including:
- ID card/passport layouts and front/back composition.
- Receipt scanning.
- Batch conversion/processing.
- Permanent redaction.
- Supported PDF form filling.
- Headers, footers and page numbering.
- Folders, tags, smart categories and OCR-assisted naming.
- Private folder/app lock with approved key management.
- Batch rename and bulk export.
- Table extraction to CSV/XLSX.
- Local PDF comparison.
- Local reminders.
- Optional authenticated local Wi-Fi transfer.

## Required order
Implement the simpler, lower-risk workflows first. Treat redaction, private storage, table extraction and local transfer as security-sensitive gates. Do not advertise unsupported PDF types.

## Security gates
- Redaction must remove recoverable underlying content in supported cases.
- Private folder requires documented key management and recovery behavior.
- Local transfer requires threat-model review and explicit pairing/authentication.
- Spreadsheet export must handle formula-like cell values safely.

## Acceptance
Each feature has tests, documented limitations, offline verification, accessibility states, and actual output validation. Report any item that cannot safely meet the launch promise; do not silently omit it.
