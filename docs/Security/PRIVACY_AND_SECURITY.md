# Privacy and Security Requirements

## Privacy promise
Document content is processed on-device. The app must not automatically upload documents, images, OCR text, signatures, filenames, document metadata or derived content.

## Threat model
Consider:
- Accidental cloud upload from a library or analytics SDK.
- Sensitive data in logs/crash reports.
- Insecure temporary files.
- Password leakage.
- Unauthorized access to private-folder data.
- Malicious or malformed PDF/image inputs.
- Redaction that only hides content visually.
- Unsafe local network transfer.
- Incorrect purchase entitlement state.
- Dependency supply-chain or license risk.

## Required controls
- Data-flow inventory for every SDK and network path.
- No document-derived analytics parameters.
- Redact sensitive paths and content from logs.
- Use established cryptographic implementations and platform key storage.
- Avoid custom cryptography.
- Validate and bound untrusted PDF/image inputs.
- Isolate temporary processing files and clean up reliably.
- Treat imported files as untrusted.
- Review PDF engine vulnerabilities and update dependencies.
- Use least-privilege OS permissions.
- Provide clear deletion behavior.
- Keep signing keys, private service credentials and store secrets outside Git.
- Review ad SDK consent, disclosures and data collection.

## Redaction
A visual black rectangle is not sufficient. Remove or sanitize underlying text, image regions, hidden layers, metadata and relevant attachments/revisions as supported. Independently test that target content cannot be searched, copied or extracted from the result. Document residual limitations.

## Password protection
Use a vetted PDF engine and documented encryption standards. Never claim that an arbitrary password prompt encrypts a file. Do not store plaintext passwords or include them in telemetry.

## Signature
A drawn signature is an image/annotation and must not be marketed as a certificate-backed digital signature unless a separate cryptographic signature implementation is added and validated.

## Network verification
During release testing, inspect network traffic on:
- clean install,
- offline operation,
- OCR,
- export/share,
- ads enabled,
- lifetime purchase,
- WAPCentral/Firebase enabled if applicable.

Confirm that document-derived content never leaves the device. Document non-content telemetry and third-party SDK data collection accurately.

## Incident response
Define a process to disable a problematic integration, update a vulnerable dependency, communicate privacy-impacting changes, and ship a hotfix. Keep a dependency inventory and release history.
