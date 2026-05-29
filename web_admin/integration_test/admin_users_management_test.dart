import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'admin_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('admin can open users create dialog', (tester) async {
    await launchAdminApp(tester);
    await loginAsAdmin(tester);

    await openUsersAndCancelCreateDialog(tester);
  });
}
