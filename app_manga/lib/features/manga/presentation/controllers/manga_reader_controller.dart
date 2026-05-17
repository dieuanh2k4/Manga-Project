import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../../domain/entities/chapter_entity.dart';
import '../../domain/entities/chapter_page_entity.dart';
import '../../domain/usecases/get_pages_by_chapter_usecase.dart';
import '../../domain/usecases/upsert_history_usecase.dart';

enum ReaderMode { vertical, horizontal }

class MangaReaderController extends ChangeNotifier {
  final int mangaId;
  final String mangaTitle;
  final List<ChapterEntity> chapters;
  final String? token;
  final GetPagesByChapterUseCase getPagesByChapterUseCase;
  final UpsertHistoryUseCase upsertHistoryUseCase;

  MangaReaderController({
    required this.mangaId,
    required this.mangaTitle,
    required this.chapters,
    required this.getPagesByChapterUseCase,
    required this.upsertHistoryUseCase,
    this.token,
  });

  bool isLoading = false;
  String? errorMessage;
  bool showTaskbar = true;
  ReaderMode mode = ReaderMode.vertical;

  int currentChapterIndex = 0;
  int currentImageIndex = 0;

  int lastVerticalIndex = 0;
  Timer? _historyDebounce;
  int? _lastHistoryPageId;
  int? _lastHistoryChapterId;
  bool _lastHistoryCompleted = false;

  List<ChapterPageEntity> pages = const [];

  ChapterEntity get currentChapter => chapters[currentChapterIndex];

  Future<void> initialize(int initialChapterId) async {
    final idx = chapters.indexWhere((e) => e.id == initialChapterId);
    currentChapterIndex = idx >= 0 ? idx : 0;
    await loadCurrentChapter();
  }

  Future<void> loadCurrentChapter() async {
    isLoading = true;
    errorMessage = null;
    currentImageIndex = 0;
    notifyListeners();

    try {
      pages = await getPagesByChapterUseCase(
        mangaId: mangaId,
        chapterId: currentChapter.id,
        token: token,
      );
      if (pages.isEmpty) {
        errorMessage = 'Chapter nay chua co noi dung';
      } else {
        lastVerticalIndex = 0;
        _scheduleHistoryUpdate(pageIndex: 0);
      }
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      pages = const [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> goToChapter(int index) async {
    if (index < 0 || index >= chapters.length || index == currentChapterIndex) {
      return;
    }

    currentChapterIndex = index;
    await loadCurrentChapter();
  }

  Future<void> nextChapter() async {
    if (!hasNextChapter) {
      return;
    }

    await goToChapter(currentChapterIndex + 1);
  }

  Future<void> previousChapter() async {
    if (!hasPreviousChapter) {
      return;
    }

    await goToChapter(currentChapterIndex - 1);
  }

  bool get hasPreviousChapter => currentChapterIndex > 0;
  bool get hasNextChapter => currentChapterIndex < chapters.length - 1;

  bool get hasPreviousImage => currentImageIndex > 0;
  bool get hasNextImage => currentImageIndex < pages.length - 1;

  void setReaderMode(ReaderMode value) {
    if (mode == value) {
      return;
    }

    mode = value;
    showTaskbar = true;
    if (mode == ReaderMode.horizontal) {
      currentImageIndex = lastVerticalIndex.clamp(0, pages.length - 1);
      _scheduleHistoryUpdate(pageIndex: currentImageIndex);
    }
    notifyListeners();
  }

  void onHorizontalPageChanged(int index) {
    if (index == currentImageIndex) {
      return;
    }

    currentImageIndex = index;
    _scheduleHistoryUpdate(pageIndex: index);
    notifyListeners();
  }

  void onVerticalPageSelected(int index) {
    if (index < 0 || index >= pages.length) {
      return;
    }

    lastVerticalIndex = index;
    currentImageIndex = index;
    _scheduleHistoryUpdate(pageIndex: index);
  }

  void setCurrentImageIndex(int index) {
    if (index == currentImageIndex) {
      return;
    }

    currentImageIndex = index;
    notifyListeners();
  }

  void previousImage() {
    if (!hasPreviousImage) {
      return;
    }

    currentImageIndex -= 1;
    notifyListeners();
  }

  void nextImage() {
    if (!hasNextImage) {
      return;
    }

    currentImageIndex += 1;
    notifyListeners();
  }

  void toggleTaskbar() {
    showTaskbar = !showTaskbar;
    notifyListeners();
  }

  void updateTaskbarOnScroll(ScrollDirection direction) {
    if (mode != ReaderMode.vertical) {
      return;
    }

    if (direction == ScrollDirection.reverse && showTaskbar) {
      showTaskbar = false;
      notifyListeners();
      return;
    }

    if (direction == ScrollDirection.forward && !showTaskbar) {
      showTaskbar = true;
      notifyListeners();
    }
  }

  void _scheduleHistoryUpdate({required int pageIndex}) {
    if (token == null || token!.isEmpty) {
      return;
    }
    if (pageIndex < 0 || pageIndex >= pages.length) {
      return;
    }

    final pageId = pages[pageIndex].id;
    if (pageId <= 0) {
      return;
    }

    final chapterId = currentChapter.id;
    final isCompleted = pageIndex == pages.length - 1 ? true : null;
    if (_lastHistoryPageId == pageId &&
        _lastHistoryChapterId == chapterId &&
        _lastHistoryCompleted == (isCompleted ?? false)) {
      return;
    }

    _historyDebounce?.cancel();
    _historyDebounce = Timer(const Duration(milliseconds: 900), () async {
      _lastHistoryPageId = pageId;
      _lastHistoryChapterId = chapterId;
      _lastHistoryCompleted = isCompleted ?? false;
      try {
        await upsertHistoryUseCase(
          mangaId: mangaId,
          chapterId: chapterId,
          pageId: pageId,
          token: token!,
          isCompleted: isCompleted,
        );
      } catch (_) {
        // Ignore history update failures to avoid disrupting reading.
      }
    });
  }

  @override
  void dispose() {
    _historyDebounce?.cancel();
    super.dispose();
  }
}
