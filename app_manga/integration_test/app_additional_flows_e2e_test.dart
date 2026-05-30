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

  testWidgets('user can handle extra app flows', (tester) async {
    await _launchApp(tester);

    await _tryLoginWithWrongPassword(tester);
    await _loginIfNeeded(tester);

    await _expectHome(tester);
    await _openFirstMangaFromHome(tester);
    await _expectMangaDetail(tester);

    await _toggleFollow(tester);

    await _openFirstChapter(tester);
    await _expectReader(tester);
    await _toggleReaderMode(tester);

    await _goBackToMangaDetail(tester);
    await _goBackToHome(tester);

    await _openSearch(tester);
    await _openDirectoryTab(tester);
    await _toggleStatusFilter(tester);
    await _toggleFirstGenreIfAny(tester);

    await _goBackToHomeFromSearch(tester);
    await _openNotifications(tester);
    await _markAllNotificationsAsReadIfAny(tester);
    await _goBackToHome(tester);
  });
}

Future<void> _launchApp(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 2));
  await _waitForAppSettled(tester);
}

Future<void> _tryLoginWithWrongPassword(WidgetTester tester) async {
  if (find.text('LOGIN').evaluate().isEmpty) {
    return;
  }

  final textFields = find.byType(TextField);
  expect(textFields, findsAtLeastNWidgets(2));

  await tester.enterText(textFields.at(0), _username);
  await tester.enterText(textFields.at(1), 'wrong-password');
  await tester.tap(find.text('LOG IN'));
  await tester.pumpAndSettle();

  await _waitUntil(
    tester,
    () => find.text('LOGIN').evaluate().isNotEmpty,
    reason: 'Auth page should remain after wrong login.',
  );

  final errorText = find.byWidgetPredicate(
    (widget) =>
        widget is Text &&
        widget.style?.color == const Color(0xFF9B1B1B),
  );
  expect(errorText, findsWidgets);
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
    reason: 'Manga detail should show introduction and chapters.',
  );
}

Future<void> _toggleFollow(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        find.text('FOLLOW').evaluate().isNotEmpty ||
        find.text('FOLLOWING').evaluate().isNotEmpty,
    reason: 'Follow button should be visible.',
  );

  if (find.text('FOLLOWING').evaluate().isNotEmpty) {
    await tester.tap(find.text('FOLLOWING').first);
    await tester.pumpAndSettle();
  }

  if (find.text('FOLLOW').evaluate().isNotEmpty) {
    await tester.tap(find.text('FOLLOW').first);
    await tester.pumpAndSettle();
    await _waitUntil(
      tester,
      () => find.text('FOLLOWING').evaluate().isNotEmpty,
      reason: 'Follow state should change to FOLLOWING.',
    );

    await tester.tap(find.text('FOLLOWING').first);
    await tester.pumpAndSettle();
    await _waitUntil(
      tester,
      () => find.text('FOLLOW').evaluate().isNotEmpty,
      reason: 'Follow state should change back to FOLLOW.',
    );
  }
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

Future<void> _toggleReaderMode(WidgetTester tester) async {
  if (find.byIcon(Icons.tune).evaluate().isEmpty) {
    return;
  }

  await tester.tap(find.byIcon(Icons.tune).first);
  await tester.pumpAndSettle();

  if (find.text('Doc doc').evaluate().isNotEmpty) {
    await tester.tap(find.text('Doc doc').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Doc ngang').last);
    await tester.pumpAndSettle();
  }

  if (find.text('Doc ngang').evaluate().isNotEmpty) {
    await tester.tap(find.text('Doc ngang').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Doc doc').last);
    await tester.pumpAndSettle();
  }
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

Future<void> _openDirectoryTab(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () => find.text('DIRECTORY').evaluate().isNotEmpty,
    reason: 'Search page should show DIRECTORY tab.',
  );
  await tester.tap(find.text('DIRECTORY').first);
  await tester.pumpAndSettle();
}

Future<void> _toggleStatusFilter(WidgetTester tester) async {
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

    if (label == 'Continuous' || label == 'Complete' || label == 'New') {
      continue;
    }

    await tester.tap(find.text(label).first);
    await tester.pumpAndSettle();
    break;
  }
}

Future<void> _goBackToHomeFromSearch(WidgetTester tester) async {
  await tester.tap(find.text('Home').last);
  await tester.pumpAndSettle();
}

Future<void> _openNotifications(WidgetTester tester) async {
  final bell = find.byTooltip('Thong bao');
  if (bell.evaluate().isNotEmpty) {
    await tester.tap(bell.first);
    await tester.pumpAndSettle();
  }
}

Future<void> _markAllNotificationsAsReadIfAny(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () => find.text('Thong bao').evaluate().isNotEmpty,
    reason: 'Notification page should be visible.',
  );

  if (find.text('Da doc tat ca').evaluate().isNotEmpty) {
    await tester.tap(find.text('Da doc tat ca').first);
    await tester.pumpAndSettle();
  }
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
