---
name: skill-webadmin-manga-e2e-test
description: Use this whenever the user asks to create, run, fix, or analyze end-to-end tests for ProjectManga's Flutter admin web app in web_admin only. This skill is for admin-facing web flows such as admin login, manga management, author management, chapter/page management, user management, notifications, dashboard/sidebar navigation, and other web_admin UI journeys that run through Flutter integration_test against a configured API base URL. Do not use this for app_manga E2E tests, backend controller/unit tests, or non-admin Flutter tests.
---

# skill-webAdmin-manga-e2e-test

Use this skill to work on end-to-end tests for the `web_admin/` Flutter admin app only.

The goal is to test real admin behavior through the web admin UI with Flutter `integration_test`. Keep test ownership inside `web_admin`; backend services may be required as running dependencies, but this skill should not create backend tests or app_manga tests.

## Scope

Target only these paths:

- `web_admin/integration_test/`
- `web_admin/test_driver/` if a driver is needed later
- `web_admin/test/` only for shared test helpers used by web admin tests
- `web_admin/pubspec.yaml` when test dependencies are missing
- `web_admin/lib/` only when stable widget keys or testability hooks are needed
- `script/e2e/` for root-level scripts that run web admin E2E commands

Avoid changing these unless the user explicitly asks:

- `app_manga/`
- `backend.Tests/`
- backend controller/unit test files
- production backend behavior

## Project Facts

- Flutter admin folder: `web_admin/`
- API constant file: `web_admin/lib/core/constants/constants.dart`
- Current API constant: `newAPIBaseURL`
- Recommended runtime API override: `--dart-define=API_BASE_URL=<url>`
- Default E2E package: Flutter SDK `integration_test`
- Default E2E device: `windows`
- Root E2E script folder: `script/e2e/`
- Preferred script: `script/e2e/run-web-admin-e2e.ps1`

If `newAPIBaseURL` is still hard-coded, update only `web_admin/lib/core/constants/constants.dart` to support `String.fromEnvironment('API_BASE_URL', defaultValue: '<current-url>')` before relying on `--dart-define`.

## When Starting

1. Inspect `web_admin/pubspec.yaml` and verify:
   - `flutter_test` exists under `dev_dependencies`
   - `integration_test` exists under `dev_dependencies` with `sdk: flutter`
2. Inspect `web_admin/integration_test/`.
   - If it does not exist, create it before adding E2E tests.
   - Name test files by admin flow, for example `admin_login_manage_manga_test.dart`.
3. Check whether the requested admin flow already has tests.
4. Check whether UI elements have stable `Key` values.
   - Prefer adding keys to important fields, buttons, menu items, rows, dialogs, and submit actions rather than relying only on visible text.
5. Confirm how the web admin should reach the backend:
   - Prefer a provided `API_BASE_URL`.
   - Otherwise use the current local/dev API URL supplied by the user or environment.

## Test Workflow

Use Flutter `integration_test` for E2E admin flows.

Before running E2E, quickly verify the Flutter tool is responsive:

```powershell
flutter --version
flutter devices
```

Default command from repo root:

```powershell
.\script\e2e\run-web-admin-e2e.ps1 -ApiBaseUrl "http://localhost:5001/api/"
```

Manual fallback from `web_admin/`:

```powershell
flutter pub get
flutter test integration_test --dart-define=API_BASE_URL=http://localhost:5001/api/ -d windows
```

Run one file:

```powershell
flutter test integration_test/admin_login_manage_manga_test.dart --dart-define=API_BASE_URL=http://localhost:5001/api/ -d windows
```

Prefer `-d windows` for Flutter `integration_test`. Flutter does not support running `integration_test` directly on web devices such as Chrome or Edge through `flutter test -d chrome`. If the user specifically wants browser-web E2E, use a browser automation setup such as Playwright/Selenium instead of this Flutter integration_test runner.

## Flutter Lock/Timeout Recovery

If `flutter --version`, `flutter devices`, or the E2E runner times out before test output appears, treat it as an environment problem before changing tests or app code.

Common local cause in this project: Flutter SDK cache locks or stale Dart/Flutter processes outside the workspace. The SDK may live outside the writable sandbox, for example:

- `D:\FLUTTER\flutter_sdk\flutter\bin\cache\flutter.bat.lock`
- `D:\FLUTTER\flutter_sdk\flutter\bin\cache\lockfile`

Recovery workflow:

1. Check running Flutter/Dart processes:

```powershell
Get-Process | Where-Object { $_.ProcessName -match 'flutter|dart|dartvm|web_admin' } | Select-Object ProcessName,Id,CPU,StartTime,Path
```

2. If stale Dart/Flutter processes are clearly from a stuck E2E/Flutter run, stop only those processes.
3. Remove stale Flutter SDK lock files only after the related stale processes are stopped.
4. Because the Flutter SDK is often outside the repo workspace, request escalated/outside-sandbox execution when stopping those processes or deleting SDK lock files.
5. Re-run `flutter --version` and `flutter devices`. Only continue to E2E once both commands respond normally.
6. Record the recovery steps and the final E2E result in `result_test_webadmin`.

Do not classify this as a web admin UI failure if Flutter hangs before printing test progress. Classify it as `Environment/Flutter SDK lock or runner timeout`.

## Recommended Admin Flows

Start with high-value admin journeys:

1. Admin login -> dashboard/home renders authenticated shell
2. Login -> sidebar navigation -> Manga management table
3. Manga management -> filter/search -> open manga detail
4. Manga management -> create manga -> validate new row or success state
5. Manga detail -> chapter list -> create/update/delete chapter when test data permits
6. Author management -> create/update/delete author when test data permits
7. User management -> search reader/admin -> open action dialog without destructive changes
8. Notifications -> create notification draft/send request when safe test data is available

Prefer one test file per broad journey. Keep assertions focused on visible admin outcomes and API-backed state changes that can be verified deterministically.

## Stable Keys

When adding or fixing tests, prefer stable keys for critical controls:

- `admin_login_email_field`
- `admin_login_password_field`
- `admin_login_submit_button`
- `admin_shell_sidebar`
- `admin_sidebar_manga`
- `admin_sidebar_authors`
- `admin_sidebar_users`
- `admin_sidebar_notifications`
- `manage_manga_table`
- `manage_manga_search_field`
- `manage_manga_create_button`
- `manage_manga_row_<id-or-slug>`
- `manga_form_submit_button`
- `manga_detail_screen`
- `chapter_list`
- `chapter_create_button`
- `manage_authors_table`
- `manage_users_table`
- `notifications_create_button`

Do not add keys everywhere. Add them where tests would otherwise become fragile or ambiguous.

## Test Data

E2E tests should use deterministic admin credentials and test records.

If the data is not available:

- Report the missing dependency clearly.
- Do not hard-code personal accounts.
- Prefer environment variables or `--dart-define` values for secrets and account credentials.
- Avoid destructive actions against shared development data.
- For create/update/delete flows, prefer uniquely named test records and clean them up when the UI and API support it.

Recommended environment variables:

- `API_BASE_URL`
- `WEB_ADMIN_E2E_EMAIL`
- `WEB_ADMIN_E2E_PASSWORD`

Recommended Dart defines:

- `API_BASE_URL`
- `WEB_ADMIN_E2E_EMAIL`
- `WEB_ADMIN_E2E_PASSWORD`

## Failure Analysis

When a test fails, classify the issue before editing code:

- Environment: Flutter SDK, Windows desktop device, package restore, backend not reachable
- Config: wrong `API_BASE_URL`, app constants do not read `--dart-define`
- Auth/test data: missing admin account, wrong role, expired seed data
- UI testability: missing keys, ambiguous selectors, dialog timing
- Web admin UI: navigation issue, async loading issue, form validation issue
- App logic/API handling: auth/session/API error visible from admin behavior
- Backend dependency: API error or missing data required by the tested admin flow

If the failure is a Flutter tool timeout, first apply the Flutter Lock/Timeout Recovery workflow above. Retry the same E2E command after recovery before reporting a final failure.

Only fix web admin code when the failure points to web admin behavior or testability. If the backend dependency is down or data is missing, report the dependency instead of weakening the test.

## Report Format

When finished, report:

- What admin E2E flow was created or run
- Files changed
- Command used
- Result: passed, failed, or not run
- If failed, the first actionable error and likely category
- Any required setup the user must provide, such as `API_BASE_URL` or admin test credentials

Keep the report concise and focused on the next useful action.
