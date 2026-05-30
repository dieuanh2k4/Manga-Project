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

  testWidgets('auth page validation and login flows', (tester) async {
    await _launchApp(tester);

    // 1. Verify auth page UI
    await _verifyAuthPageUI(tester);

    // 2. Login with wrong password
    await _loginWithWrongPassword(tester);

    // 3. Switch to REGISTER tab and verify fields
    await _switchToRegisterTab(tester);
    await _verifyRegisterFields(tester);

    // 4. Switch back to LOGIN tab
    await _switchToLoginTab(tester);
    await _verifyLoginFields(tester);

    // 5. Login with correct credentials
    await _loginWithCorrectCredentials(tester);

    // 6. Verify Home page
    await _verifyHomePage(tester);
  });
}

Future<void> _launchApp(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 2));
  await _waitForAppSettled(tester);
}

Future<void> _verifyAuthPageUI(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () => find.text('LOGIN').evaluate().isNotEmpty,
    reason: 'Auth page should show LOGIN tab.',
  );

  expect(find.text('Welcome to MangaMinus'), findsOneWidget);
  expect(find.text('LOGIN'), findsOneWidget);
  expect(find.text('REGISTER'), findsOneWidget);
}

Future<void> _loginWithWrongPassword(WidgetTester tester) async {
  if (find.text('LOGIN').evaluate().isEmpty) {
    return;
  }

  final textFields = find.byType(TextField);
  expect(textFields, findsAtLeastNWidgets(2));

  await tester.enterText(textFields.at(0), _username);
  await tester.enterText(textFields.at(1), 'wrong-password-123');
  await tester.tap(find.text('LOG IN'));
  await tester.pumpAndSettle();

  // Should remain on LOGIN page
  await _waitUntil(
    tester,
    () => find.text('LOGIN').evaluate().isNotEmpty,
    reason: 'Auth page should remain after wrong login.',
  );

  // Verify error message appears (red color text)
  final errorText = find.byWidgetPredicate(
    (widget) =>
        widget is Text && widget.style?.color == const Color(0xFF9B1B1B),
  );
  expect(errorText, findsWidgets);
}

Future<void> _switchToRegisterTab(WidgetTester tester) async {
  await tester.tap(find.text('REGISTER'));
  await tester.pumpAndSettle();
}

Future<void> _verifyRegisterFields(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () => find.text('Full Name').evaluate().isNotEmpty,
    reason: 'Register tab should show Full Name field.',
  );

  expect(find.text('Full Name'), findsOneWidget);
  expect(find.text('Email'), findsOneWidget);
  expect(find.text('Phone'), findsOneWidget);
  expect(find.text('Gender'), findsOneWidget);
}

Future<void> _switchToLoginTab(WidgetTester tester) async {
  await tester.tap(find.text('LOGIN'));
  await tester.pumpAndSettle();
}

Future<void> _verifyLoginFields(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () => find.text('LOG IN').evaluate().isNotEmpty,
    reason: 'Login tab should show LOG IN button.',
  );

  // Username and Password labels should be visible in login tab
  expect(find.text('Username'), findsWidgets);
  expect(find.text('Password'), findsWidgets);
}

Future<void> _loginWithCorrectCredentials(WidgetTester tester) async {
  final textFields = find.byType(TextField);
  expect(textFields, findsAtLeastNWidgets(2));

  // Clear old values and enter correct credentials
  await tester.enterText(textFields.at(0), _username);
  await tester.enterText(textFields.at(1), _password);
  await tester.tap(find.text('LOG IN'));
  await tester.pumpAndSettle();

  await _waitUntil(
    tester,
    () => find.text('Last Updates').evaluate().isNotEmpty,
    reason: 'Home page should be visible after successful login.',
  );
}

Future<void> _verifyHomePage(WidgetTester tester) async {
  expect(find.byType(BottomNavigationBar), findsOneWidget);

  await _waitUntil(
    tester,
    () =>
        find.text('Last Updates').evaluate().isNotEmpty ||
        find.text('Most Viewed').evaluate().isNotEmpty,
    reason: 'Home page should show manga sections.',
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
