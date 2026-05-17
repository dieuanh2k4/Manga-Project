---
name: skill-app-manga-e2e-test
description: Use this whenever the user asks to create, run, fix, or analyze end-to-end tests for ProjectManga's Flutter user app in app_manga only. This skill is for user-facing app flows such as login, register, browsing manga, search, manga detail, reading chapters, library/follow, reading history, notifications, and VIP/package screens that run through Flutter integration_test against a configured API base URL. Do not use this for web_admin E2E tests or backend controller/unit tests.
---

# skill-app-manga-e2e-test

Use this skill to work on end-to-end tests for the `app_manga/` Flutter app only.

The goal is to test user behavior through the app UI with `integration_test`, while keeping the test ownership inside `app_manga`. The backend may be required as a running dependency, but this skill should not create backend tests or web admin tests.

## Scope

Target only these paths:

- `app_manga/integration_test/`
- `app_manga/test_driver/` if a driver is needed later
- `app_manga/test/` only for shared test helpers used by app tests
- `app_manga/pubspec.yaml` when test dependencies are missing
- `app_manga/lib/` only when stable widget keys or testability hooks are needed
- `script/e2e/` for root-level scripts that run app manga E2E commands

Avoid changing these unless the user explicitly asks:

- `web_admin/`
- `backend.Tests/`
- backend controller/unit test files
- production backend behavior

## Project facts

- Flutter app folder: `app_manga/`
- API config: `app_manga/lib/core/config/app_config.dart`
- Runtime API override: `--dart-define=API_BASE_URL=<url>`
- Default E2E package: Flutter SDK `integration_test`
- Root E2E script folder: `script/e2e/`
- Preferred script: `script/e2e/run-app-manga-e2e.ps1`

## When Starting

1. Inspect `app_manga/pubspec.yaml` and verify:
   - `flutter_test` exists under `dev_dependencies`
   - `integration_test` exists under `dev_dependencies` with `sdk: flutter`
2. Inspect `app_manga/integration_test/`.
   - If it does not exist, create it before adding E2E tests.
   - Name test files by user flow, for example `user_login_read_chapter_test.dart`.
3. Check whether the requested user flow already has tests.
4. Check whether UI elements have stable `Key` values.
   - Prefer adding keys to important fields/buttons rather than relying only on visible text.
5. Confirm how the app should reach the backend:
   - Prefer a provided `API_BASE_URL`.
   - Otherwise use the current local/dev API URL supplied by the user or environment.

## Test Workflow

Use Flutter `integration_test` for E2E user flows.

Before running E2E, quickly verify the Flutter tool is responsive:

```powershell
flutter --version
flutter devices
```

Default commands from repo root:

```powershell
.\script\e2e\run-app-manga-e2e.ps1 -ApiBaseUrl "http://localhost:5219/api"
```

Manual fallback from `app_manga/`:

```powershell
flutter pub get
flutter test integration_test --dart-define=API_BASE_URL=http://localhost:5219/api
```

Run one file:

```powershell
flutter test integration_test/user_login_read_chapter_test.dart --dart-define=API_BASE_URL=http://localhost:5219/api
```

When a device is required:

```powershell
flutter test integration_test --dart-define=API_BASE_URL=http://localhost:5219/api -d chrome
```

## Flutter Lock/Timeout Recovery

If `flutter --version`, `flutter devices`, or the E2E runner times out before test output appears, treat it as an environment problem before changing tests or app code.

Common local cause in this project: Flutter SDK cache locks or stale Dart/Flutter processes outside the workspace. The SDK may live outside the writable sandbox, for example:

- `D:\FLUTTER\flutter_sdk\flutter\bin\cache\flutter.bat.lock`
- `D:\FLUTTER\flutter_sdk\flutter\bin\cache\lockfile`

Recovery workflow:

1. Check running Flutter/Dart processes:

```powershell
Get-Process | Where-Object { $_.ProcessName -match 'flutter|dart|dartvm|app_manga' } | Select-Object ProcessName,Id,CPU,StartTime,Path
```

2. If stale Dart/Flutter processes are clearly from a stuck E2E/Flutter run, stop only those processes.
3. Remove stale Flutter SDK lock files only after the related stale processes are stopped.
4. Because the Flutter SDK is often outside the repo workspace, request escalated/outside-sandbox execution when stopping those processes or deleting SDK lock files.
5. Re-run `flutter --version` and `flutter devices`. Only continue to E2E once both commands respond normally.
6. Record the recovery steps and the final E2E result in the app E2E result folder requested by the user, or the repo's existing result folder if no folder is specified.

Do not classify this as an app UI failure if Flutter hangs before printing test progress. Classify it as `Environment/Flutter SDK lock or runner timeout`.

## Recommended User Flows

Start with high-value user journeys:

1. Login -> Home -> Manga detail -> Chapter reader
2. Register -> Login -> Home
3. Search manga -> Open result -> Manga detail
4. Manga detail -> Add to library/follow -> Library shows manga
5. Chapter reader -> Reading history is updated
6. Notification list -> Open notification detail if supported
7. VIP/package list -> Open package detail or purchase entry point without completing real payment

Prefer one test file per broad journey. Keep assertions focused on visible user outcomes.

## Test File Pattern

Use this structure for new E2E tests:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app_manga/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('user can login and open a manga chapter', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Arrange/act/assert through visible UI and stable keys.
  });
}
```

## Stable Keys

When adding or fixing tests, prefer stable keys for critical controls:

- `login_email_field`
- `login_password_field`
- `login_submit_button`
- `home_manga_list`
- `manga_search_field`
- `manga_search_result_<id-or-slug>`
- `manga_detail_screen`
- `chapter_list`
- `chapter_reader_screen`
- `library_tab`
- `library_manga_<id-or-slug>`

Do not add keys everywhere. Add them where tests otherwise become fragile or ambiguous.

## Test Data

E2E tests should use deterministic test accounts and manga data.

If the data is not available:

- Report the missing dependency clearly.
- Do not hard-code personal accounts.
- Prefer environment variables for secrets or account credentials.
- Avoid destructive actions against shared development data.

Recommended environment variables:

- `API_BASE_URL`
- `APP_MANGA_E2E_EMAIL`
- `APP_MANGA_E2E_PASSWORD`

## Failure Analysis

When a test fails, classify the issue before editing code:

- Environment: Flutter SDK, device, package restore, backend not reachable
- Config: wrong `API_BASE_URL`, missing `--dart-define`
- Test data: missing account, missing manga/chapter, unexpected permissions
- App UI: missing keys, navigation issue, async loading issue
- App logic: auth/session/API handling bug
- Backend dependency: API error visible from app behavior

If the failure is a Flutter tool timeout, first apply the Flutter Lock/Timeout Recovery workflow above. Retry the same E2E command after recovery before reporting a final failure.

Only fix app code when the failure points to app behavior or testability. If the backend dependency is down or data is missing, report the dependency instead of rewriting tests around it.

## Report Format

When finished, report:

- What E2E flow was created or run
- Files changed
- Command used
- Result: passed, failed, or not run
- If failed, the first actionable error and likely category
- Any required setup the user must provide, such as `API_BASE_URL` or test credentials

Keep the report concise and focused on the next useful action.
