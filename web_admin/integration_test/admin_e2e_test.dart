import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'admin_test_helpers.dart';
import 'flows/admin_auth_flow.dart';
import 'flows/admin_authors_management_flow.dart';
import 'flows/admin_manga_management_flow.dart';
import 'flows/admin_notifications_management_flow.dart';
import 'flows/admin_users_management_flow.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('admin can complete core end to end flows', (tester) async {
    await launchAdminApp(tester);

    await verifyAdminLoginFlow(tester);
    await verifyAdminMangaManagementFlow(tester);
    await verifyAdminAuthorsManagementFlow(tester);
    await verifyAdminUsersManagementFlow(tester);
    await verifyAdminNotificationsManagementFlow(tester);
    await verifyAdminLogoutFlow(tester);
  });
}
