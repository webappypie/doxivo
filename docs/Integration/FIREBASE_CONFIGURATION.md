# Firebase Configuration Procedure

## Principle
Firebase is not a document-processing backend and is not automatically required by this product. Integrate only the Firebase services actually required by the approved WAPCentral guide or separately approved product requirement.

## Expected configuration files
- Android file commonly placed at `android/app/google-services.json`.
- iOS file commonly placed at `ios/Runner/GoogleService-Info.plist`.

Actual locations depend on project configuration. Inspect the Gradle and Xcode project before moving or adding files.

## AI agent procedure
1. Inspect root and native project files.
2. Confirm the configuration file belongs to the exact Android application ID or iOS bundle ID.
3. Compare identifiers with the actual project configuration.
4. Move/copy only when appropriate; preserve original files until integration is verified.
5. Add required Gradle/Xcode configuration only according to current official setup and selected SDK.
6. Build both platforms and test the specific Firebase feature.
7. Confirm core document features work when Firebase/network is unavailable.
8. Update `.gitignore` and secret-handling rules appropriately.

## Security
Firebase client configuration is not equivalent to a private service-account credential. Nevertheless, do not commit private keys, service account JSON, signing credentials, private API secrets, or user-specific tokens. Keep Firebase security rules and project permissions properly configured. Never use Firebase to upload document content under this product's privacy policy.

## Required report
Document which services were enabled, why they are needed, exact configuration paths, identifiers verified (do not unnecessarily expose keys in logs), builds/tests performed, and any remaining manual steps.
