import 'package:app_manga/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

String _e2eKeyPart(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

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
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_session');

  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 2));
  await _waitForAppSettled(tester);
}

Future<void> _loginIfNeeded(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        find.byKey(const Key('home_page')).evaluate().isNotEmpty ||
        find.byKey(const Key('login_submit_button')).evaluate().isNotEmpty,
    reason: 'App should show either the seeded home session or login form.',
    failureDetails: _visibleStateForFailure,
  );

  if (find.byKey(const Key('home_page')).evaluate().isNotEmpty) {
    return;
  }

  await tester.enterText(
    find.byKey(const Key('login_username_field')),
    _username,
  );
  await tester.enterText(
    find.byKey(const Key('login_password_field')),
    _password,
  );
  await tester.tap(find.byKey(const Key('login_submit_button')));
  await tester.pump();

  await _waitUntil(
    tester,
    () => find.byKey(const Key('home_page')).evaluate().isNotEmpty,
    reason: 'Home page should be visible after login.',
    failureDetails: _visibleStateForFailure,
  );
}

Future<void> _expectHome(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        find.byKey(const Key('home_page')).evaluate().isNotEmpty &&
        (find.text('Last Updates').evaluate().isNotEmpty ||
            find.text('Most Viewed').evaluate().isNotEmpty),
    reason: 'Home page should show manga sections.',
    failureDetails: _homeStateForFailure,
  );
  expect(find.byType(BottomNavigationBar), findsOneWidget);
}

String _homeStateForFailure() {
  if (find.byKey(const Key('home_loading')).evaluate().isNotEmpty) {
    return 'Home is still loading manga.';
  }
  if (find.byKey(const Key('home_error')).evaluate().isNotEmpty) {
    return 'Home API error: ${_visibleText()}';
  }
  if (find.byKey(const Key('home_empty')).evaluate().isNotEmpty) {
    return 'Home loaded but returned an empty manga list.';
  }
  if (find.byKey(const Key('login_submit_button')).evaluate().isNotEmpty) {
    return 'App is still on the login page.';
  }
  return _visibleStateForFailure();
}

String _visibleStateForFailure() {
  return 'Current visible text: ${_visibleText()}';
}

String _visibleText() {
  final values = find
      .byType(Text)
      .evaluate()
      .map((element) => element.widget)
      .whereType<Text>()
      .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
      .where((text) => text.trim().isNotEmpty)
      .take(12)
      .join(' | ');

  return values.isEmpty ? '<none>' : values;
}

Future<void> _expectMangaDetail(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        find.byKey(const Key('manga_detail_page')).evaluate().isNotEmpty &&
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
    () => find
        .byKey(Key('manga_chapter_${_e2eKeyPart(_chapterTitle)}'))
        .evaluate()
        .isNotEmpty,
    reason: 'Seeded manga detail should contain $_chapterTitle.',
  );

  final chapterTile = find.byKey(
    Key('manga_chapter_${_e2eKeyPart(_chapterTitle)}'),
  );
  expect(chapterTile, findsOneWidget);

  await tester.tap(chapterTile);
  await tester.pumpAndSettle();
}

Future<void> _expectReader(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        find.byKey(const Key('manga_reader_page')).evaluate().isNotEmpty &&
        (find
                .byKey(const Key('manga_reader_horizontal_pages'))
                .evaluate()
                .isNotEmpty ||
            find
                .byKey(const Key('manga_reader_vertical_pages'))
                .evaluate()
                .isNotEmpty),
    reason: 'Reader should show seeded chapter pages.',
  );
}

Future<void> _goBackToMangaDetail(WidgetTester tester) async {
  await tester.pageBack();
  await tester.pumpAndSettle();
  await _expectMangaDetail(tester);
}

Future<void> _openSearch(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('home_nav_search')));
  await tester.pumpAndSettle();
}

Future<void> _expectSearch(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        find.byKey(const Key('search_page')).evaluate().isNotEmpty &&
        find.text('POPULAR').evaluate().isNotEmpty &&
        find.text('LAST UPDATES').evaluate().isNotEmpty &&
        find.text('DIRECTORY').evaluate().isNotEmpty,
    reason: 'Search page should show search tabs.',
  );
}

Future<void> _openSeededSearchResult(WidgetTester tester) async {
  if (_searchQuery.trim().isNotEmpty) {
    await tester.enterText(
      find.byKey(const Key('manga_search_field')),
      _searchQuery,
    );
  }

  final resultKey = Key('manga_search_result_${_e2eKeyPart(_mangaTitle)}');
  await _waitUntil(
    tester,
    () => find.byKey(resultKey).evaluate().isNotEmpty,
    reason: 'Search page should contain seeded manga $_mangaTitle.',
  );

  final result = find.byKey(resultKey);
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
  await tester.tap(find.byKey(const Key('search_nav_home')));
  await tester.pumpAndSettle();
  await _expectHome(tester);
}

Future<void> _openLibrary(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('home_nav_library')));
  await tester.pumpAndSettle();
}

Future<void> _expectLibrary(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        find.byKey(const Key('library_page')).evaluate().isNotEmpty &&
        find.textContaining('Library -').evaluate().isNotEmpty &&
        find.text('Your Library').evaluate().isNotEmpty &&
        find.text('History').evaluate().isNotEmpty &&
        find.text('Downloads').evaluate().isNotEmpty,
    reason: 'Library page should show all library tabs.',
    failureDetails: _libraryStateForFailure,
  );

  await _waitUntil(
    tester,
    () => find
        .byKey(Key('library_manga_${_e2eKeyPart(_mangaTitle)}'))
        .evaluate()
        .isNotEmpty,
    reason: 'Library should contain seeded manga $_mangaTitle.',
    failureDetails: _libraryStateForFailure,
  );
}

String _libraryStateForFailure() {
  if (find.byKey(const Key('library_loading')).evaluate().isNotEmpty) {
    return 'Library is still loading.';
  }
  if (find.byKey(const Key('library_page')).evaluate().isEmpty) {
    return 'App is not on Library page. ${_visibleStateForFailure()}';
  }
  return 'Library visible text: ${_visibleText()}';
}

Future<void> _openMe(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('library_nav_me')));
  await tester.pumpAndSettle();
}

Future<void> _expectMe(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        find.byKey(const Key('me_page')).evaluate().isNotEmpty &&
        find.text('E2E Reader').evaluate().isNotEmpty &&
        find.text(_username).evaluate().isNotEmpty &&
        find.text('Premium').evaluate().isNotEmpty &&
        find.text('Username').evaluate().isNotEmpty &&
        find.byKey(const Key('me_logout_button')).evaluate().isNotEmpty,
    reason: 'Me page should show the seeded reader profile.',
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
