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

  testWidgets('search page tabs, text search, and directory filters',
      (tester) async {
    await _launchApp(tester);
    await _loginIfNeeded(tester);

    // 1. Navigate to Search tab
    await _openSearch(tester);

    // 2. Verify search page tabs
    await _verifySearchTabs(tester);

    // 3. Verify POPULAR tab has items
    await _verifyPopularTab(tester);

    // 4. Tap LAST UPDATES tab
    await _tapLastUpdatesTab(tester);
    await _verifyLastUpdatesTab(tester);

    // 5. Enter text search
    await _performTextSearch(tester);

    // 6. Go to DIRECTORY tab
    await _tapDirectoryTab(tester);
    await _verifyDirectoryTab(tester);

    // 7. Tap Complete status filter
    await _tapStatusFilter(tester);

    // 8. Toggle a genre if available
    await _toggleFirstGenreIfAny(tester);

    // 9. Navigate from search result
    await _tapPopularTab(tester);
    await _openFirstSearchResult(tester);
    await _verifyMangaDetailPage(tester);

    // 10. Go back to search
    await _goBackToSearch(tester);
  });
}

Future<void> _launchApp(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 2));
  await _waitForAppSettled(tester);
}

Future<void> _loginIfNeeded(WidgetTester tester) async {
  if (find.byKey(const Key('login_submit_button')).evaluate().isEmpty) {
    return;
  }

  final textFields = find.byType(TextField);
  expect(textFields, findsAtLeastNWidgets(2));

  await tester.enterText(textFields.at(0), _username);
  await tester.enterText(textFields.at(1), _password);
  await tester.tap(find.byKey(const Key('login_submit_button')));
  await tester.pumpAndSettle();

  await _waitUntil(
    tester,
    () => find.byKey(const Key('home_page')).evaluate().isNotEmpty,
    reason: 'Home page should be visible after login.',
  );
}

Future<void> _openSearch(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('home_nav_search')));
  await tester.pumpAndSettle();
}

Future<void> _verifySearchTabs(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        find.text('POPULAR').evaluate().isNotEmpty &&
        find.text('LAST UPDATES').evaluate().isNotEmpty &&
        find.text('DIRECTORY').evaluate().isNotEmpty,
    reason: 'Search page should show all three tabs.',
  );
}

Future<void> _verifyPopularTab(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () => find.byType(InkWell).evaluate().isNotEmpty,
    reason: 'POPULAR tab should contain manga items.',
  );
}

Future<void> _tapLastUpdatesTab(WidgetTester tester) async {
  await tester.tap(find.text('LAST UPDATES'));
  await tester.pumpAndSettle();
}

Future<void> _verifyLastUpdatesTab(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () => find.byType(InkWell).evaluate().isNotEmpty,
    reason: 'LAST UPDATES tab should contain manga items.',
  );
}

Future<void> _performTextSearch(WidgetTester tester) async {
  final searchField = find.byType(TextField);
  if (searchField.evaluate().isEmpty) {
    return;
  }

  await tester.enterText(searchField.first, 'one');
  await tester.pumpAndSettle(const Duration(milliseconds: 500));

  // Search should either show results or indicate no data
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _tapDirectoryTab(WidgetTester tester) async {
  // Clear search first
  final searchField = find.byType(TextField);
  if (searchField.evaluate().isNotEmpty) {
    await tester.enterText(searchField.first, '');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
  }

  await tester.tap(find.text('DIRECTORY'));
  await tester.pumpAndSettle();
}

Future<void> _verifyDirectoryTab(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        find.text('Status').evaluate().isNotEmpty &&
        find.text('Genres').evaluate().isNotEmpty,
    reason: 'DIRECTORY tab should show Status and Genres sections.',
  );

  // Verify status filters
  expect(find.text('Continuous'), findsOneWidget);
  expect(find.text('Complete'), findsOneWidget);
  expect(find.text('New'), findsOneWidget);
}

Future<void> _tapStatusFilter(WidgetTester tester) async {
  if (find.text('Complete').evaluate().isNotEmpty) {
    await tester.tap(find.text('Complete').first);
    await tester.pumpAndSettle();
  }
}

Future<void> _toggleFirstGenreIfAny(WidgetTester tester) async {
  final candidates = find.byWidgetPredicate(
    (widget) => widget is GestureDetector && widget.child is Text,
  );

  for (final element in candidates.evaluate()) {
    final widget = element.widget as GestureDetector;
    final child = widget.child;
    if (child is! Text) {
      continue;
    }

    final label = child.data ?? '';
    if (label.isEmpty) {
      continue;
    }

    // Skip status filters and section headers
    if (label == 'Continuous' || label == 'Complete' || label == 'New') {
      continue;
    }

    await tester.tap(find.text(label).first);
    await tester.pumpAndSettle();
    break;
  }
}

Future<void> _tapPopularTab(WidgetTester tester) async {
  await tester.tap(find.text('POPULAR'));
  await tester.pumpAndSettle();
}

Future<void> _openFirstSearchResult(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () => find.byType(InkWell).evaluate().isNotEmpty,
    reason: 'Should have at least one manga item to tap.',
  );

  final result = find
      .byWidgetPredicate(
        (widget) =>
            widget is InkWell &&
            widget.onTap != null &&
            widget.child is Container,
      )
      .first;

  await tester.tap(result);
  await tester.pumpAndSettle();
}

Future<void> _verifyMangaDetailPage(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        find.text('Introduction').evaluate().isNotEmpty &&
        find.text('Chapters').evaluate().isNotEmpty,
    reason: 'Manga detail should show Introduction and Chapters.',
  );
}

Future<void> _goBackToSearch(WidgetTester tester) async {
  await tester.pageBack();
  await tester.pumpAndSettle();
  await _verifySearchTabs(tester);
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
