import 'package:app_manga/features/manga/presentation/widgets/manga_card.dart';
import 'package:app_manga/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

const _username = String.fromEnvironment(
  'APP_MANGA_E2E_USERNAME',
  defaultValue: 'reader01',
);
const _password = String.fromEnvironment(
  'APP_MANGA_E2E_PASSWORD',
  defaultValue: 'reader123',
);
const _searchQuery = String.fromEnvironment('APP_MANGA_E2E_SEARCH_QUERY');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('user can use the main app manga journeys', (tester) async {
    await _launchApp(tester);
    await _loginIfNeeded(tester);

    await _expectHome(tester);
    await _openFirstMangaFromHome(tester);
    await _expectMangaDetail(tester);
    await _openFirstChapter(tester);
    await _expectReader(tester);

    await _goBackToMangaDetail(tester);
    await _goBackToHome(tester);

    await _openSearch(tester);
    await _expectSearch(tester);
    await _openFirstSearchResult(tester);
    await _expectMangaDetail(tester);

    await _goBackToSearch(tester);
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
    reason: 'Manga detail should show introduction and chapters.',
  );
}

Future<void> _openFirstChapter(WidgetTester tester) async {
  await _scrollUntilVisible(tester, find.text('Chapters'));

  await _waitUntil(
    tester,
    () => find.byType(ListTile).evaluate().isNotEmpty,
    reason: 'Manga detail should contain at least one chapter.',
  );

  await tester.tap(find.byType(ListTile).first);
  await tester.pumpAndSettle();
}

Future<void> _expectReader(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        find.byType(PageView).evaluate().isNotEmpty ||
        find.byType(ScrollablePositionedList).evaluate().isNotEmpty ||
        find.text('Chuong nay chua co noi dung').evaluate().isNotEmpty,
    reason: 'Reader should show pages or an empty chapter message.',
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

Future<void> _openFirstSearchResult(WidgetTester tester) async {
  if (_searchQuery.trim().isNotEmpty) {
    await tester.enterText(find.byType(TextField).first, _searchQuery);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  await _waitUntil(
    tester,
    () => find.byType(InkWell).evaluate().isNotEmpty,
    reason: 'Search page should contain at least one result item.',
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

Future<void> _goBackToSearch(WidgetTester tester) async {
  await tester.pageBack();
  await tester.pumpAndSettle();
  await _expectSearch(tester);
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
