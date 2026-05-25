# App Manga E2E Test Result

Time: 2026-05-17T22:14:18.8776686+07:00
Skill: skill-app-manga-e2e-test
Target: app_manga/integration_test/app_user_flows_e2e_test.dart
Result: NOT RUN

## Flow Covered By Existing Test

- Launch app_manga.
- Login if the login screen is shown.
- Verify Home and open the first manga.
- Verify Manga Detail and open the first chapter.
- Verify Reader page.
- Return to Home.
- Open Search and open the first search result.
- Open Library and verify library tabs.
- Open Me and verify the logged-in profile screen.

## Commands Attempted

```powershell
flutter --version
flutter devices
```

Both Flutter health-check commands timed out after 120 seconds, so the integration test suite was not started.

## Recovery Attempted

Detected stuck Dart process and Flutter SDK lock files:

```text
dart.exe: 7568
D:\FLUTTER\flutter_sdk\flutter\bin\cache\flutter.bat.lock
D:\FLUTTER\flutter_sdk\flutter\bin\cache\lockfile
```

Recovery commands run:

```powershell
Stop-Process -Id 7568 -Force
Remove-Item -LiteralPath D:\FLUTTER\flutter_sdk\flutter\bin\cache\flutter.bat.lock,D:\FLUTTER\flutter_sdk\flutter\bin\cache\lockfile -Force
flutter --version
flutter devices
```

Retry result:

- `flutter --version` timed out again after 120 seconds.
- `flutter devices` timed out again after 120 seconds.
- A new stuck Dart process was created and stopped: `dart.exe: 9096`.

## Likely Category

Environment: Flutter SDK / Dart tooling hang before test execution.

This is not an app UI or E2E test assertion failure. The test did not reach app startup.

## Next Action

1. Restart the machine or fully restart all IDE/terminal sessions using Flutter.
2. Confirm Flutter is responsive:

```powershell
flutter --version
flutter devices
```

3. Then run the app_manga E2E suite:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\script\e2e\run-app-manga-e2e.ps1 -ApiBaseUrl "http://192.168.0.195:5001/api"
```

If Flutter still hangs after restart, repair or reinstall the Flutter SDK at:

```text
D:\FLUTTER\flutter_sdk\flutter
```
