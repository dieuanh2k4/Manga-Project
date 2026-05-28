import 'package:app_manga/features/manga/presentation/widgets/manga_card.dart';
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

  testWidgets('library follow, unfollow, tabs, and history flows',
      (tester) async {
    await _launchApp(tester);
    await _loginIfNeeded(tester);

    // 1. Verify home page
    await _expectHome(tester);

    // 2. Open first manga detail
    await _openFirstMangaFromHome(tester);
    await _expectMangaDetail(tester);

    // 3. Follow manga
    await _followManga(tester);

    // 4. Go back to home
    await _goBackToHome(tester);

    // 5. Navigate to Library
    await _openLibrary(tester);

    // 6. Verify Library tabs
    await _verifyLibraryTabs(tester);

    // 7. Search in library
    await _searchInLibrary(tester);

    // 8. Tap History tab
    await _openHistoryTab(tester);

    // 9. Toggle history grouping
    await _toggleHistoryGrouping(tester);

    // 10. Go back to home and unfollow
    await _goToHomeFromLibrary(tester);
    await _openFirstMangaFromHome(tester);
    await _expectMangaDetail(tester);
    await _unfollowManga(tester);

    // 11. Go back to home
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

Future<void> _expectHome(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        find.text('Last Updates').evaluate().isNotEmpty ||
        find.text('Most Viewed').evaluate().isNotEmpty,
    reason: 'Home page should show manga sections.',
  );
}

Future<void> _openFirstMangaFromHome(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () => find.byType(MangaCard).evaluate().isNotEmpty,
    reason: 'Home page should contain at least one manga card.',
  );
  await tester.tap(find.byType(MangaCard).first);
  await tester.pumpAndSettle();
}

Future<void> _expectMangaDetail(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        find.text('Introduction').evaluate().isNotEmpty &&
        find.text('Chapters').evaluate().isNotEmpty,
    reason: 'Manga detail should show Introduction and Chapters.',
  );
}

Future<void> _followManga(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        find.text('FOLLOW').evaluate().isNotEmpty ||
        find.text('FOLLOWING').evaluate().isNotEmpty,
    reason: 'Follow button should be visible.',
  );

  // If already following, skip
  if (find.text('FOLLOWING').evaluate().isNotEmpty) {
    return;
  }

  await tester.tap(find.text('FOLLOW').first);
  await tester.pumpAndSettle();

  await _waitUntil(
    tester,
    () => find.text('FOLLOWING').evaluate().isNotEmpty,
    reason: 'Follow state should change to FOLLOWING.',
  );

  // Verify snackbar
  await _waitUntil(
    tester,
    () => find.text('Da them vao thu vien.').evaluate().isNotEmpty,
    reason: 'Snackbar should show follow success message.',
    timeout: const Duration(seconds: 5),
  );
}

Future<void> _unfollowManga(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        find.text('FOLLOW').evaluate().isNotEmpty ||
        find.text('FOLLOWING').evaluate().isNotEmpty,
    reason: 'Follow button should be visible.',
  );

  // If not following, skip
  if (find.text('FOLLOW').evaluate().isNotEmpty &&
      find.text('FOLLOWING').evaluate().isEmpty) {
    return;
  }

  await tester.tap(find.text('FOLLOWING').first);
  await tester.pumpAndSettle();

  await _waitUntil(
    tester,
    () => find.text('FOLLOW').evaluate().isNotEmpty,
    reason: 'Follow state should change back to FOLLOW.',
  );
}

Future<void> _goBackToHome(WidgetTester tester) async {
  await tester.pageBack();
  await tester.pumpAndSettle();
  await _expectHome(tester);
}

Future<void> _openLibrary(WidgetTester tester) async {
  await tester.tap(find.text('Library').last);
  await tester.pumpAndSettle();
}

Future<void> _verifyLibraryTabs(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        find.textContaining('Library -').evaluate().isNotEmpty &&
        find.text('Your Library').evaluate().isNotEmpty &&
        find.text('History').evaluate().isNotEmpty &&
        find.text('Downloads').evaluate().isNotEmpty,
    reason: 'Library page should show all tabs.',
  );
}

Future<void> _searchInLibrary(WidgetTester tester) async {
  final textFields = find.byType(TextField);
  if (textFields.evaluate().isEmpty) {
    return;
  }

  await tester.enterText(textFields.first, 'one');
  await tester.pumpAndSettle(const Duration(milliseconds: 500));

  // Clear search
  await tester.enterText(textFields.first, '');
  await tester.pumpAndSettle(const Duration(milliseconds: 300));
}

Future<void> _openHistoryTab(WidgetTester tester) async {
  if (find.text('History').evaluate().isEmpty) {
    return;
  }

  await tester.tap(find.text('History').first);
  await tester.pumpAndSettle();
}

Future<void> _toggleHistoryGrouping(WidgetTester tester) async {
  final switchFinder = find.byType(Switch);
  if (switchFinder.evaluate().isEmpty) {
    return;
  }

  // Toggle off
  await tester.tap(switchFinder.first);
  await tester.pumpAndSettle();

  // Toggle on
  await tester.tap(switchFinder.first);
  await tester.pumpAndSettle();
}

Future<void> _goToHomeFromLibrary(WidgetTester tester) async {
  await tester.tap(find.text('Home').last);
  await tester.pumpAndSettle();
  await _expectHome(tester);
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

