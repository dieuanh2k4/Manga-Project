import 'package:app_manga/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _username = String.fromEnvironment(
  'APP_MANGA_E2E_USERNAME',
  defaultValue: 'reader01',
);
const _password = String.fromEnvironment(
  'APP_MANGA_E2E_PASSWORD',
  defaultValue: 'reader123',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Notification flow e2e test', (tester) async {
    await _launchApp(tester);
    await _loginIfNeeded(tester);

    // 1. Open Notification page from Home
    await _openNotifications(tester);

    // 2. Verify Notification Page UI
    await _verifyNotificationPageUI(tester);

    // 3. Test list or empty state interaction
    await _testNotificationInteraction(tester);

    // 4. Navigate back to Home
    await _goBackToHome(tester);
  });
}

Future<void> _launchApp(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 2));
  await _waitForAppSettled(tester);
}

Future<void> _loginIfNeeded(WidgetTester tester) async {
  if (find.text('LOGIN').evaluate().isEmpty) {
    return;
  }

  final textFields = find.byType(TextField);
  expect(textFields, findsAtLeastNWidgets(2));

  await tester.enterText(textFields.at(0), _username);
  await tester.enterText(textFields.at(1), _password);
  await tester.tap(find.text('LOG IN'));
  await tester.pumpAndSettle();

  await _waitUntil(
    tester,
    () => find.text('Last Updates').evaluate().isNotEmpty,
    reason: 'Home page should be visible after login.',
  );
}

Future<void> _openNotifications(WidgetTester tester) async {
  final notificationBell = find.byTooltip('Thong bao');
  expect(notificationBell, findsOneWidget);
  await tester.tap(notificationBell);
  await tester.pumpAndSettle();

  await _waitUntil(
    tester,
    () => find.descendant(
      of: find.byType(AppBar),
      matching: find.text('Thong bao'),
    ).evaluate().isNotEmpty,
    reason: 'Notification page should open with "Thong bao" title.',
  );
}

Future<void> _verifyNotificationPageUI(WidgetTester tester) async {
  // Check that "Da doc tat ca" button is present
  expect(find.text('Da doc tat ca'), findsOneWidget);
}

Future<void> _testNotificationInteraction(WidgetTester tester) async {
  final isEmpty = find.text('Chua co thong bao').evaluate().isNotEmpty;

  if (isEmpty) {
    expect(find.text('Chua co thong bao'), findsOneWidget);
  } else {
    // We have active notification items
    expect(find.byType(ListTile), findsAtLeastNWidgets(1));

    // Optional: Tap "Da doc tat ca" to mark notifications as read
    final doneAllButton = find.text('Da doc tat ca');
    await tester.tap(doneAllButton);
    await tester.pumpAndSettle();

    // Tap first notification item to test navigation flow
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    // If notification navigated to MangaDetailPage (mangaId > 0)
    final isMangaDetail = find.text('Introduction').evaluate().isNotEmpty;
    if (isMangaDetail) {
      expect(find.text('Chapters'), findsOneWidget);
      // Go back to NotificationPage
      await tester.pageBack();
      await tester.pumpAndSettle();
      
      // Ensure we are back on Notification Page
      await _waitUntil(
        tester,
        () => find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Thong bao'),
        ).evaluate().isNotEmpty,
        reason: 'Should return to notification page.',
      );
    }
  }
}

Future<void> _goBackToHome(WidgetTester tester) async {
  await tester.pageBack();
  await tester.pumpAndSettle();

  await _waitUntil(
    tester,
    () => find.text('Last Updates').evaluate().isNotEmpty,
    reason: 'Should navigate back to Home page.',
  );
}

Future<void> _waitForAppSettled(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () => find.byType(CircularProgressIndicator).evaluate().isEmpty,
    reason: 'Initial loading indicators should finish.',
  );
}

Future<void> _waitUntil(
  WidgetTester tester,
  bool Function() condition, {
  required String reason,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (condition()) {
      return;
    }
  }

  fail(reason);
}
