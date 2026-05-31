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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('library, reader navigation, and logout flows', (tester) async {
    await _launchApp(tester);
    await _loginIfNeeded(tester);

    await _openLibrary(tester);
    await _verifyLibraryTabs(tester);
    await _searchInLibrary(tester);
    await _toggleHistoryGrouping(tester);

    await _openHome(tester);
    await _openFirstMangaFromHome(tester);
    await _openFirstChapter(tester);
    await _expectReader(tester);
    await _tryNextPreviousChapter(tester);

    await _openMe(tester);
    await _logout(tester);
    await _expectAuthPage(tester);
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
}

Future<void> _toggleHistoryGrouping(WidgetTester tester) async {
  if (find.text('History').evaluate().isEmpty) {
    return;
  }

  await tester.tap(find.text('History').first);
  await tester.pumpAndSettle();

  final switchFinder = find.byType(Switch);
  if (switchFinder.evaluate().isEmpty) {
    return;
  }

  await tester.tap(switchFinder.first);
  await tester.pumpAndSettle();
  await tester.tap(switchFinder.first);
  await tester.pumpAndSettle();
}

Future<void> _openHome(WidgetTester tester) async {
  await tester.tap(find.text('Home').last);
  await tester.pumpAndSettle();
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

Future<void> _openFirstChapter(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () => find.text('Chapters').evaluate().isNotEmpty,
    reason: 'Manga detail should show chapters.',
  );

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

Future<void> _tryNextPreviousChapter(WidgetTester tester) async {
  if (find.byIcon(Icons.tune).evaluate().isNotEmpty) {
    await tester.tap(find.byIcon(Icons.tune).first);
    await tester.pumpAndSettle();
  }

  final nextButton = find.byIcon(Icons.chevron_right);
  final prevButton = find.byIcon(Icons.chevron_left);

  if (nextButton.evaluate().isNotEmpty) {
    await tester.tap(nextButton.first);
    await tester.pumpAndSettle();
  }

  if (prevButton.evaluate().isNotEmpty) {
    await tester.tap(prevButton.first);
    await tester.pumpAndSettle();
  }
}

Future<void> _openMe(WidgetTester tester) async {
  await tester.tap(find.text('Me').last);
  await tester.pumpAndSettle();
}

Future<void> _logout(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () => find.text('Dang xuat').evaluate().isNotEmpty,
    reason: 'Logout button should be visible on Me page.',
  );
  await tester.tap(find.text('Dang xuat').first);
  await tester.pumpAndSettle();
}

Future<void> _expectAuthPage(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () => find.text('LOGIN').evaluate().isNotEmpty,
    reason: 'Auth page should appear after logout.',
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
