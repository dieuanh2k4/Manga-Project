# App Manga E2E Test Result

Time: 2026-05-17T22:38:21.2907245+07:00
Skill: skill-app-manga-e2e-test
Target: app_manga/integration_test/app_user_flows_e2e_test.dart
Result: PASSED

## Flow Tested

- Launch app_manga.
- Login if the login screen is shown.
- Verify Home and open the first manga.
- Verify Manga Detail and open the first chapter.
- Verify Reader page.
- Return to Home.
- Open Search and open the first search result.
- Open Library and verify library tabs.
- Open Me and verify the logged-in user profile screen.

## Environment

- Flutter: 3.38.6 stable
- Dart: 3.10.7
- Device: SM A135F / R58TC11CD9R / Android 14 API 34
- API_BASE_URL: http://192.168.0.195:5001/api

## Commands Run

```powershell
$env:APPDATA='D:\4-2\multi-platform-2\ProjectManga\.codex_appdata'
$env:PATH='D:\ANDROI\Sdk\platform-tools;' + $env:PATH
flutter --no-version-check --version
flutter devices
powershell -NoProfile -ExecutionPolicy Bypass -File .\script\e2e\run-app-manga-e2e.ps1 -ApiBaseUrl "http://192.168.0.195:5001/api" -Device R58TC11CD9R
```

## Outcome

- `flutter --no-version-check --version` passed.
- `flutter devices` detected the Android phone.
- `flutter pub get` completed.
- Gradle built `build\app\outputs\flutter-apk\app-debug.apk`.
- Flutter installed the debug APK on `R58TC11CD9R`.
- E2E command finished with exit code `0`.

## Warnings Observed

These did not fail the E2E command, but they are worth fixing:

- Some remote image URLs failed while rendering:
  - `https://via.placeholder.com/600x300/ffccaa/ffffff?text=Frieren+Banner` ended with `HandshakeException`.
  - `https://example.com/pages/one-piece-2-2.jpg` returned HTTP 404.
- Gradle/Kotlin printed incremental cache errors for `shared_preferences_android`:
  - `Could not close incremental caches`
  - `this and base files have different roots`

## Notes

The earlier timeout was resolved by running Flutter outside the sandbox and adding Android platform-tools to PATH. This run confirms the connected phone is usable for app_manga E2E.
