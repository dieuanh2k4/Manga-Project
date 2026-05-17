import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web_admin/main.dart' as app;

const String _adminUserName = String.fromEnvironment(
  'WEB_ADMIN_E2E_EMAIL',
  defaultValue: 'admin',
);
const String _adminPassword = String.fromEnvironment(
  'WEB_ADMIN_E2E_PASSWORD',
  defaultValue: 'admin123',
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

    await _waitForTextContaining(tester, 'Manga');
    expect(find.textContaining('Manga'), findsWidgets);

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

  final Finder fields = find.byType(TextFormField);
  expect(fields, findsNWidgets(2));

  await tester.enterText(fields.at(0), _adminUserName);
  await tester.enterText(fields.at(1), _adminPassword);
  await tester.tap(find.text('LOGIN'));
  await tester.pump();

  await _waitForGone(tester, find.text('LOGIN'));
}

Future<void> _openMangaCreateFormAndCancel(WidgetTester tester) async {
  await _waitForTextContaining(tester, 'Manga');

  await _tapFirstIcon(tester, Icons.add);

  await _waitForTextContaining(tester, 'Thông tin cơ bản');
  await _tapFirstVisibleText(tester, 'Hủy');
  await tester.pumpAndSettle();

  await _waitForTextContaining(tester, 'Manga');
}

Future<void> _openAuthorsAndCancelCreateDialog(WidgetTester tester) async {
  await _tapFirstIcon(tester, Icons.person_pin_rounded);
  await _waitForTextContaining(tester, 'tác giả');

  await _tapFirstVisibleTextContaining(tester, 'Thêm tác giả');
  await _waitForTextContaining(tester, 'Tên tác giả');
  await _tapFirstVisibleText(tester, 'Hủy');
  await tester.pumpAndSettle();

  await _waitForTextContaining(tester, 'tác giả');
}

Future<void> _openUsersAndCancelCreateDialog(WidgetTester tester) async {
  await _tapFirstIcon(tester, Icons.people_outline_rounded);
  await _waitForTextContaining(tester, 'tài khoản');

  await _tapFirstVisibleTextContaining(tester, 'Thêm tài khoản');
  await _waitForTextContaining(tester, 'người dùng');
  await _tapFirstVisibleText(tester, 'Hủy');
  await tester.pumpAndSettle();

  await _waitForTextContaining(tester, 'tài khoản');
}

Future<void> _openNotificationsAndCancelCreateDialog(
  WidgetTester tester,
) async {
  await _tapLastIcon(tester, Icons.notifications_none_rounded);
  await _waitForTextContaining(tester, 'thông báo');

  await _tapFirstVisibleTextContaining(tester, 'Tạo thông báo');
  await _waitForTextContaining(tester, 'Tiêu đề');
  await _tapFirstVisibleText(tester, 'Hủy');
  await tester.pumpAndSettle();

  await _waitForTextContaining(tester, 'thông báo');
}

Future<void> _logout(WidgetTester tester) async {
  await _tapFirstIcon(tester, Icons.logout_rounded);
  await _waitForText(tester, 'Welcome to MangaMinus Admin');
}

Future<void> _tapFirstIcon(WidgetTester tester, IconData icon) async {
  final Finder finder = find.byIcon(icon);
  await _waitForFinder(tester, finder);
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

Future<void> _tapLastIcon(WidgetTester tester, IconData icon) async {
  final Finder finder = find.byIcon(icon);
  await _waitForFinder(tester, finder);
  await tester.tap(finder.last);
  await tester.pumpAndSettle();
}

Future<void> _tapFirstVisibleText(WidgetTester tester, String text) async {
  final Finder finder = find.text(text);
  await _waitForFinder(tester, finder);
  await tester.ensureVisible(finder.first);
  await tester.tap(finder.first);
}

Future<void> _tapFirstVisibleTextContaining(
  WidgetTester tester,
  String text,
) async {
  final Finder finder = find.textContaining(text);
  await _waitForFinder(tester, finder);
  await tester.ensureVisible(finder.first);
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

Future<void> _waitForText(WidgetTester tester, String text) {
  return _waitForFinder(tester, find.text(text));
}

Future<void> _waitForTextContaining(WidgetTester tester, String text) {
  return _waitForFinder(tester, find.textContaining(text));
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
