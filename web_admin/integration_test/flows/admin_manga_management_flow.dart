import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../admin_test_helpers.dart';

Future<void> verifyAdminMangaManagementFlow(WidgetTester tester) async {
  await tapFirstKey(tester, const Key('admin_sidebar_manga'));
  await waitForFinder(
    tester,
    find.byKey(const Key('manage_manga_create_button')),
  );
  await filterSeededManga(tester);
  await openMangaCreateFormAndCancel(tester);
}
