# Data Flows

## Scan-to-PDF
Camera/native scanner → local captured page → crop/enhancement pipeline → review model → local PDF engine → temporary output → validation → managed storage → local metadata → optional OS share sheet.

## Import-and-compress
OS file picker → user-selected file access → local validation → processing job → PDF engine → temporary output → validation and actual-size calculation → save-as/export.

## OCR-and-search
Local page image/PDF render → local OCR engine → OCR result → local database/index → search results with document/page reference. No network path is permitted.

## Monetization
App lifecycle → privacy/consent requirements → ad SDK without document-derived inputs. Store billing → purchase state → entitlement repository → hide app-controlled ads. Document tools do not depend on a successful ad request or billing network.

## WAPCentral/Firebase
Only integrate services specified in the supplied guide and approved scope. Notifications, remote configuration or promotions may use network access if required, but document content must remain outside those data flows. Core document processing must remain usable if these services are unavailable.

## Required review
For each flow, document data touched, persistence, deletion behavior, network possibility, failure behavior, and tests. Run network inspection to confirm the design matches implementation.
