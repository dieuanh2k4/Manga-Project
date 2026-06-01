import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../admin_test_helpers.dart';

Future<void> verifyAdminLoginFlow(WidgetTester tester) async {
  await loginAsAdmin(tester);

  expect(find.byKey(const Key('admin_sidebar_manga')), findsWidgets);
}

Future<void> verifyAdminLogoutFlow(WidgetTester tester) async {
  await logout(tester);
}
