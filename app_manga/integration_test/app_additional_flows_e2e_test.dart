import 'package:app_manga/features/manga/presentation/controllers/manga_reader_controller.dart';
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
  if (!_isAuthPageVisible()) {
    return;
  }

  await tester.enterText(_loginUsernameField(), _username);
  await tester.enterText(_loginPasswordField(), 'wrong-password');
  await tester.tap(_loginSubmitButton());
  await tester.pumpAndSettle();

  await _waitUntil(
    tester,
    _isAuthPageVisible,
    reason: 'Auth page should remain after wrong login.',
    failureDetails: _visibleStateForFailure,
  );

  final errorText = find.byWidgetPredicate(
    (widget) =>
        widget is Text && widget.style?.color == const Color(0xFF9B1B1B),
  );
  expect(errorText, findsWidgets);
}

Future<void> _loginIfNeeded(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () =>
        find.byKey(const Key('home_page')).evaluate().isNotEmpty ||
        _isAuthPageVisible(),
    reason: 'App should settle on either auth page or home page before login.',
    failureDetails: _visibleStateForFailure,
  );

  if (!_isAuthPageVisible()) {
    return;
  }

  await tester.enterText(_loginUsernameField(), _username);
  await tester.enterText(_loginPasswordField(), _password);
  await tester.tap(_loginSubmitButton());
  await tester.pump();

  await _waitUntil(
    tester,
    () =>
        find.byKey(const Key('home_page')).evaluate().isNotEmpty ||
        _visibleAuthErrorText().isNotEmpty,
    reason: 'Home page should be visible after login.',
    failureDetails: _homeStateForFailure,
  );

  final authError = _visibleAuthErrorText();
  if (authError.isNotEmpty) {
    fail('Login failed before reaching Home. Auth error: $authError');
  }

  if (_isAuthPageVisible()) {
    fail(
      'Login did not navigate away from AuthPage. ${_visibleStateForFailure()}',
    );
  }
}

bool _isAuthPageVisible() {
  return find.byKey(const Key('auth_page')).evaluate().isNotEmpty ||
      find.text('ĐĂNG NHẬP').evaluate().isNotEmpty;
}

Finder _loginUsernameField() {
  final keyed = find.byKey(const Key('login_username_field'));
  if (keyed.evaluate().isNotEmpty) {
    return keyed;
  }

  final textFields = find.byType(TextField);
  expect(textFields, findsAtLeastNWidgets(2));
  return textFields.at(0);
}

Finder _loginPasswordField() {
  final keyed = find.byKey(const Key('login_password_field'));
  if (keyed.evaluate().isNotEmpty) {
    return keyed;
  }

  final textFields = find.byType(TextField);
  expect(textFields, findsAtLeastNWidgets(2));
  return textFields.at(1);
}

Finder _loginSubmitButton() {
  final keyed = find.byKey(const Key('login_submit_button'));
  if (keyed.evaluate().isNotEmpty) {
    return keyed;
  }

  final elevated = find.widgetWithText(ElevatedButton, 'ĐĂNG NHẬP');
  if (elevated.evaluate().isNotEmpty) {
    return elevated.last;
  }

  return find.text('ĐĂNG NHẬP').last;
}

Future<void> _expectHome(WidgetTester tester) async {
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

String _visibleLibraryMutationErrorText() {
  final values = find
      .byType(SnackBar)
      .evaluate()
      .map((element) => element.widget)
      .whereType<SnackBar>()
      .map((snackBar) {
        final content = snackBar.content;
        if (content is Text) {
          return content.data ?? content.textSpan?.toPlainText() ?? '';
        }
        return '';
      })
      .where((text) {
        final normalized = text.toLowerCase();
        return normalized.contains('that bai') ||
            normalized.contains('failed') ||
            normalized.contains('error') ||
            normalized.contains('exception');
      })
      .join(' | ');

  return values;
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
    await tester.tap(find.byKey(const Key('manga_follow_button')));
    await tester.pump();
    await _waitUntil(
      tester,
      () =>
          find.text('FOLLOW').evaluate().isNotEmpty ||
          _visibleLibraryMutationErrorText().isNotEmpty,
      reason: 'Follow state should change back to FOLLOW.',
      failureDetails: _visibleStateForFailure,
    );

    final unfollowError = _visibleLibraryMutationErrorText();
    if (unfollowError.isNotEmpty) {
      fail('Unfollow failed before reaching FOLLOW state: $unfollowError');
    }
  }

  if (find.text('FOLLOW').evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('manga_follow_button')));
    await tester.pump();
    await _waitUntil(
      tester,
      () =>
          find.text('FOLLOWING').evaluate().isNotEmpty ||
          _visibleLibraryMutationErrorText().isNotEmpty,
      reason: 'Follow state should change to FOLLOWING.',
      failureDetails: _visibleStateForFailure,
    );

    final followError = _visibleLibraryMutationErrorText();
    if (followError.isNotEmpty) {
      fail('Follow failed before reaching FOLLOWING state: $followError');
    }

    await tester.tap(find.byKey(const Key('manga_follow_button')));
    await tester.pump();
    await _waitUntil(
      tester,
      () =>
          find.text('FOLLOW').evaluate().isNotEmpty ||
          _visibleLibraryMutationErrorText().isNotEmpty,
      reason: 'Follow state should change back to FOLLOW.',
      failureDetails: _visibleStateForFailure,
    );

    final cleanupError = _visibleLibraryMutationErrorText();
    if (cleanupError.isNotEmpty) {
      fail('Follow cleanup failed before reaching FOLLOW state: $cleanupError');
    }
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
  final tuneButton = find.byIcon(Icons.tune);
  if (tuneButton.evaluate().isEmpty) {
    return;
  }

  await tester.tap(tuneButton.first);
  await tester.pumpAndSettle();

  final dropdownFinder = find.byKey(const Key('reader_mode_dropdown'));
  if (dropdownFinder.evaluate().isEmpty) {
    return;
  }

  final dropdown = tester.widget<DropdownButton<ReaderMode>>(dropdownFinder);
  final currentMode = dropdown.value;
  final targetMode = currentMode == ReaderMode.vertical
      ? ReaderMode.horizontal
      : ReaderMode.vertical;

  dropdown.onChanged?.call(targetMode);
  await tester.pumpAndSettle();

  final updatedDropdown = tester.widget<DropdownButton<ReaderMode>>(
    dropdownFinder,
  );
  updatedDropdown.onChanged?.call(currentMode);
  await tester.pumpAndSettle();
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
  await tester.tap(find.byKey(const Key('home_nav_search')));
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
  await tester.tap(find.byKey(const Key('search_nav_home')));
  await tester.pumpAndSettle();
}

Future<void> _openNotifications(WidgetTester tester) async {
  final bell = find.byKey(const Key('home_notification_button'));
  if (bell.evaluate().isNotEmpty) {
    await tester.tap(bell.first);
    await tester.pumpAndSettle();
  }
}

Future<void> _markAllNotificationsAsReadIfAny(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () => find.byKey(const Key('notification_page')).evaluate().isNotEmpty,
    reason: 'Notification page should be visible.',
  );

  final markAllButton = find.byKey(
    const Key('notifications_mark_all_read_button'),
  );
  if (markAllButton.evaluate().isNotEmpty) {
    await tester.tap(markAllButton.first);
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
