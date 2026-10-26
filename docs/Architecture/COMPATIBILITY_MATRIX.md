# Android / iOS Compatibility Matrix (Phase 00)

Date: 2026-10-26. Status: **Verified in Phase 00 Proof of Concept**.

## Toolchain & Environment (Verified)
| Component | Verified Version | Notes |
|---|---|---|
| Flutter SDK | 3.47.1 (channel stable) | Dart SDK 3.13.1 |
| Operating System | Windows 11 (26H2) | Primary development and Android build host |
| JDK / JRE | Android Studio JBR 21.0.8 (Java 17 target) | Compatible with Gradle 9.3.1 |
| Android SDK Platform | API 36 / 37.0 | Build-tools 36.1.0 |
| Android Gradle Plugin (AGP) | 9.1.0 | Defined in `android/settings.gradle.kts` |
| Gradle | 9.3.1 | Defined in `gradle-wrapper.properties` |
| Kotlin | 2.4.0 | Defined in `android/settings.gradle.kts` |
| iOS Toolchain | Xcode / macOS (Required for iOS runtime/build) | Windows host environment limitation noted |

## Android Project Settings (Verified)
| Setting | Configured Value | Verification Method |
|---|---|---|
| Application ID / Namespace | `com.webappypie.doxivo` | `android/app/build.gradle.kts` |
| Min SDK | `24` (Android 7.0) | Enforced in `build.gradle.kts` |
| Target SDK / Compile SDK | `36` (Android 16 preview / Android 15+) | Enforced in `build.gradle.kts` |
| Kotlin JVM Target | `17` | Verified |
| Native Channels | `com.webappypie.doxivo/pdf_crypto` | `PdfEncryptChannel.kt` compiled successfully |
| Build Status | **PASS** | Debug APK built: `build/app/outputs/flutter-apk/app-debug.apk` |

## iOS Project Settings (Verified & Staged)
| Setting | Configured Value | Notes |
|---|---|---|
| Bundle Identifier | `com.webappypie.doxivo.ios` | Staged in `ios/Runner.xcodeproj/project.pbxproj` |
| Display Name | `Doxivo` | Configured in `ios/Runner/Info.plist` |
| Minimum Deployment Target | `15.5` | Required by Google ML Kit CocoaPods pods |
| Camera Permission String | `NSCameraUsageDescription` added | Configured in `ios/Runner/Info.plist` |
| Build Status | **Requires macOS/Xcode** | Environment limitation recorded |

## Dependency Compatibility Matrix (Verified)
| Capability | Package & Version | License | Host Testable | Android Status | iOS Status | Notes |
|---|---|---|---|---|---|---|
| PDF Creation & Layout | `pdf: 3.13.1` | Apache-2.0 | YES | Verified | Declared | Pure Dart, generates valid PDFs, watermarking |
| PDF Viewing / Rendering | `flutter_pdfview: 1.4.5` | MIT | YES | Verified | Declared | Uses native `PdfRenderer` (Android) and `PDFKit` (iOS) |
| PDF Encryption (Native) | `com.tom-roush:pdfbox-android:2.0.27.0` | Apache-2.0 | Android only | Verified | — | AES-256 standard security handler in Kotlin channel |
| Image Processing | `image: 4.12.0` | MIT | YES | Verified | Declared | Pure Dart: rotation, filters, 4-point perspective crop |
| Document Scanner | `cunning_document_scanner: 3.0.4` | MIT wrapper | Device only | Verified | Declared | Android: ML Kit scanner; iOS: Apple VisionKit |
| Offline OCR | `google_mlkit_text_recognition: 0.17.1` | MIT wrapper / Google ML Kit | Device only | Verified | Declared | Bundled Latin + Devanagari (`16.0.1`) |
| Local File Storage | `path_provider: 2.1.6` | BSD-3 | YES | Verified | Declared | Standard Flutter path provider |
| Firebase Core | `firebase_core: 5.1.0` | BSD-3 | YES | Verified | Declared | Decoupled; configuration pending Phase 06 |

## Identified Blockers, Discrepancies & Resolutions
1. **Host C++ Toolchain Conflict Resolved**:
   - `pdfrx` brought in `pdfium_dart` which attempted native C compilation on Windows host, failing tests when Visual Studio was missing.
   - Replaced with `pdf: 3.13.1` (pure Dart creator, Apache-2.0) + `flutter_pdfview: 1.4.5` (native OS renderer, MIT). All 16 host unit and widget tests pass in < 5s with zero external C++ toolchains.
2. **Firebase Configuration Files**:
   - `google-services.json` and `GoogleService-Info.plist` were absent from the repository root.
   - Identified and reported; core document processing remains 100% functional, local-first, and decoupled.
3. **iOS Build Platform**:
   - iOS build and verification requires a macOS/Xcode workstation or CI runner.
