# Run web_admin E2E (single file)

## Prereqs

- Backend E2E is running (docker compose).
- API base URL in this script matches your backend.

## Usage


From web_admin:

```powershell
..\script\e2e\run-web-admin-one.ps1 integration_test/admin_login_test.dart
..\script\e2e\run-web-admin-one.ps1 integration_test/admin_manga_management_test.dart
..\script\e2e\run-web-admin-one.ps1 integration_test/admin_authors_management_test.dart
..\script\e2e\run-web-admin-one.ps1 integration_test/admin_users_management_test.dart
..\script\e2e\run-web-admin-one.ps1 integration_test/admin_notifications_management_test.dart
..\script\e2e\run-web-admin-one.ps1 integration_test/admin_logout_test.dart
..\script\e2e\run-web-admin-one.ps1 integration_test/admin_smoke_flow_test.dart

