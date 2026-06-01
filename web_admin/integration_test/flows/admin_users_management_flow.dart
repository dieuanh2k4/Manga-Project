import 'package:flutter_test/flutter_test.dart';

import '../admin_test_helpers.dart';

Future<void> verifyAdminUsersManagementFlow(WidgetTester tester) async {
  await openUsersAndCancelCreateDialog(tester);
}
