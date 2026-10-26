# Ads and Lifetime Purchase Specification

## Model
- Free app with ads.
- One-time non-consumable purchase to remove app-controlled ads.
- No subscription.
- No paywall on basic document creation, user-owned files, or essential export.

## Ad placement
Allowed candidates: home and other non-editing, non-sensitive screens. Avoid camera capture, OCR review, signing, password entry, redaction, active processing, and export completion. Avoid blocking an export behind an ad. Use conservative interstitial frequency or omit interstitials if they harm UX.

## Lifetime purchase
- One-time store-managed purchase.
- Clear disclosure: removes app-controlled ads; local tools continue to work offline.
- Handle pending, success, cancellation, failure, refund/revocation, and restore.
- Persist entitlement state safely and reconcile with store APIs when online.
- Do not treat an unavailable billing service as a reason to disable document processing.
- On confirmed entitlement, hide all app-controlled ad placements.
- Respect platform store rules and current billing APIs.

## Privacy
- Do not send filenames, OCR text, document paths, signatures, or document content to ad SDKs.
- Review consent requirements and privacy labels/data safety forms.
- Test network behavior of every SDK.

## Pricing
Pricing is a product/business decision and must be validated in target markets. Do not hard-code example prices into code. Read localized price from the relevant store product configuration.

## Acceptance tests
- First launch without network remains usable for core local tools.
- Ad failure does not block the app.
- Purchase cancellation returns to app without false success.
- Successful purchase removes ads.
- Restore recovers valid entitlement where supported.
- Refund/revocation behavior follows store response.
- No subscription product or recurring billing path exists.
