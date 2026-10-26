# Release Checklist

## Product
- [ ] All approved P0/P1/P2 launch features implemented or formally dispositioned.
- [ ] User journeys and acceptance criteria pass.
- [ ] Known limitations documented in-app or in support material where relevant.

## Engineering
- [ ] Flutter analysis and tests pass.
- [ ] Android build succeeds on clean environment.
- [ ] iOS build succeeds on compatible macOS/Xcode.
- [ ] No debug-only shortcuts, fake outputs, or disabled tests.
- [ ] Dependency lockfile committed.
- [ ] License inventory and notices complete.
- [ ] Crash recovery and low-storage cases tested.

## Privacy/security
- [ ] Network inspection confirms no document-content upload.
- [ ] SDK data collection reviewed.
- [ ] Privacy policy and store disclosures match behavior.
- [ ] Passwords/signatures/OCR text excluded from logs.
- [ ] Redaction and encryption tests independently verified.
- [ ] No private secrets or signing keys in Git.
- [ ] Threat model reviewed and release blockers closed.

## Monetization
- [ ] Ad placements follow policy.
- [ ] Consent flow tested where required.
- [ ] Lifetime purchase works.
- [ ] Restore and revocation behavior tested.
- [ ] No subscription products or recurring billing.
- [ ] Core offline features unaffected by ad/billing failures.

## Store readiness
- [ ] Final app name, IDs, icons, screenshots and descriptions.
- [ ] Android signing and iOS signing/provisioning secured.
- [ ] Store privacy/data-safety forms complete.
- [ ] Permissions justified.
- [ ] Support/privacy URLs available if required.
- [ ] Accessibility and localization review complete.
- [ ] Internal/beta testing and staged rollout plan approved.

## Final go/no-go
No release with unresolved data loss, document upload, critical/high security, invalid encryption/redaction, or broken purchase entitlement issues.
