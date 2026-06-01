import 'package:flutter_test/flutter_test.dart';

import '../admin_test_helpers.dart';

Future<void> verifyAdminAuthorsManagementFlow(WidgetTester tester) async {
  await openAuthorsAndCancelCreateDialog(tester);
}
