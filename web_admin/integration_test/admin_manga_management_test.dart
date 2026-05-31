import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'admin_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('admin can search manga and open create form', (tester) async {
    await launchAdminApp(tester);
    await loginAsAdmin(tester);

    await tapFirstKey(tester, const Key('admin_sidebar_manga'));
    await waitForFinder(
      tester,
      find.byKey(const Key('manage_manga_create_button')),
    );
    await filterSeededManga(tester);
    await openMangaCreateFormAndCancel(tester);
  });
}
