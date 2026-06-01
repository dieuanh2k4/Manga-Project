import 'package:flutter_test/flutter_test.dart';

import '../admin_test_helpers.dart';

Future<void> verifyAdminNotificationsManagementFlow(WidgetTester tester) async {
  await openNotificationsAndCancelCreateDialog(tester);
}
