# Phase 00 Architecture Decision Records

Date: 2026-10-26. Status of ADRs: **Validated for Phase 00 Gate**.
All decisions below are supported by real implementations, passing unit and widget tests, independent Python PDF verification, and clean Android debug compilation.

---
## ADR-0001: PDF Engine and Platform Viewing / Encryption Architecture

**Context.** Needs: Create PDFs from images, multi-page assembly, margin and orientation handling, watermarking, viewing/rendering, password-protection/encryption, text extraction, local offline execution, Android + iOS support, permissive commercial-friendly licensing.

**Evaluated Candidates.**
| Candidate | License | Feature Coverage | Verification / Findings |
|---|---|---|---|
| **`pdf` 3.13.1** (Pure Dart) | Apache-2.0 | PDF creation from scratch, multi-page layout, image embedding, watermarks, vector drawing | **Verified in Phase 00**: Tested and generated single-page, multi-page, and watermarked PDFs. Verified 100% valid by independent Python parser (`tool/verify_pdfs.py`). 0 external binary dependencies; runs unit tests on host without C compiler. |
| **`flutter_pdfview` 1.4.5** | MIT | Native PDF rendering / viewing | **Verified in Phase 00**: Uses native OS PDF rendering (`android.graphics.pdf.PdfRenderer` on Android API 21+, `PDFKit` on iOS). Avoids host C++ compiler issues on development machines. |
| **`pdfrx` 2.10.1** (PDFium) | MIT / BSD-3 (PDFium) | PDF viewing, text selection, page manipulation | **Evaluated & Tested**: Uses `pdfium_dart` native assets hook, which requires MSVC C++ compiler on Windows host and fails host `flutter test` when Visual Studio is not installed. Preserved as an option if in-place vector editing is required in Phase 02. |
| **`pdfbox-android` 2.0.27.0** (`com.tom-roush`) | Apache-2.0 | Standard PDF security handler encryption (AES-256 / 128-bit) | **Verified in Phase 00**: Implemented in `PdfEncryptChannel.kt` via MethodChannel `com.webappypie.doxivo/pdf_crypto`. Compiles cleanly into Android debug APK. |
| **Apple PDFKit** | Apple Platform API | Viewing, page manipulation, password protection (`PDFDocumentWriteOption`) | Built into iOS (iOS 11+). Requires macOS/Xcode for runtime execution. |

**Decision.**
1. Use **`pdf: 3.13.1`** (Apache-2.0) as the primary PDF creation, page assembly, and watermarking engine.
2. Use **`flutter_pdfview: 1.4.5`** (MIT) backed by native OS engines (`PdfRenderer` on Android, `PDFKit` on iOS) for high-performance offline document rendering.
3. Use a platform-channel adapter for standard PDF password protection (PDFBox-Android on Android; PDFKit on iOS) to avoid custom cryptography.

**Evidence.**
- All unit tests in `test/unit/pdf_engine_test.dart` and `test/unit/generate_poc_artifacts_test.dart` passed (`flutter test`).
- Output files `single_page.pdf`, `watermarked.pdf`, and `multipage.pdf` validated by `python tool/verify_pdfs.py build/poc_output`.
- Kotlin `PdfEncryptChannel.kt` compiled successfully in `:app:compileDebugKotlin` and packaged into `build/app/outputs/flutter-apk/app-debug.apk`.

---
## ADR-0002: Android Scanner Implementation

**Context.** Needs document boundary detection, auto-crop, perspective correction, enhancement filters, multi-page scanning, and offline resilience.

**Evaluated Candidates.**
1. **Google Play Services Document Scanner** (`cunning_document_scanner: 3.0.4`, native `play-services-mlkit-document-scanner:16.0.0`):
   - High-quality boundary detection, automatic perspective correction, and system UI.
   - Offline consideration: On clean devices, Play Services may trigger an initial dynamic download of the scanner UI/model.
2. **Pure Dart / In-App Fallback** (`ImageProcessingPipeline`):
   - Implemented in `lib/poc/image_pipeline.dart`.
   - Provides 4-point bilinear perspective rectification (`perspectiveCrop`) and document enhancement filters (Grayscale, Black & White binarization, Enhanced Color).
   - Works 100% offline on any Android device, custom ROMs, or devices without Google Play Services.

**Decision.**
Adopt a hybrid approach:
- Launch Google Play Services Document Scanner where Google Play Services are available.
- Provide a guaranteed camera capture + manual 4-point perspective crop fallback using `ImageProcessingPipeline.perspectiveCrop` for non-GMS devices or offline first-use scenarios.

**Evidence.**
- `ImageProcessingPipeline` tested in `test/unit/image_pipeline_test.dart` (6 tests passed).
- `ScannerService.scanDocuments` integrated and tested for error handling and cancellation.

---
## ADR-0003: iOS Scanner Implementation

**Context.** Needs native document capture, edge detection, and multi-page scanning on iOS.

**Decision.**
- Use Apple VisionKit `VNDocumentCameraViewController` via `cunning_document_scanner: 3.0.4`.
- Apple framework, native, 100% on-device, zero runtime downloads required.
- Configured `NSCameraUsageDescription` in `ios/Runner/Info.plist`.
- Shared `ImageProcessingPipeline` fallback for gallery import and manual perspective crop.

---
## ADR-0004: Offline OCR Engine and Language Architecture

**Context.** Needs on-device, offline OCR for English and Hindi (Devanagari script) with zero document-content uploads.

**Evaluated Candidates.**
1. **Google ML Kit Text Recognition** (`google_mlkit_text_recognition: 0.17.1`):
   - Latin script model (`com.google.mlkit:text-recognition:16.0.1`).
   - Devanagari script model (`com.google.mlkit:text-recognition-devanagari:16.0.1`).
   - Bundled dependency: When declared in `android/app/build.gradle.kts`, the Devanagari model is bundled directly inside the APK, requiring **zero runtime network downloads**.
   - Input/output stays 100% on-device.
2. **Tesseract OCR** (`flutter_tesseract_ocr`):
   - Requires heavy traineddata assets (`eng.traineddata`, `hin.traineddata`), slower execution on mobile CPUs. Deferred for consideration if ML Kit cannot be used in specific non-GMS markets.

**Decision.**
- Use Google ML Kit with bundled Latin and Devanagari models for Android and iOS.
- Measure Character Error Rate (CER) using Levenshtein distance metric ($CER = (S+D+I)/N$).
- Standardize on synthetic and scanned test fixtures in `test/fixtures/ocr/` with verified ground truth.

**Evidence.**
- Added `com.google.mlkit:text-recognition-devanagari:16.0.1` to `build.gradle.kts` (compiled and packaged in debug APK).
- Implemented `TextMetrics` CER calculator in `lib/poc/text_metrics.dart` and verified with English and Hindi runes in `test/unit/text_metrics_test.dart`.
- Generated synthetic fixture images `english_sample.png` and `hindi_sample.png` using Arial and Nirmala fonts.

---
## ADR-0005: State Management and Dependency Injection

**Decision.**
- Use `flutter_riverpod` (MIT) with narrow service interfaces (`PdfEngineService`, `ScannerService`, `OcrService`, `ImageProcessingService`) for testability and mock injection. Low overhead, compile-time safety.

---
## ADR-0006: Local Database and Search Indexing

**Decision.**
- Use `drift` (MIT) over SQLite for structured document metadata, categories, and FTS5 full-text search indexing of recognized OCR text.
- 100% local database storage in the app's sandboxed document directory (`path_provider`).

---
## ADR-0011: Minimum Android and iOS Versions

**Decision.**
- **Android**: `minSdk = 24` (Android 7.0 Nougat), `targetSdk = 36`, `compileSdk = 36`.
  - Justification: Required by `cunning_document_scanner` and compatible with ML Kit (requires minSdk ≥ 21).
- **iOS**: `minimum deployment target = 15.5`.
  - Justification: Required by Google ML Kit CocoaPods pods. Configured in `ios/Runner.xcodeproj/project.pbxproj`.
