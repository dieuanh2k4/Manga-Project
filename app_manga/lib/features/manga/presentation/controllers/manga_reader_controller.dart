import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../../domain/entities/chapter_entity.dart';
import '../../domain/entities/chapter_page_entity.dart';
import '../../domain/usecases/get_pages_by_chapter_usecase.dart';

enum ReaderMode { vertical, horizontal }

class MangaReaderController extends ChangeNotifier {
  final int mangaId;
  final String mangaTitle;
  final List<ChapterEntity> chapters;
  final String? token;
  final GetPagesByChapterUseCase getPagesByChapterUseCase;

  MangaReaderController({
    required this.mangaId,
    required this.mangaTitle,
    required this.chapters,
    required this.getPagesByChapterUseCase,
    this.token,
  });

  bool isLoading = false;
  String? errorMessage;
  bool showTaskbar = true;
  ReaderMode mode = ReaderMode.vertical;

  int currentChapterIndex = 0;
  int currentImageIndex = 0;

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
    notifyListeners();
  }

  void onHorizontalPageChanged(int index) {
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
}
