# Quick Start

## Before coding

- [ ] Confirm the final app name, Android application ID, and iOS bundle identifier.
- [ ] Review all docs in `docs/PRD/`, `docs/Architecture/`, and `docs/Security/`.
- [ ] Create a Git repository and `.gitignore`.
- [ ] Confirm minimum Android/iOS versions based on chosen dependencies.
- [ ] Obtain and review the WAPCentral integration guide, if integration is required.
- [ ] Download Firebase platform configuration files only if the selected Firebase features need them.
- [ ] Keep private credentials and signing material out of source control.

## Toolchain checks

```bash
flutter doctor
flutter --version
dart --version
```

After the Flutter project has been created or inspected:

```bash
flutter pub get
flutter analyze
flutter test
```

Use a real Android device/emulator for Android testing. Use a real iPhone/simulator and compatible macOS/Xcode setup for iOS testing.

## Phase order

1. Phase 00 — foundation and proof of concept.
2. Phase 01 — scanner and local library.
3. Phase 02 — PDF toolkit.
4. Phase 03 — OCR and search.
5. Phase 04 — advanced P1/P2 features.
6. Phase 05 — ads and lifetime purchase.
7. Phase 06 — WAPCentral/Firebase integration, only where required.
8. Phase 07 — hardening and release.

Phases may overlap only after dependencies are documented and interfaces are stable. Do not skip Phase 00.

## Firebase configuration

Expected common locations (verify actual project configuration before moving files):
- Android: `android/app/google-services.json`
- iOS: commonly `ios/Runner/GoogleService-Info.plist`

These files do not automatically enable Firebase features. Verify app identifiers, native build configuration, required services, and runtime behavior. Do not assume Firebase is needed for core document processing.

## Ready-to-start criteria

Do not start Phase 01 until the team has selected or approved:
- scanner approach for each platform,
- PDF engine and license,
- OCR approach and supported offline languages,
- minimum OS versions,
- local data and file-storage design,
- baseline performance devices and fixtures.
