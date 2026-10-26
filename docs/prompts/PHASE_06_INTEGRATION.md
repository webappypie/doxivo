# Phase 06 — WAPCentral and Firebase Integration

## Preconditions
User has supplied the WAPCentral_App_Integration_Guide and platform configuration files if needed.

## Tasks
1. Read the guide fully and inspect existing app/native configuration.
2. Identify only the services required for this product.
3. Verify Android application ID and iOS bundle ID match supplied configuration.
4. Place configuration files in correct native locations without destroying originals.
5. Integrate documented SDK APIs behind adapters.
6. Verify notification, remote config, promotion or ad behavior only where approved.
7. Ensure no document-derived data crosses the integration boundary.
8. Test all core tools with network disabled and integration service unavailable.
9. Update docs, permissions, disclosures and troubleshooting.

## Restrictions
- Do not invent app keys, IDs, endpoints or SDK methods.
- Do not upload documents/OCR/signatures.
- Do not expose secrets or private keys in Git.
- Do not overwrite conflicting configuration without reporting it.
- Do not make Firebase a dependency for local processing.

## Acceptance
Both platforms build; documented integration works; privacy/network tests pass; core offline workflows remain functional.
