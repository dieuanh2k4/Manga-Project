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

  testWidgets('VIP purchase section e2e test', (tester) async {
    await _launchApp(tester);
    await _loginIfNeeded(tester);

    // 1. Navigate to Me page
    await _openMe(tester);

    // 2. Verify profile details
    await _verifyProfileDetails(tester);

    // 3. Verify VIP section UI elements
    await _verifyVipSectionUI(tester);

    // 4. Test VIP refresh action
    await _testVipRefresh(tester);

    // 5. Test AppBar Profile refresh action
    await _testAppBarRefresh(tester);

    // 6. Navigate back to Home
    await _openHome(tester);
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

Future<void> _openMe(WidgetTester tester) async {
  final meTab = find.text('Me').last;
  await tester.tap(meTab);
  await tester.pumpAndSettle();

  await _waitUntil(
    tester,
    () => find.text('Me').evaluate().isNotEmpty,
    reason: 'Me page should be visible.',
  );
}

Future<void> _verifyProfileDetails(WidgetTester tester) async {
  // Username label is always present
  expect(find.text('Username'), findsOneWidget);
  
  // Verify standard / premium status badge exists
  final standardBadge = find.text('Standard');
  final premiumBadge = find.text('Premium');
  expect(standardBadge.evaluate().isNotEmpty || premiumBadge.evaluate().isNotEmpty, true);
}

Future<void> _verifyVipSectionUI(WidgetTester tester) async {
  // Verify "Goi VIP" title
  expect(find.text('Goi VIP'), findsOneWidget);

  // Wait until VIP packages are loaded and visible
  await _waitUntil(
    tester,
    () => find.textContaining('Trang thai:').evaluate().isNotEmpty,
    reason: 'VIP section should load active entitlements status.',
  );

  // Check state text
  expect(find.textContaining('Trang thai:'), findsOneWidget);
}

Future<void> _testVipRefresh(WidgetTester tester) async {
  // Find refresh button inside VIP row
  final vipRow = find.ancestor(
    of: find.text('Goi VIP'),
    matching: find.byType(Row),
  ).first;
  
  final vipRefreshButton = find.descendant(
    of: vipRow,
    matching: find.byIcon(Icons.refresh),
  );

  expect(vipRefreshButton, findsOneWidget);
  await tester.tap(vipRefreshButton);
  await tester.pumpAndSettle();

  // Wait for load to finish
  await _waitUntil(
    tester,
    () => find.textContaining('Trang thai:').evaluate().isNotEmpty,
    reason: 'VIP section should complete refreshing entitlements.',
  );
}

Future<void> _testAppBarRefresh(WidgetTester tester) async {
  // Find refresh button in AppBar
  final appBarRefreshButton = find.descendant(
    of: find.byType(AppBar),
    matching: find.byIcon(Icons.refresh),
  );

  expect(appBarRefreshButton, findsOneWidget);
  await tester.tap(appBarRefreshButton);
  await tester.pumpAndSettle();
  
  await _waitForAppSettled(tester);
}

Future<void> _openHome(WidgetTester tester) async {
  final homeTab = find.text('Home').last;
  await tester.tap(homeTab);
  await tester.pumpAndSettle();

  await _waitUntil(
    tester,
    () => find.text('Last Updates').evaluate().isNotEmpty,
    reason: 'Home page should be visible.',
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
