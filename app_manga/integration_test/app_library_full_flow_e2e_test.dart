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
    reason: 'Home page should be visible after login.',
    failureDetails: _homeStateForFailure,
  );

  final authError = _visibleAuthErrorText();
  if (authError.isNotEmpty && authError != errorBeforeSubmit) {
    fail('Login failed before reaching Home. Auth error: $authError');
  }
}

Future<void> _expectHome(WidgetTester tester) async {
  await _waitUntil(
    tester,
    () => find.byKey(const Key('home_page')).evaluate().isNotEmpty,
    reason: 'Home page should show manga sections.',
    failureDetails: _homeStateForFailure,
  );
}

bool _isAuthPageVisible() {
  return find.byKey(const Key('auth_page')).evaluate().isNotEmpty ||
      find.byKey(const Key('login_submit_button')).evaluate().isNotEmpty;
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
  if (_isAuthPageVisible()) {
    return 'App is on auth page. Login may have failed. ${_visibleStateForFailure()}';
  }
  return _visibleStateForFailure();
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

Future<void> _goBackToHome(WidgetTester tester) async {
  await tester.pageBack();
  await tester.pumpAndSettle();
  await _expectHome(tester);
}

Future<void> _openLibrary(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('home_nav_library')));
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
  await tester.tap(find.byKey(const Key('library_nav_home')));
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

