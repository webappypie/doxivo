# Phase 05 — Ads and Lifetime Purchase

## Scope
- Integrate approved ad SDK and placement policy.
- Implement consent/disclosure requirements.
- Implement one-time non-consumable ad-removal purchase.
- Handle pending, success, cancel, failure, restore and revocation/refund.
- Disable all app-controlled ads when lifetime entitlement is valid.
- Verify no document-derived data is exposed to ads/billing.

## Rules
- No subscription product.
- No ad gate before export.
- No ads during scanning, OCR, signature, password, redaction or active processing.
- Ad/billing failure must not block core document operations.
- Do not hard-code store price; use localized store product data.

## Acceptance
Test purchase flows on store test environments, including offline behavior and reinstall/restore where supported. Document all platform-specific manual steps.
