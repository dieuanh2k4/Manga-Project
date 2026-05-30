import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'admin_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('admin can login and see shell', (tester) async {
    await launchAdminApp(tester);
    await loginAsAdmin(tester);

    expect(find.byKey(const Key('admin_sidebar_manga')), findsWidgets);
  });
}
