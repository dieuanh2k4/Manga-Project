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
    () => find.byKey(const Key('auth_page')).evaluate().isNotEmpty,
    reason: 'Auth page should show LOGIN tab.',
  );

  expect(find.byKey(const Key('auth_login_tab')), findsOneWidget);
  expect(find.byKey(const Key('auth_register_tab')), findsOneWidget);
}

Future<void> _loginWithWrongPassword(WidgetTester tester) async {
  if (find.byKey(const Key('login_submit_button')).evaluate().isEmpty) {
    return;
  }

  await tester.enterText(
    find.byKey(const Key('login_username_field')),
    _username,
  );
  await tester.enterText(
    find.byKey(const Key('login_password_field')),
    'wrong-password-123',
  );
  await tester.tap(find.byKey(const Key('login_submit_button')));
  await tester.pumpAndSettle();

  // Should remain on LOGIN page
  await _waitUntil(
    tester,
    () => find.byKey(const Key('auth_page')).evaluate().isNotEmpty,
    reason: 'Auth page should remain after wrong login.',
    failureDetails: _visibleStateForFailure,
  );

  // Verify error message appears (red color text)
  final errorText = find.byWidgetPredicate(
    (widget) =>
        widget is Text && widget.style?.color == const Color(0xFF9B1B1B),
  );
  expect(errorText, findsWidgets);
}

Future<void> _switchToRegisterTab(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('auth_register_tab')));
  await tester.pumpAndSettle();
}

Future<void> _verifyRegisterFields(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        find.byKey(const Key('register_full_name_field')).evaluate().isNotEmpty,
    reason: 'Register tab should show Full Name field.',
  );

  expect(find.byKey(const Key('register_email_field')), findsOneWidget);
  expect(find.byKey(const Key('register_phone_field')), findsOneWidget);
  expect(find.byKey(const Key('register_gender_field')), findsOneWidget);
}

Future<void> _switchToLoginTab(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('auth_login_tab')));
  await tester.pumpAndSettle();
}

Future<void> _verifyLoginFields(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () => find.byKey(const Key('login_submit_button')).evaluate().isNotEmpty,
    reason: 'Login tab should show LOG IN button.',
  );

  // Username and Password labels should be visible in login tab
  expect(find.byKey(const Key('login_username_field')), findsOneWidget);
  expect(find.byKey(const Key('login_password_field')), findsOneWidget);
}

Future<void> _loginWithCorrectCredentials(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('login_username_field')),
    _username,
  );
  await tester.enterText(
    find.byKey(const Key('login_password_field')),
    _password,
  );
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();

  final errorBeforeSubmit = _visibleAuthErrorText();
  final submitButton = find.byKey(const Key('login_submit_button'));
  await tester.ensureVisible(submitButton);
  await tester.tap(submitButton);
  await tester.pump();

  await _waitUntil(
    tester,
    () =>
        find.byKey(const Key('home_page')).evaluate().isNotEmpty ||
        (_visibleAuthErrorText().isNotEmpty &&
            _visibleAuthErrorText() != errorBeforeSubmit),
    reason: 'Home page should be visible after successful login.',
    failureDetails: _homeStateForFailure,
  );

  final authError = _visibleAuthErrorText();
  if (authError.isNotEmpty) {
    fail('Login failed before reaching Home. Auth error: $authError');
  }
}

Future<void> _verifyHomePage(WidgetTester tester) async {
  expect(find.byType(BottomNavigationBar), findsOneWidget);

  await _waitUntil(
    tester,
    () => find.byKey(const Key('home_page')).evaluate().isNotEmpty,
    reason: 'Home page should show manga sections.',
    failureDetails: _homeStateForFailure,
  );
}

String _homeStateForFailure() {
  if (find.byKey(const Key('home_loading')).evaluate().isNotEmpty) {
    return 'Home is still loading manga.';
  }
  if (find.byKey(const Key('home_error')).evaluate().isNotEmpty) {
    return 'Home API error. ${_visibleStateForFailure()}';
  }
  if (find.byKey(const Key('home_empty')).evaluate().isNotEmpty) {
    return 'Home loaded but returned an empty manga list.';
  }
  if (find.byKey(const Key('auth_page')).evaluate().isNotEmpty) {
    return 'App is on auth page. Login may have failed. ${_visibleStateForFailure()}';
  }
  return _visibleStateForFailure();
}

String _visibleStateForFailure() {
  final values = find
      .byType(Text)
      .evaluate()
      .map((element) => element.widget)
      .whereType<Text>()
      .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
      .where((text) => text.trim().isNotEmpty)
      .take(16)
      .join(' | ');

  return 'Current visible text: ${values.isEmpty ? '<none>' : values}';
}

String _visibleAuthErrorText() {
  final values = find
      .byWidgetPredicate(
        (widget) =>
            widget is Text && widget.style?.color == const Color(0xFF9B1B1B),
      )
      .evaluate()
      .map((element) => element.widget)
      .whereType<Text>()
      .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
      .where((text) => text.trim().isNotEmpty)
      .join(' | ');

  return values;
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
  String Function()? failureDetails,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (condition()) {
      return;
    }
  }

  final details = failureDetails?.call();
  fail(details == null || details.isEmpty ? reason : '$reason $details');
}
