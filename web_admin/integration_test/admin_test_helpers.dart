import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_admin/main.dart' as app;

const String adminUserName = String.fromEnvironment(
  'WEB_ADMIN_E2E_EMAIL',
  defaultValue: 'e2e_admin',
);
const String adminPassword = String.fromEnvironment(
  'WEB_ADMIN_E2E_PASSWORD',
  defaultValue: 'E2e@123456',
);
const String seedMangaTitle = String.fromEnvironment(
  'WEB_ADMIN_E2E_MANGA_TITLE',
  defaultValue: 'E2E Readable Manga',
);

Future<void> setDesktopViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> launchAdminApp(WidgetTester tester) async {
  await setDesktopViewport(tester);
  await app.main();
  await tester.pumpAndSettle();
}

Future<void> loginAsAdmin(WidgetTester tester) async {
  expect(
    adminUserName,
    isNotEmpty,
    reason: 'Pass --dart-define=WEB_ADMIN_E2E_EMAIL=<admin username or email>.',
  );
  expect(
    adminPassword,
    isNotEmpty,
    reason: 'Pass --dart-define=WEB_ADMIN_E2E_PASSWORD=<admin password>.',
  );

  await waitForText(tester, 'Welcome to MangaMinus Admin');

  await tester.enterText(
    find.byKey(const Key('admin_login_username_field')),
    adminUserName,
  );
  await tester.enterText(
    find.byKey(const Key('admin_login_password_field')),
    adminPassword,
  );
  await tester.tap(find.byKey(const Key('admin_login_submit_button')));
  await tester.pump();

  await waitForAuthenticatedShell(tester);
}

Future<void> waitForAuthenticatedShell(WidgetTester tester) async {
  final shellFinder = find.byKey(const Key('admin_sidebar_manga'));
  final errorFinder = find.byKey(const Key('admin_login_error_message'));

  await waitUntil(
    tester,
    () => shellFinder.evaluate().isNotEmpty || errorFinder.evaluate().isNotEmpty,
    reason:
        'Admin login did not reach the authenticated shell and no login error was shown.',
    timeout: const Duration(seconds: 60),
  );

  if (errorFinder.evaluate().isNotEmpty) {
    final errorWidget = tester.widget<Container>(errorFinder.first);
    final errorText = extractText(errorWidget.child);
    fail('Admin login failed: ${errorText ?? 'unknown login error'}');
  }

  expect(shellFinder, findsWidgets);
}

Future<void> filterSeededManga(WidgetTester tester) async {
  final searchField = find.byKey(const Key('manage_manga_search_field'));
  await waitForFinder(tester, searchField);

  await tester.enterText(searchField, seedMangaTitle);
  await tester.pumpAndSettle();

  await waitForText(tester, seedMangaTitle);
}

Future<void> openMangaCreateFormAndCancel(WidgetTester tester) async {
  await tapFirstKey(tester, const Key('manage_manga_create_button'));

  await waitForFinder(
    tester,
    find.byKey(const Key('manga_form_cancel_button')),
  );
  await tapFirstKey(tester, const Key('manga_form_cancel_button'));
  await tester.pumpAndSettle();

  await waitForFinder(
    tester,
    find.byKey(const Key('manage_manga_create_button')),
  );
}

Future<void> openAuthorsAndCancelCreateDialog(WidgetTester tester) async {
  await tapFirstKey(tester, const Key('admin_sidebar_authors'));
  await waitForFinder(
    tester,
    find.byKey(const Key('manage_authors_create_button')),
  );

  await tapFirstKey(tester, const Key('manage_authors_create_button'));
  await waitForFinder(
    tester,
    find.byKey(const Key('manage_author_dialog_name_field')),
  );
  await tapFirstKey(tester, const Key('manage_author_dialog_cancel_button'));
  await tester.pumpAndSettle();

  await waitForFinder(
    tester,
    find.byKey(const Key('manage_authors_create_button')),
  );
}

Future<void> openUsersAndCancelCreateDialog(WidgetTester tester) async {
  await tapFirstKey(tester, const Key('admin_sidebar_users'));
  await waitForFinder(
    tester,
    find.byKey(const Key('manage_users_create_button')),
  );

  await tapFirstKey(tester, const Key('manage_users_create_button'));
  await waitForFinder(
    tester,
    find.byKey(const Key('manage_user_dialog_cancel_button')),
  );
  await tapFirstKey(tester, const Key('manage_user_dialog_cancel_button'));
  await tester.pumpAndSettle();

  await waitForFinder(
    tester,
    find.byKey(const Key('manage_users_create_button')),
  );
}

Future<void> openNotificationsAndCancelCreateDialog(
  WidgetTester tester,
) async {
  await tapFirstKey(tester, const Key('admin_sidebar_notifications'));
  await waitForFinder(
    tester,
    find.byKey(const Key('manage_notifications_create_button')),
  );

  await tapFirstKey(tester, const Key('manage_notifications_create_button'));
  await waitForFinder(
    tester,
    find.byKey(const Key('manage_notification_dialog_title_field')),
  );
  await tapFirstKey(tester, const Key('manage_notification_dialog_cancel_button'));
  await tester.pumpAndSettle();

  await waitForFinder(
    tester,
    find.byKey(const Key('manage_notifications_create_button')),
  );
}

Future<void> logout(WidgetTester tester) async {
  await tapFirstKey(tester, const Key('admin_profile_menu_button'));
  await tapFirstKey(tester, const Key('admin_logout_button'));
  await waitForText(tester, 'Welcome to MangaMinus Admin');
}

Future<void> tapFirstKey(WidgetTester tester, Key key) async {
  final Finder finder = find.byKey(key);
  await waitForFinder(tester, finder);
  await tester.ensureVisible(finder.first);
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

Future<void> waitForText(WidgetTester tester, String text) {
  return waitForFinder(tester, find.text(text));
}

String? extractText(Widget? widget) {
  if (widget == null) {
    return null;
  }

  if (widget is Text) {
    return widget.data;
  }

  if (widget is SingleChildRenderObjectWidget) {
    return extractText(widget.child);
  }

  if (widget is MultiChildRenderObjectWidget) {
    for (final child in widget.children) {
      final text = extractText(child);
      if (text != null && text.trim().isNotEmpty) {
        return text;
      }
    }
  }

  return null;
}

Future<void> waitUntil(
  WidgetTester tester,
  bool Function() condition, {
  required String reason,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final DateTime end = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (condition()) {
      return;
    }
  }

  fail(reason);
}

Future<void> waitForFinder(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final DateTime end = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  expect(finder, findsWidgets);
}
