# Global Acceptance Criteria

A feature is not complete unless all applicable checks pass.

## Functional
- [ ] User can reach the feature from documented navigation.
- [ ] Valid inputs produce the documented output.
- [ ] Invalid inputs produce a helpful error and preserve originals.
- [ ] Loading, progress, cancellation, success, and failure states are implemented.
- [ ] Duplicate filenames and Unicode names are handled.
- [ ] Empty, large, encrypted, and corrupt inputs are tested as applicable.

## Data integrity
- [ ] Source files are unchanged unless user explicitly requests destructive action.
- [ ] Output is fully written before success is reported.
- [ ] Output can be reopened by an independent reader when applicable.
- [ ] Interrupted operations do not leave a corrupt final file.
- [ ] Temporary files are cleaned up safely.

## Privacy and security
- [ ] No document content or derived content is sent over the network.
- [ ] Logs contain no passwords, signatures, OCR text, or document content.
- [ ] Sensitive data is stored only as required and deleted according to policy.
- [ ] Security-sensitive features have independent verification tests.

## UX/accessibility
- [ ] Touch targets, contrast, screen-reader labels, and text scaling are checked.
- [ ] Permission denial has a fallback or clear explanation.
- [ ] Preview matches exported output.
- [ ] Errors explain recovery options.

## Engineering
- [ ] Formatter and static analysis pass.
- [ ] Relevant unit/widget/integration tests pass.
- [ ] Android build succeeds.
- [ ] iOS build succeeds on compatible macOS/Xcode.
- [ ] Dependency licenses and versions are documented.
- [ ] Docs and phase report are updated.
