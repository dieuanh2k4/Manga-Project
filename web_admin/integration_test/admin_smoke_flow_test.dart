import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web_admin/main.dart' as app;

const String _adminUserName = String.fromEnvironment(
  'WEB_ADMIN_E2E_EMAIL',
  defaultValue: 'e2e_admin',
);
const String _adminPassword = String.fromEnvironment(
  'WEB_ADMIN_E2E_PASSWORD',
  defaultValue: 'E2e@123456',
);
const String _seedMangaTitle = String.fromEnvironment(
  'WEB_ADMIN_E2E_MANGA_TITLE',
  defaultValue: 'E2E Readable Manga',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('admin can login and navigate core management flows', (
    tester,
  ) async {
    expect(
      _adminUserName,
      isNotEmpty,
      reason:
          'Pass --dart-define=WEB_ADMIN_E2E_EMAIL=<admin username or email>.',
    );
    expect(
      _adminPassword,
      isNotEmpty,
      reason: 'Pass --dart-define=WEB_ADMIN_E2E_PASSWORD=<admin password>.',
    );

    await _setDesktopViewport(tester);

    await app.main();
    await tester.pumpAndSettle();

    await _loginAsAdmin(tester);

    await _waitForFinder(
      tester,
      find.byKey(const Key('manage_manga_create_button')),
    );
    await _filterSeededManga(tester);

    await _openMangaCreateFormAndCancel(tester);
    await _openAuthorsAndCancelCreateDialog(tester);
    await _openUsersAndCancelCreateDialog(tester);
    await _openNotificationsAndCancelCreateDialog(tester);
    await _logout(tester);
  });
}

Future<void> _setDesktopViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _loginAsAdmin(WidgetTester tester) async {
  await _waitForText(tester, 'Welcome to MangaMinus Admin');

  await tester.enterText(
    find.byKey(const Key('admin_login_username_field')),
    _adminUserName,
  );
  await tester.enterText(
    find.byKey(const Key('admin_login_password_field')),
    _adminPassword,
  );
  await tester.tap(find.byKey(const Key('admin_login_submit_button')));
  await tester.pump();

  await _waitForAuthenticatedShell(tester);
}

Future<void> _waitForAuthenticatedShell(WidgetTester tester) async {
  final shellFinder = find.byKey(const Key('admin_sidebar_manga'));
  final errorFinder = find.byKey(const Key('admin_login_error_message'));

  await _waitUntil(
    tester,
    () => shellFinder.evaluate().isNotEmpty || errorFinder.evaluate().isNotEmpty,
    reason:
        'Admin login did not reach the authenticated shell and no login error was shown.',
    timeout: const Duration(seconds: 60),
  );

  if (errorFinder.evaluate().isNotEmpty) {
    final errorWidget = tester.widget<Container>(errorFinder.first);
    final errorText = _extractText(errorWidget.child);
    fail('Admin login failed: ${errorText ?? 'unknown login error'}');
  }

  expect(shellFinder, findsWidgets);
}

Future<void> _filterSeededManga(WidgetTester tester) async {
  final searchField = find.byKey(const Key('manage_manga_search_field'));
  await _waitForFinder(tester, searchField);

  await tester.enterText(searchField, _seedMangaTitle);
  await tester.pumpAndSettle();

  await _waitForText(tester, _seedMangaTitle);
}

Future<void> _openMangaCreateFormAndCancel(WidgetTester tester) async {
  await _tapFirstKey(tester, const Key('manage_manga_create_button'));

  await _waitForFinder(
    tester,
    find.byKey(const Key('manga_form_cancel_button')),
  );
  await _tapFirstKey(tester, const Key('manga_form_cancel_button'));
  await tester.pumpAndSettle();

  await _waitForFinder(
    tester,
    find.byKey(const Key('manage_manga_create_button')),
  );
}

Future<void> _openAuthorsAndCancelCreateDialog(WidgetTester tester) async {
  await _tapFirstKey(tester, const Key('admin_sidebar_authors'));
  await _waitForFinder(
    tester,
    find.byKey(const Key('manage_authors_create_button')),
  );

  await _tapFirstKey(tester, const Key('manage_authors_create_button'));
  await _waitForFinder(
    tester,
    find.byKey(const Key('manage_author_dialog_name_field')),
  );
  await _tapFirstKey(tester, const Key('manage_author_dialog_cancel_button'));
  await tester.pumpAndSettle();

  await _waitForFinder(
    tester,
    find.byKey(const Key('manage_authors_create_button')),
  );
}

Future<void> _openUsersAndCancelCreateDialog(WidgetTester tester) async {
  await _tapFirstKey(tester, const Key('admin_sidebar_users'));
  await _waitForFinder(
    tester,
    find.byKey(const Key('manage_users_create_button')),
  );

  await _tapFirstKey(tester, const Key('manage_users_create_button'));
  await _waitForFinder(
    tester,
    find.byKey(const Key('manage_user_dialog_cancel_button')),
  );
  await _tapFirstKey(tester, const Key('manage_user_dialog_cancel_button'));
  await tester.pumpAndSettle();

  await _waitForFinder(
    tester,
    find.byKey(const Key('manage_users_create_button')),
  );
}

Future<void> _openNotificationsAndCancelCreateDialog(
  WidgetTester tester,
) async {
  await _tapFirstKey(tester, const Key('admin_sidebar_notifications'));
  await _waitForFinder(
    tester,
    find.byKey(const Key('manage_notifications_create_button')),
  );

  await _tapFirstKey(tester, const Key('manage_notifications_create_button'));
  await _waitForFinder(
    tester,
    find.byKey(const Key('manage_notification_dialog_title_field')),
  );
  await _tapFirstKey(
    tester,
    const Key('manage_notification_dialog_cancel_button'),
  );
  await tester.pumpAndSettle();

  await _waitForFinder(
    tester,
    find.byKey(const Key('manage_notifications_create_button')),
  );
}

Future<void> _logout(WidgetTester tester) async {
  await _tapFirstKey(tester, const Key('admin_logout_button'));
  await _waitForText(tester, 'Welcome to MangaMinus Admin');
}

Future<void> _tapFirstKey(WidgetTester tester, Key key) async {
  final Finder finder = find.byKey(key);
  await _waitForFinder(tester, finder);
  await tester.ensureVisible(finder.first);
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

Future<void> _waitForText(WidgetTester tester, String text) {
  return _waitForFinder(tester, find.text(text));
}

String? _extractText(Widget? widget) {
  if (widget == null) {
    return null;
  }

  if (widget is Text) {
    return widget.data;
  }

  if (widget is SingleChildRenderObjectWidget) {
    return _extractText(widget.child);
  }

  if (widget is MultiChildRenderObjectWidget) {
    for (final child in widget.children) {
      final text = _extractText(child);
      if (text != null && text.trim().isNotEmpty) {
        return text;
      }
    }
  }

  return null;
}

Future<void> _waitUntil(
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

Future<void> _waitForFinder(
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

Future<void> _waitForGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final DateTime end = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isEmpty) {
      return;
    }
  }

  expect(finder, findsNothing);
}
