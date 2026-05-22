import 'package:app_manga/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

const _username = String.fromEnvironment(
  'APP_MANGA_E2E_USERNAME',
  defaultValue: 'e2e_reader',
);
const _password = String.fromEnvironment(
  'APP_MANGA_E2E_PASSWORD',
  defaultValue: 'E2e@123456',
);
const _mangaTitle = String.fromEnvironment(
  'APP_MANGA_E2E_MANGA_TITLE',
  defaultValue: 'E2E Readable Manga',
);
const _chapterTitle = String.fromEnvironment(
  'APP_MANGA_E2E_CHAPTER_TITLE',
  defaultValue: 'E2E Chapter 1',
);
const _searchQuery = String.fromEnvironment(
  'APP_MANGA_E2E_SEARCH_QUERY',
  defaultValue: 'E2E Readable Manga',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('user can use the main app manga journeys', (tester) async {
    await _launchApp(tester);
    await _loginIfNeeded(tester);

    await _expectHome(tester);
    await _openSearch(tester);
    await _expectSearch(tester);
    await _openSeededSearchResult(tester);
    await _expectMangaDetail(tester);
    await _openSeededChapter(tester);
    await _expectReader(tester);

    await _goBackToMangaDetail(tester);
    await _goBackToSearch(tester);
    await _openHome(tester);
    await _openLibrary(tester);
    await _expectLibrary(tester);

    await _openMe(tester);
    await _expectMe(tester);
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
  expect(find.byType(BottomNavigationBar), findsOneWidget);
}

Future<void> _expectMangaDetail(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        find.text('Introduction').evaluate().isNotEmpty &&
        find.text('Chapters').evaluate().isNotEmpty,
    reason: 'Manga detail should show introduction and chapters.',
  );
  expect(find.text(_mangaTitle), findsWidgets);
}

Future<void> _openSeededChapter(WidgetTester tester) async {
  await _scrollUntilVisible(tester, find.text('Chapters'));

  await _waitUntil(
    tester,
    () => find.text(_chapterTitle).evaluate().isNotEmpty,
    reason: 'Seeded manga detail should contain $_chapterTitle.',
  );

  final chapterTile = find.ancestor(
    of: find.text(_chapterTitle),
    matching: find.byType(ListTile),
  );
  expect(chapterTile, findsOneWidget);

  await tester.tap(chapterTile);
  await tester.pumpAndSettle();
}

Future<void> _expectReader(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        find.byType(PageView).evaluate().isNotEmpty ||
        find.byType(ScrollablePositionedList).evaluate().isNotEmpty,
    reason: 'Reader should show seeded chapter pages.',
  );
}

Future<void> _goBackToMangaDetail(WidgetTester tester) async {
  await tester.pageBack();
  await tester.pumpAndSettle();
  await _expectMangaDetail(tester);
}

Future<void> _goBackToHome(WidgetTester tester) async {
  await tester.pageBack();
  await tester.pumpAndSettle();
  await _expectHome(tester);
}

Future<void> _openSearch(WidgetTester tester) async {
  await tester.tap(find.text('Search').last);
  await tester.pumpAndSettle();
}

Future<void> _expectSearch(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        find.text('POPULAR').evaluate().isNotEmpty &&
        find.text('LAST UPDATES').evaluate().isNotEmpty &&
        find.text('DIRECTORY').evaluate().isNotEmpty,
    reason: 'Search page should show search tabs.',
  );
}

Future<void> _openSeededSearchResult(WidgetTester tester) async {
  if (_searchQuery.trim().isNotEmpty) {
    await tester.enterText(find.byType(TextField).first, _searchQuery);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  await _waitUntil(
    tester,
    () => find.text(_mangaTitle).evaluate().isNotEmpty,
    reason: 'Search page should contain seeded manga $_mangaTitle.',
  );

  final result = find.ancestor(
    of: find.text(_mangaTitle),
    matching: find.byType(InkWell),
  );
  expect(result, findsOneWidget);

  await tester.tap(result);
  await tester.pumpAndSettle();
}

Future<void> _goBackToSearch(WidgetTester tester) async {
  await tester.pageBack();
  await tester.pumpAndSettle();
  await _expectSearch(tester);
}

Future<void> _openHome(WidgetTester tester) async {
  await tester.tap(find.text('Home').last);
  await tester.pumpAndSettle();
  await _expectHome(tester);
}

Future<void> _openLibrary(WidgetTester tester) async {
  await tester.tap(find.text('Library').last);
  await tester.pumpAndSettle();
}

Future<void> _expectLibrary(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        find.textContaining('Library -').evaluate().isNotEmpty &&
        find.text('Your Library').evaluate().isNotEmpty &&
        find.text('History').evaluate().isNotEmpty &&
        find.text('Downloads').evaluate().isNotEmpty,
    reason: 'Library page should show all library tabs.',
  );
}

Future<void> _openMe(WidgetTester tester) async {
  await tester.tap(find.text('Me').last);
  await tester.pumpAndSettle();
}

Future<void> _expectMe(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        find.text('Me').evaluate().isNotEmpty &&
        find.text('Username').evaluate().isNotEmpty &&
        find.text('Dang xuat').evaluate().isNotEmpty,
    reason: 'Me page should show the logged-in user profile.',
  );
}

Future<void> _scrollUntilVisible(
  WidgetTester tester,
  Finder finder, {
  Finder? scrollable,
}) async {
  if (finder.evaluate().isNotEmpty) {
    return;
  }

  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: scrollable ?? find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
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
