# WAPCentral Integration Guide — Doxivo

> **Application:** Doxivo  
> **Document Version:** 2.0 • WAPCentral 1.0  
> **Generated:** 25 Oct 2026  
> **Source of Truth:** WAPCentral Central Control Plane & Firebase Console  

---

## Application Identity & Metadata

| Field | Configuration Value | Security & Source |
| :--- | :--- | :--- |
| **Application Name** | `Doxivo` | WAPCentral Application Registry |
| **WAPCentral App ID** | `app_1792970450704` | Unique WAP Platform Identifier |
| **X-App-Key** | `wap_key_f03e1b83a399557027d2f968c4f559fa88052290` | Platform API Auth (`X-App-Key`) |
| **Android Package ID** | `com.webappypie.doxivo` | Android Manifest `package` |
| **iOS Bundle ID** | `com.webappypie.doxivo.ios` | iOS `CFBundleIdentifier` |
| **Firebase Project ID** | `doxivo` | Firebase Console (`projectId`) |
| **Firebase Android App ID** | `1:789463269094:android:4716506cc7a943ecdfc527` | `google-services.json` (`mobilesdk_app_id`) |
| **Firebase iOS App ID** | `1:789463269094:ios:d22a620f2c330a6bdfc527` | `GoogleService-Info.plist` (`GOOGLE_APP_ID`) |
| **Firebase Project Number / FCM Sender ID** | `789463269094` | Cloud Messaging Sender ID |
| **Enabled WAP Services** | `Ads, Notifications, Promotion` | Centrally Authorized Modules |
| **Ads Status** | `Enabled (Testing)` | WAPCentral Monetization Engine |
| **Service Status** | `Active (Online)` | Remote App Service Control |
| **Notifications Status** | `Enabled (FCM required)` | WAPCentral FCM Dispatch Engine |

---

## 1. Purpose

This document is the official, app-specific implementation guide for **Doxivo**. It is generated dynamically from the application's central registration in **WAPCentral** to eliminate manual configuration drift, guesswork, and security misconfigurations.

### Key Architecture Principles:
- **Local-First Architecture:** The mobile app retains full local functionality even if network connectivity is disrupted or WAPCentral is temporarily unreachable.
- **Central Control Plane:** WAPCentral serves as the single source of truth for platform service access, feature flags, Ads mediation, and Push Notification campaigns.
- **Lightweight Modular SDKs:** The application includes only the WAP client SDKs and provider adapters required for its active features.

---

## 2. App Configuration & Secure Credential Handling

| Parameter | Value | Description |
| :--- | :--- | :--- |
| **App Name** | `Doxivo` | Display name of the application |
| **WAPCentral App ID** | `app_1792970450704` | Public application identifier passed in `X-App-Id` |
| **X-App-Key** | `wap_key_f03e1b83a399557027d2f968c4f559fa88052290` | Secret application key passed in `X-App-Key` |
| **Android Package ID** | `com.webappypie.doxivo` | Unique Android application ID |
| **iOS Bundle ID** | `com.webappypie.doxivo.ios` | Unique Apple bundle identifier |
| **Firebase Project ID** | `doxivo` | Target Firebase infrastructure project |
| **Firebase Android App ID** | `1:789463269094:android:4716506cc7a943ecdfc527` | Mobile app client registration ID |
| **Firebase iOS App ID** | `1:789463269094:ios:d22a620f2c330a6bdfc527` | iOS mobile app client registration ID |
| **FCM Sender ID** | `789463269094` | Authorized FCM project number |
| **Enabled WAP Services** | `Ads, Notifications, Promotion` | Active backend API modules |

### 🔒 Secure Credential-Handling Rules:
1. **Never Hardcode Secrets in Source Code:** Do not embed raw production API keys or service keys in Git repositories. Use `--dart-define` or Flutter secure storage.
2. **Direct Authentication Provisioning:** The complete, unmasked `X-App-Key` for Doxivo is provided unmasked in this guide (`wap_key_f03e1b83a399557027d2f968c4f559fa88052290`). The AI development team can implement WAPCentral authentication directly without manual lookups or key replacements. If the key needs rotation, regenerate it anytime in **WAPCentral Dashboard → Applications → Doxivo → Application Credentials**.
3. **Redact from Client Logs:** Ensure your HTTP logging interceptors automatically mask `X-App-Key` and authorization headers.
4. **No Third-Party Secrets:** Never include AI provider keys (OpenAI, Gemini, Anthropic) or FCM server service-account JSON inside the mobile app. All third-party access is mediated securely through WAPCentral backend services.

---

## 3. Firebase Configuration Files

Download the official configuration files directly from the Firebase Console for project `doxivo`:

- **Android:** `google-services.json` → place at `android/app/google-services.json`
- **iOS:** `GoogleService-Info.plist` → place at `ios/Runner/GoogleService-Info.plist`

> [!WARNING]
> Firebase configuration files belong exclusively in your client project root. Never commit cloud service account private keys (`service-account.json`), database admin credentials, or backend signing keys into the mobile application repository.

---

## 4. Firebase Services

| Service | Status for Doxivo | Integration Rule |
| :--- | :--- | :--- |
| **Firebase Cloud Messaging (FCM)** | `Required (Enabled for this application)` | Required when WAPCentral Notifications are enabled |
| **Firebase Crashlytics** | `Recommended for production crash monitoring` | Recommended for real-time production crash reporting |
| **Firebase Analytics** | `Optional / Product-dependent` | Optional / Product-dependent |
| **Firebase Authentication** | `Optional / Product-dependent` | Optional / Product-dependent (only if user login required) |
| **Cloud Firestore** | `Not required by WAPCentral` | Use only if the client application itself requires cloud persistence |
| **Cloud Storage** | `Optional / Product-dependent` | Optional / Product-dependent (only if app stores user files in cloud) |

---

## 5. Enabled WAP SDKs & Dependencies

Only add the WAP SDKs enabled for **Doxivo** to your `pubspec.yaml`. Do not bundle unused SDKs.

| SDK Package | Purpose | Status for Doxivo |
| :--- | :--- | :--- |
| `wap_core_sdk` | WAPCentral connection, auth headers, request retry, error handling | `✓ Required (Core WAP runtime & auth)` |
| `wap_ads_sdk` | Central Ads configuration, AppLovin MAX mediation, house ads fallback | `✓ Required (Enabled for Doxivo)` |
| `wap_notifications_sdk` | FCM device token registration, notification feed, read synchronization | `✓ Required (Enabled for Doxivo)` |
| `wap_promo_sdk` | Cross-promotional campaign surfaces, interstitials, banners | `✓ Required (Enabled for Doxivo)` |

---

## 6. WAPCentral Connection & Initialization

The unified core client connects to the production WAPCentral API gateway:
- **Production Base URL:** `https://wapcentral.webappypie.com/api/platform/v1`

### Initialization Snippet (`lib/main.dart`):

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wap_core_sdk/wap_core_sdk.dart';
import 'package:wap_ads_sdk/wap_ads.dart';
import 'package:wap_notifications_sdk/wap_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  await Firebase.initializeApp();

  // 2. Initialize WAPCentral Core Client
  await WapCore.initialize(
    baseUrl: 'https://wapcentral.webappypie.com/api/platform/v1',
    appId: 'app_1792970450704',
    appKey: const String.fromEnvironment('WAP_APP_KEY', defaultValue: 'wap_key_f03e1b83a399557027d2f968c4f559fa88052290'),
    preferLocal: true,
  );

  // 3. Remote App Service Control Check
  final serviceStatus = await ServiceControlGuard.checkServiceStatus();
  if (!serviceStatus.enabled) {
    // Blocks user interaction if service is disabled
    ServiceControlGuard.showBlockingDialog(navigatorKey.currentContext!, serviceStatus);
    return;
  }

  // 4. Initialize Ads (Google AdMob Direct GMA)
  await WapAds.initialize(
    const WapAdsOptions(
      appId: 'app_1792970450704',
      appKey: String.fromEnvironment('WAP_APP_KEY', defaultValue: 'wap_key_f03e1b83a399557027d2f968c4f559fa88052290'),
      environment: 'development',
      baseUrl: 'https://wapcentral.webappypie.com',
      testMode: true,
    ),
  );

  // 5. Initialize Notifications & Register FCM Token
  await WapNotifications.initialize(
    const WapNotificationsOptions(
      appId: 'app_1792970450704',
      appKey: String.fromEnvironment('WAP_APP_KEY', defaultValue: 'wap_key_f03e1b83a399557027d2f968c4f559fa88052290'),
      baseUrl: 'https://wapcentral.webappypie.com',
    ),
  );

  runApp(const MyApp());
}
```

Every platform request automatically attaches headers:
- `X-App-Id: app_1792970450704`
- `X-App-Key: wap_key_f03e1b83a399557027d2f968c4f559fa88052290`

---

## 7. Platform API Catalog & Permissions

The following table lists the WAPCentral Platform API endpoints and whether **Doxivo** is authorized to access them:

| Service | Method | Route | Permission Status for this App |
| :--- | :---: | :--- | :--- |
| **Health** | `GET` | `/api/platform/v1/health` | `Public (Available)` |
| **Service Control** | `GET` | `/api/platform/v1/apps/{appId}/service-status` | `Public / Authenticated (Active)` |
| **AI** | `POST` | `/api/platform/v1/ai/generate` | `ai — Not enabled for this app` |
| **AI** | `POST` | `/api/platform/v1/ai/vision` | `ai — Not enabled for this app` |
| **AI** | `POST` | `/api/platform/v1/ai/classify` | `ai — Not enabled for this app` |
| **AI** | `POST` | `/api/platform/v1/ai/summarize` | `ai — Not enabled for this app` |
| **AI** | `POST` | `/api/platform/v1/ai/translate` | `ai — Not enabled for this app` |
| **AI** | `POST` | `/api/platform/v1/ai/extract` | `ai — Not enabled for this app` |
| **Image** | `POST` | `/api/platform/v1/image/enhance` | `image — Not enabled for this app` |
| **Image** | `POST` | `/api/platform/v1/image/analyze` | `image — Not enabled for this app` |
| **OCR** | `POST` | `/api/platform/v1/ocr/extract` | `ocr — Not enabled for this app` |
| **Files** | `POST` | `/api/platform/v1/files/search` | `files — Not enabled for this app` |
| **Files** | `POST` | `/api/platform/v1/files/classify` | `files — Not enabled for this app` |
| **Ads** | `GET` | `/api/platform/v1/ads/config` | `ads — Enabled` |
| **Ads** | `POST` | `/api/platform/v1/ads/custom/track` | `ads — Enabled` |
| **Notifications** | `POST` | `/api/platform/v1/notifications/devices/register` | `notifications — Enabled` |
| **Notifications** | `GET` | `/api/platform/v1/notifications` | `notifications — Enabled` |

---

## 8. Ads — Controlled by WAPCentral
This app uses **Google AdMob as the sole advertising provider**. WAPCentral centrally controls Ads Enabled/Disabled, Testing/Production mode, enabled formats, and production ad units for this app. Third-party mediation platforms (such as AppLovin MAX) and external house promotions are disabled and are **NOT required** for this app.
### Configuration Summary for Doxivo:
- **Ads Status:** `Enabled`
- **Environment:** `Testing`
- **Active Demand Sources for Doxivo:** Google AdMob (Direct GMA)
- **Active Supported Formats:** Banner, Native, Interstitial, Rewarded, App Open
### Master Advertising Provider & Demand Source Roster:
The following table audits all advertising providers explicitly enabled for this application:
| Provider / Demand Source | Role & Architecture | Integration Status | Required Mobile SDK / Adapter | Supported Formats | Configuration Keys |
| :--- | :--- | :---: | :--- | :--- | :--- |
| **Google AdMob** | Direct Advertising Provider | `Configured & Verified` | `google_mobile_ads: ^5.2.0`<br>(Android: `com.google.android.gms:play-services-ads:23.6.0`) | Banner, Native, Interstitial, Rewarded, App Open, Rewarded Interstitial | Google Mobile Ads App ID (`APPLICATION_ID`), Ad Unit IDs |
### Single Provider Direct Integration (Google AdMob):
- **Direct GMA Integration:** Mobile client connects directly to Google Mobile Ads (GMA) or through `wap_ads_sdk` in AdMob-direct mode.
- **Zero Mediation Overhead:** Bypasses third-party auction latency and external mediation SDKs.
- **No AppLovin Credentials Required:** Do not configure AppLovin SDK keys or declare AppLovin metadata in native manifests.
- **Google Mobile Ads App ID:** Declared in `AndroidManifest.xml` and `Info.plist`.
### Official Testing Configuration Catalog:
Use the official testing methods and verified sample identifiers below during integration. Never use or click live production ads during development.
| Provider | Format | Testing Method / Test Identifier | Testing Status | Official Documentation |
| :--- | :--- | :--- | :---: | :--- |
| **Google AdMob** | App ID (Android Test) | `ca-app-pub-3940256099942544~3347511713` | `Configured` | [AdMob Test Ads](https://developers.google.com/admob/android/test-ads#sample_ad_units) |
| **Google AdMob** | Banner (adaptive) | `ca-app-pub-3940256099942544/9214589741` | `Configured` | [AdMob Test Ads](https://developers.google.com/admob/android/test-ads#sample_ad_units) |
| **Google AdMob** | Banner (fixed) | `ca-app-pub-3940256099942544/6300978111` | `Configured` | [AdMob Test Ads](https://developers.google.com/admob/android/test-ads#sample_ad_units) |
| **Google AdMob** | Native | `ca-app-pub-3940256099942544/2247696110` | `Configured` | [AdMob Test Ads](https://developers.google.com/admob/android/test-ads#sample_ad_units) |
| **Google AdMob** | Interstitial | `ca-app-pub-3940256099942544/1033173712` | `Configured` | [AdMob Test Ads](https://developers.google.com/admob/android/test-ads#sample_ad_units) |
| **Google AdMob** | Rewarded | `ca-app-pub-3940256099942544/5224354917` | `Configured` | [AdMob Test Ads](https://developers.google.com/admob/android/test-ads#sample_ad_units) |
| **Google AdMob** | App Open | `ca-app-pub-3940256099942544/9257395921` | `Configured` | [AdMob Test Ads](https://developers.google.com/admob/android/test-ads#sample_ad_units) |
| **Google AdMob** | Rewarded Interstitial | `ca-app-pub-3940256099942544/5354046379` | `Configured` | [AdMob Test Ads](https://developers.google.com/admob/android/test-ads#sample_ad_units) |
### App-Specific Production Identifiers for Doxivo:
| Demand Source | Ad Format / Parameter | Configured Value for Doxivo | Integration & Production Status |
| :--- | :--- | :--- | :---: |
| Google AdMob | Application ID | `ca-app-pub-3940256099942544~3347511713` | `Configured` |
| Google AdMob | Banner | `Not configured` | `Integrated but Not Configured` |
| Google AdMob | Native | `Not configured` | `Integrated but Not Configured` |
| Google AdMob | Interstitial | `Not configured` | `Integrated but Not Configured` |
| Google AdMob | Rewarded | `Not configured` | `Integrated but Not Configured` |
| Google AdMob | App Open | `Not configured` | `Integrated but Not Configured` |
| Google AdMob | Rewarded Interstitial | `Not configured` | `Integrated but Not Configured` |
> ⚠️ **Missing Production Configuration Warning**: Formats marked `Not configured` or `Integrated but Not Configured` will not serve third-party ads in Production mode. Missing demand sources are safely skipped without crashing the app.
### Provider Activation Prerequisites & Account Approval Guide:
1. **Google AdMob:** Requires an approved Google AdMob account with verified identity and active payment profile. `app-ads.txt` must be published on the app developer domain. Google Mobile Ads App ID (`APPLICATION_ID`) must be declared in native manifests.

### Native Manifest Declarations:
#### Android Manifest (`android/app/src/main/AndroidManifest.xml`):
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713" />
```

### Testing & Release Verification Rules:
- **Testing Mode is ACTIVE:** Official SDK test ads and sandbox unit IDs are automatically injected by WAPCentral. Never use or click live production ads during development.
- **Testing Configuration is Controlled Centrally:** Testing configuration is controlled centrally by WAPCentral. The mobile app must not hardcode fake production IDs.
- **Zero Production Clicks in Testing:** Never use or click live production ads for testing. Always use official sample ad units or test devices during development.
- **Secure Public Identifiers:** Only public client identifiers (such as App ID and Ad Unit ID) are included in mobile integration. Backend signing secrets and private reporting keys are strictly withheld.
- **Dynamic Config Fetch:** `wap_ads_sdk` fetches the effective configuration from `/api/platform/v1/ads/config`.
- **Omission of Disabled Units:** Disabled networks and formats must not be requested by client code.
- **Graceful No-Fill Handling:** When third-party fill is exhausted, applications display house promotions or collapse containers without UI disruption.

---

## 9. Remote App Service Control

WAPCentral provides an authoritative, per-app **Remote Service Status** control mechanism. The administrator can remotely pause or restore application service at any time from the WAPCentral Dashboard without submitting an app store update.

### Published Configuration for Doxivo:
- **Current Service Status:** `Enabled (Normal Service Active)`
- **Popup Dialog Title:** `Service Notice`
- **Popup Message:** `We are currently performing scheduled maintenance. Please check back shortly.`
- **Action Button Text:** `Learn More`
- **Destination URL:** `https://webappypie.com`
- **Last Updated:** `2026-10-25T23:22:22.016Z`

### Remote Service Control API Contract

Mobile applications check the remote service status via the dedicated endpoint:
- **Method:** `GET`
- **Route:** `/api/platform/v1/apps/app_1792970450704/service-status` (or `/api/platform/v1/service-status`)
- **Authentication:** Public or standard platform auth headers:
  - `X-App-Id: app_1792970450704`
  - `X-App-Key: wap_key_f03e1b83a399557027d2f968c4f559fa88052290`

#### Response Payload Example:
```json
{
  "success": true,
  "appId": "app_1792970450704",
  "service": "service_control",
  "data": {
    "enabled": true,
    "title": "Service Notice",
    "message": "We are currently performing scheduled maintenance. Please check back shortly.",
    "buttonText": "Learn More",
    "destinationUrl": "https://webappypie.com",
    "updatedAt": "2026-10-25T23:22:22.016Z"
  }
}
```

### Mobile Lifecycle & Operational Rules

1. **App Startup:**
   - During cold start (in `main.dart` / splash screen), call `GET /api/platform/v1/apps/app_1792970450704/service-status`.
   - If `data.enabled === false`, immediately render a full-screen, non-dismissible blocking dialog (`PopScope(canPop: false)`).
   - Display the configured `title`, `message`, and button text.
   - Clicking the action button opens `destinationUrl` in the external browser using `url_launcher`.
   - Normal app features and screens must remain completely blocked until service is restored.

2. **App Resume & Foreground Events:**
   - Listen to app lifecycle events (`WidgetsBindingObserver.didChangeAppLifecycleState` or `AppLifecycleListener.onResume`).
   - Re-query the service status endpoint when returning to the foreground.
   - If service has been paused remotely while the app was in the background, immediately display the blocking dialog.

3. **Temporary Network Failures & Offline Mode (Local-First Resilience):**
   - The application must operate **local-first and resiliently**.
   - If the endpoint is temporarily unreachable (e.g. airplane mode, network timeout, DNS error, HTTP 5xx), the app must **fail open** (`enabled: true`) to prevent locking offline users out of local features.
   - Log a non-fatal warning and retry on the next foreground resume event.

4. **Missing or Invalid Configuration:**
   - If the remote configuration is missing, returns invalid JSON, or fails validation, default to `enabled: true` (fail-open).

5. **Service Restoration:**
   - When the administrator re-enables service in the dashboard (`enabled: true`), the next foreground check or periodic poll receives `enabled: true`.
   - The blocking dialog is automatically dismissed, restoring normal app flow instantly.

6. **Older App Versions:**
   - Older app builds that do not include the Service Control client will continue normal operation.
   - If a mandatory upgrade is required, configure minimum version requirements in WAPCentral.

7. **Security Rules:**
   - Only public identifiers (`appId`) and standard client auth (`X-App-Key`) are used.
   - Never embed private backend signing secrets or admin credentials in the mobile app.

### Flutter Reference Implementation (`lib/services/service_control_guard.dart`):

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ServiceStatusData {
  final bool enabled;
  final String title;
  final String message;
  final String buttonText;
  final String destinationUrl;

  ServiceStatusData({
    required this.enabled,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.destinationUrl,
  });

  factory ServiceStatusData.fromJson(Map<String, dynamic> json) {
    return ServiceStatusData(
      enabled: json['enabled'] as bool? ?? true,
      title: json['title'] as String? ?? 'Service Notice',
      message: json['message'] as String? ?? 'Service is currently unavailable.',
      buttonText: json['buttonText'] as String? ?? 'Learn More',
      destinationUrl: json['destinationUrl'] as String? ?? 'https://webappypie.com',
    );
  }
}

class ServiceControlGuard {
  static const String _baseUrl = 'https://wapcentral.webappypie.com/api/platform/v1/apps/app_1792970450704/service-status';
  static const String _appId = 'app_1792970450704';
  static const String _appKey = String.fromEnvironment('WAP_APP_KEY', defaultValue: 'wap_key_f03e1b83a399557027d2f968c4f559fa88052290');

  static Future<ServiceStatusData> checkServiceStatus() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'X-App-Id': _appId,
          'X-App-Key': _appKey,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true && body['data'] != null) {
          return ServiceStatusData.fromJson(body['data']);
        }
      }
      return ServiceStatusData(
        enabled: true,
        title: '',
        message: '',
        buttonText: '',
        destinationUrl: '',
      );
    } catch (e) {
      debugPrint('WAPCentral Service Control check failed (fail-open): $e');
      return ServiceStatusData(
        enabled: true,
        title: '',
        message: '',
        buttonText: '',
        destinationUrl: '',
      );
    }
  }

  static void showBlockingDialog(BuildContext context, ServiceStatusData data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(data.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Text(data.message),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  final uri = Uri.tryParse(data.destinationUrl);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Text(data.buttonText),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

---

## 10. Notifications — Controlled by WAPCentral

Notifications are managed centrally from WAPCentral for this app. The mobile app does not contain its own campaign management system.

### Configuration Summary:
- **Notifications:** `Enabled`
- **FCM:** `Required (FCM configuration via google-services.json / GoogleService-Info.plist)`
- **wap_notifications_sdk:** `Required`
- **Device Registration Endpoint:** `POST /api/platform/v1/notifications/devices/register`
- **Notification Feed Endpoint:** `GET /api/platform/v1/notifications`

### Integration & Lifecycle Steps:
1. Initialize `wap_notifications_sdk` with the WAPCentral app credentials and the device FCM token.
2. Register the device with WAPCentral upon successful token acquisition.
3. Read the app-specific notification feed and synchronize unread/read state.
4. WAPCentral sends title, message body, optional rich image, and optional deep link payload.
5. WAPCentral supports Send Now / Schedule according to dashboard capabilities.

> [!CAUTION]
> **Security Notice:** Never place FCM server or service-account private credentials in the mobile app. All outbound push dispatches are securely performed server-side by WAPCentral.

---

## 11. App Startup Sequence

1. **Initialize Firebase:** Use standard Flutter Firebase setup (`await Firebase.initializeApp()`).
2. **Initialize WAPCore SDK:** Connect using the generated App ID and authorized credentials:
   - `baseUrl`: `https://wapcentral.webappypie.com/api/platform/v1`
   - `appId`: `app_1792970450704`
   - `appKey`: `wap_key_f03e1b83a399557027d2f968c4f559fa88052290`
   - `preferLocal`: `true`
3. **Verify Remote Service Status:** Query `/api/platform/v1/apps/app_1792970450704/service-status` before rendering primary views. If service is disabled, show blocking dialog.
4. **Initialize Enabled Modules:** Initialize only the WAP SDKs enabled for this application: `wap_core_sdk, wap_ads_sdk, wap_notifications_sdk, wap_promo_sdk`.
5. **Initialize Ads:** Initialize `wap_ads_sdk` to fetch the effective remote configuration from `/api/platform/v1/ads/config`.
6. **Register Push Device:** Obtain device FCM token via `FirebaseMessaging` and register with WAPCentral (`/api/platform/v1/notifications/devices/register`).
7. **No Secret Ingestion:** Do not fetch or store provider secrets in the client application.
8. **No Local Duplicate State:** Do not create a local duplicate of WAPCentral business configuration.
9. **Local-First Resilience:** Preserve local-first functionality if WAPCentral is temporarily unavailable.

---

## 12. Project File Checklist

- [ ] `android/app/google-services.json` is present and matches package `com.webappypie.doxivo`
- [ ] `ios/Runner/GoogleService-Info.plist` is present and matches bundle `com.webappypie.doxivo.ios`
- [ ] `pubspec.yaml` includes only the required WAP SDKs (`wap_core_sdk, wap_ads_sdk, wap_notifications_sdk, wap_promo_sdk`)
- [ ] No hardcoded third-party API keys (OpenAI, Gemini, Anthropic, InMobi) in source code
- [ ] No WAPCentral `X-App-Key` printed to production device logs
- [ ] No hardcoded production Ad Unit IDs in Flutter code (fetched dynamically from `/api/platform/v1/ads/config`)
- [ ] No hardcoded push notification campaigns or device bypass endpoints in mobile code
- [ ] App permissions and entitlements scoped to minimum requirements

---

## 13. Security & Compliance Rules

1. **Transport Security:** All client-to-server traffic is strictly encrypted over TLS 1.3/HTTPS.
2. **Server-Side Enforcement:** Every request is authenticated by `X-App-Id` and `X-App-Key`. Unauthorized modules return `403 Forbidden`.
3. **Zero Secret Leakage:** Provider master credentials, FCM server keys, and AI models reside in Google Cloud Secret Manager.
4. **App Isolation:** Applications cannot inspect or invoke configurations, campaigns, or ad units belonging to other apps.
5. **No Client Mocking in Production:** Mobile apps must never manufacture fake third-party ads, fake impressions, or simulated metrics.

---

## 14. What NOT To Do (Common Pitfalls)

- ❌ **Do NOT bundle multiple mediation platforms:** Never include Unity LevelPlay alongside AppLovin MAX.
- ❌ **Do NOT bundle unneeded ad adapters:** Only include adapters for networks enabled in WAPCentral.
- ❌ **Do NOT hardcode Ad Unit IDs:** Always fetch effective ad configurations from `/api/platform/v1/ads/config`.
- ❌ **Do NOT place server secrets in mobile code:** Never store private FCM keys, service account JSON, or AI API tokens in Flutter.
- ❌ **Do NOT bypass WAPCentral:** Do not call external AI APIs directly when the corresponding WAP service is available.
- ❌ **Do NOT block app launch on network error:** If WAPCentral is momentarily unreachable, fall back to local-first app functionality.

---

## 15. Release & Verification Checklist

- [ ] **Android Build:** App compiles with Android minSdk and targetSdk versions.
- [ ] **iOS Build:** App compiles with iOS deployment target and required privacy manifests.
- [ ] **Firebase Initialization:** Firebase initializes cleanly on cold start without crashes.
- [ ] **WAPCentral Health:** Cold-start check against `/api/platform/v1/health` succeeds.
- [ ] **Remote Service Control:** Service status endpoint is queried on startup and app foreground.
- [ ] **Service Access:** Enabled services respond with 200 OK; disabled services return 403 Forbidden.
- [ ] **Ads Environment:** Testing mode shows official test ads; Production mode serves configured units.
- [ ] **Custom Ads House Fallback:** Verify house promo banner displays gracefully when third-party fill is 0.
- [ ] **FCM Device Registration:** Device registers token with `/api/platform/v1/notifications/devices/register`.
- [ ] **Log Audit:** Verify no credentials, tokens, or PII appear in `flutter logs` or Android logcat.

---

## 16. New App Setup — Short Workflow

1. **Register Application:** Add the app under WAPCentral Applications.
2. **Configure Modules:** Enable required services (AI, Ads, Notifications) on the app details page.
3. **Configure Ads:** Enable required ad providers (AdMob, AppLovin MAX, Promotions) on the Ads page.
4. **Configure Service Control:** Verify remote service status is active.
5. **Download Guide:** Download this `.md` integration guide from Developer Resources.
6. **Add Dependencies:** Add only the required WAP SDKs and enabled ad adapters to `pubspec.yaml`.
7. **Initialize Client:** Add initialization snippet to `lib/main.dart` with secure credential handling and service guard.
8. **Verify & Release:** Run the release checklist before publishing to Google Play / App Store.

---

## 17. Source of Truth

This integration guide is generated dynamically for **Doxivo** (`app_1792970450704`). WAPCentral remains the authoritative source of truth for platform identity, Ads mediation, remote service status, notification rules, and service access. Firebase remains the source of truth for mobile push credentials and analytics.

*Generated by WAPCentral • Doxivo • app_1792970450704*
