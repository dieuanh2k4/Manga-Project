import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'admin_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('admin can logout', (tester) async {
    await launchAdminApp(tester);
    await loginAsAdmin(tester);

    await logout(tester);
  });
}
