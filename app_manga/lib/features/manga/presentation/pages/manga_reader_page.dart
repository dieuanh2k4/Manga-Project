import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../../core/services/reading_progress_service.dart';
import '../../../../core/network/image_cache_manager.dart';
import '../../../../core/network/protected_network_image.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/chapter_entity.dart';
import '../../domain/repositories/manga_repository.dart';
import '../../domain/usecases/get_pages_by_chapter_usecase.dart';
import '../../domain/usecases/upsert_history_usecase.dart';
import '../controllers/manga_reader_controller.dart';

class MangaReaderPage extends StatelessWidget {
  final int mangaId;
  final String mangaTitle;
  final List<ChapterEntity> chapters;
  final int initialChapterId;

  const MangaReaderPage({
    super.key,
    required this.mangaId,
    required this.mangaTitle,
    required this.chapters,
    required this.initialChapterId,
  });

  @override
  Widget build(BuildContext context) {
    final mangaRepository = context.read<MangaRepository>();
    final auth = context.read<AuthController>();

    return ChangeNotifierProvider(
      create: (_) => MangaReaderController(
        mangaId: mangaId,
        mangaTitle: mangaTitle,
        chapters: chapters,
        token: auth.session?.token,
        getPagesByChapterUseCase: GetPagesByChapterUseCase(mangaRepository),
        upsertHistoryUseCase: UpsertHistoryUseCase(mangaRepository),
      )..initialize(initialChapterId),
      child: const _MangaReaderView(),
    );
  }
}

class _MangaReaderView extends StatefulWidget {
  const _MangaReaderView();

  @override
  State<_MangaReaderView> createState() => _MangaReaderViewState();
}

class _MangaReaderViewState extends State<_MangaReaderView> {
  final PageController _horizontalPageController = PageController();
  final List<GlobalKey> _pageKeys = [];
  final GlobalKey _listKey = GlobalKey();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  int? _restoredChapterId;
  bool _isRestoring = false;
  int _lastSavedIndex = -1;
  bool _positionsListenerAttached = false;
  bool _isSwitchingChapterForRestore = false;
  int? _lastPrecachedChapterId;
  int? _lastPrecachedCenterIndex;

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(_onItemPositionsChanged);
    _positionsListenerAttached = true;
  }

  @override
  void dispose() {
    if (_positionsListenerAttached) {
      _itemPositionsListener.itemPositions.removeListener(
        _onItemPositionsChanged,
      );
    }
    _horizontalPageController.dispose();
    super.dispose();
  }

  void _syncPageKeys(int length) {
    if (_pageKeys.length == length) {
      return;
    }
    _pageKeys
      ..clear()
      ..addAll(List.generate(length, (_) => GlobalKey()));
  }

  int? _getMostVisibleIndex() {
    if (_pageKeys.isEmpty) {
      return null;
    }

    final viewportBox =
        _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewportBox == null) {
      return null;
    }

    final viewportTop = viewportBox.localToGlobal(Offset.zero).dy;
    final viewportBottom = viewportTop + viewportBox.size.height;

    double bestFraction = 0;
    int? bestIndex;

    for (var i = 0; i < _pageKeys.length; i++) {
      final keyContext = _pageKeys[i].currentContext;
      if (keyContext == null) {
        continue;
      }
      final box = keyContext.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) {
        continue;
      }

      final itemTop = box.localToGlobal(Offset.zero).dy;
      final itemBottom = itemTop + box.size.height;
      final visibleHeight =
          (itemBottom < viewportBottom ? itemBottom : viewportBottom) -
          (itemTop > viewportTop ? itemTop : viewportTop);

      if (visibleHeight <= 0) {
        continue;
      }

      final fraction = visibleHeight / box.size.height;
      if (fraction > bestFraction) {
        bestFraction = fraction;
        bestIndex = i;
      }
    }

    return bestIndex;
  }

  void _reportVerticalHistory(MangaReaderController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || controller.mode != ReaderMode.vertical) {
        return;
      }
      final index = _getMostVisibleIndex();
      if (index != null) {
        controller.onVerticalPageSelected(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MangaReaderController>();
    _restoreProgressIfNeeded(controller);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _precacheReaderImages(controller);

      if (controller.mode == ReaderMode.horizontal &&
          _horizontalPageController.hasClients &&
          _horizontalPageController.page?.round() !=
              controller.currentImageIndex) {
        _horizontalPageController.jumpToPage(controller.currentImageIndex);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1116),
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.mangaTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              'Chuong ${controller.currentChapter.chapterNumber}',
              style: const TextStyle(fontSize: 14, color: Color(0xFFC9CED9)),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: controller.toggleTaskbar,
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildContent(controller)),
          Align(
            alignment: Alignment.bottomCenter,
            child: _ReaderTaskbar(
              controller: controller,
              onSelectChapter: (index) async {
                await controller.goToChapter(index);
                _jumpToFirstPage(controller);
              },
              onModeChanged: controller.setReaderMode,
              onPrevChapter: () async {
                await controller.previousChapter();
                _jumpToFirstPage(controller);
              },
              onNextChapter: () async {
                await controller.nextChapter();
                _jumpToFirstPage(controller);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(MangaReaderController controller) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE8742B)),
      );
    }

    if (controller.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFE8742B),
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                controller.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: controller.loadCurrentChapter,
                child: const Text('Thu lai'),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.pages.isEmpty) {
      return const Center(
        child: Text(
          'Chuong nay chua co noi dung',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    if (controller.mode == ReaderMode.horizontal) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final width = constraints.maxWidth;
              final dx = details.localPosition.dx;

              if (dx <= width * 0.35) {
                controller.previousImage();
                _horizontalPageController.animateToPage(
                  controller.currentImageIndex,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                );
                return;
              }

              if (dx >= width * 0.65) {
                controller.nextImage();
                _horizontalPageController.animateToPage(
                  controller.currentImageIndex,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                );
                return;
              }

              controller.toggleTaskbar();
            },
            child: PageView.builder(
              controller: _horizontalPageController,
              itemCount: controller.pages.length,
              onPageChanged: (index) {
                controller.onHorizontalPageChanged(index);
                _saveProgress(controller, index);
              },
              itemBuilder: (context, index) {
                final page = controller.pages[index];
                return Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    // đọc ngang: ảnh được render qua CachedNetworkImage, lướt lên hay xuống
                    // ảnh có thể lấy từ cache thay vì tải lại
                    child: ProtectedNetworkImage(
                      imageUrl: page.imageUrl,
                      cacheKey: _imageCacheKey(page.imageUrl),
                      fit: BoxFit.contain,
                      errorWidget: Container(
                        color: const Color(0xFF191B1F),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    }

    _syncPageKeys(controller.pages.length);
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is UserScrollNotification) {
          controller.updateTaskbarOnScroll(notification.direction);
        }
        if (notification is ScrollEndNotification) {
          _reportVerticalHistory(controller);
        }
        return false;
      },
      child: ScrollablePositionedList.builder(
        key: _listKey,
        itemScrollController: _itemScrollController,
        itemPositionsListener: _itemPositionsListener,
        padding: EdgeInsets.only(bottom: controller.showTaskbar ? 90 : 20),
        itemCount: controller.pages.length,
        itemBuilder: (context, index) {
          final page = controller.pages[index];
          return KeyedSubtree(
            key: _pageKeys[index],
            // đọc dọc: ảnh được render qua CachedNetworkImage, lướt lên hay xuống
            // ảnh có thể lấy từ cache thay vì tải lại
            child: ProtectedNetworkImage(
              imageUrl: page.imageUrl,
              cacheKey: _imageCacheKey(page.imageUrl),
              fit: BoxFit.fitWidth,
              loadingWidget: Container(
                color: Colors.black,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: const CircularProgressIndicator(
                  color: Color(0xFFE8742B),
                ),
              ),
              errorWidget: Container(
                color: const Color(0xFF191B1F),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: const Icon(Icons.broken_image, color: Colors.white70),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _restoreProgressIfNeeded(
    MangaReaderController controller,
  ) async {
    if (_isRestoring || controller.isLoading) {
      return;
    }

    final chapterId = controller.currentChapter.id;
    if (_restoredChapterId == chapterId) {
      return;
    }

    _isRestoring = true;
    final savedChapterId = await ReadingProgressService.getLastChapter(
      mangaId: controller.mangaId,
    );

    if (!mounted) {
      _isRestoring = false;
      return;
    }

    final targetChapterId = savedChapterId ?? chapterId;
    if (targetChapterId != chapterId && !_isSwitchingChapterForRestore) {
      final targetIndex = controller.chapters.indexWhere(
        (chapter) => chapter.id == targetChapterId,
      );
      if (targetIndex != -1) {
        _isSwitchingChapterForRestore = true;
        _isRestoring = false;
        await controller.goToChapter(targetIndex);
        _isSwitchingChapterForRestore = false;
        return;
      }
    }

    if (controller.pages.isEmpty) {
      _isRestoring = false;
      return;
    }

    final savedIndex = await ReadingProgressService.getProgress(
      mangaId: controller.mangaId,
      chapterId: chapterId,
    );

    if (!mounted) {
      _isRestoring = false;
      return;
    }

    final index = (savedIndex ?? 0).clamp(0, controller.pages.length - 1);
    controller.setCurrentImageIndex(index);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (controller.mode == ReaderMode.horizontal &&
          _horizontalPageController.hasClients) {
        _horizontalPageController.jumpToPage(index);
      }

      if (controller.mode == ReaderMode.vertical &&
          _itemScrollController.isAttached) {
        _itemScrollController.jumpTo(index: index, alignment: 0);
      }

      _restoredChapterId = chapterId;
      _isRestoring = false;
      _lastSavedIndex = index;
    });
  }

  void _saveProgress(MangaReaderController controller, int index) {
    if (_lastSavedIndex == index) {
      return;
    }

    _lastSavedIndex = index;
    ReadingProgressService.saveProgress(
      mangaId: controller.mangaId,
      chapterId: controller.currentChapter.id,
      pageIndex: index,
    );
  }

  void _jumpToFirstPage(MangaReaderController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (controller.mode == ReaderMode.horizontal &&
          _horizontalPageController.hasClients) {
        _horizontalPageController.jumpToPage(0);
      }

      if (controller.mode == ReaderMode.vertical &&
          _itemScrollController.isAttached) {
        _itemScrollController.jumpTo(index: 0, alignment: 0);
      }
    });
  }

  void _onItemPositionsChanged() {
    if (!mounted) {
      return;
    }

    final controller = context.read<MangaReaderController>();
    if (_isRestoring || controller.isLoading || controller.pages.isEmpty) {
      return;
    }

    if (controller.mode != ReaderMode.vertical) {
      return;
    }

    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) {
      return;
    }

    final visible = positions.where(
      (p) => p.itemTrailingEdge > 0 && p.itemLeadingEdge < 1,
    );

    if (visible.isEmpty) {
      return;
    }

    final topMost = visible.reduce(
      (a, b) => a.itemLeadingEdge < b.itemLeadingEdge ? a : b,
    );

    _saveProgress(controller, topMost.index);
    controller.onVerticalPageSelected(topMost.index);
  }

  String _imageCacheKey(String imageUrl) {
    return imageUrl;
  }

  // preload ảnh từ (trang hiện tại-2) đến (trang hiện tại+4)
  // app tải sẵn vài ảnh gần đó vào cache
  // khi lướt tiếp hoặc lướt ngược lại sẽ nhanh hơn
  void _precacheReaderImages(MangaReaderController controller) {
    if (controller.isLoading || controller.pages.isEmpty) {
      return;
    }

    final chapterId = controller.currentChapter.id;
    final centerIndex = controller.currentImageIndex.clamp(
      0,
      controller.pages.length - 1,
    );
    if (_lastPrecachedChapterId == chapterId &&
        _lastPrecachedCenterIndex == centerIndex) {
      return;
    }

    _lastPrecachedChapterId = chapterId;
    _lastPrecachedCenterIndex = centerIndex;

    final start = (centerIndex - 2).clamp(0, controller.pages.length - 1);
    final end = (centerIndex + 4).clamp(0, controller.pages.length - 1);
    for (var index = start; index <= end; index++) {
      final imageUrl = controller.pages[index].imageUrl;
      final cacheKey = _imageCacheKey(imageUrl);
      unawaited(MangaImageCacheManager.markCached(cacheKey));
      precacheImage(
        CachedNetworkImageProvider(
          imageUrl,
          cacheKey: cacheKey,
          cacheManager: MangaImageCacheManager.instance,
        ),
        context,
      );
    }
  }
}

class _ReaderTaskbar extends StatelessWidget {
  final MangaReaderController controller;
  final Future<void> Function(int index) onSelectChapter;
  final Future<void> Function() onPrevChapter;
  final Future<void> Function() onNextChapter;
  final ValueChanged<ReaderMode> onModeChanged;

  const _ReaderTaskbar({
    required this.controller,
    required this.onSelectChapter,
    required this.onPrevChapter,
    required this.onNextChapter,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !controller.showTaskbar,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        offset: controller.showTaskbar ? Offset.zero : const Offset(0, 1.1),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: controller.showTaskbar ? 1 : 0,
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0D11),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2F3542)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _ControlButton(
                      icon: Icons.chevron_left,
                      enabled: controller.hasPreviousChapter,
                      onTap: onPrevChapter,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF3B4250)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: controller.currentChapterIndex,
                            dropdownColor: const Color(0xFF11141B),
                            iconEnabledColor: Colors.white,
                            style: const TextStyle(color: Colors.white),
                            isExpanded: true,
                            items: List.generate(controller.chapters.length, (
                              index,
                            ) {
                              final chapter = controller.chapters[index];
                              final label = chapter.chapterNumber.trim().isEmpty
                                  ? 'Chapter'
                                  : 'Ch. ${chapter.chapterNumber}';
                              return DropdownMenuItem<int>(
                                value: index,
                                child: Text(label),
                              );
                            }),
                            onChanged: (index) async {
                              if (index == null) {
                                return;
                              }

                              await onSelectChapter(index);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ControlButton(
                      icon: Icons.chevron_right,
                      enabled: controller.hasNextChapter,
                      onTap: onNextChapter,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF3B4250)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ReaderMode>(
                          value: controller.mode,
                          dropdownColor: const Color(0xFF11141B),
                          iconEnabledColor: Colors.white,
                          style: const TextStyle(color: Colors.white),
                          items: const [
                            DropdownMenuItem(
                              value: ReaderMode.vertical,
                              child: Text('Doc doc'),
                            ),
                            DropdownMenuItem(
                              value: ReaderMode.horizontal,
                              child: Text('Doc ngang'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            onModeChanged(value);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                if (controller.mode == ReaderMode.horizontal) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${controller.currentImageIndex + 1}/${controller.pages.length}',
                        style: const TextStyle(color: Color(0xFFC9CED9)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final Future<void> Function() onTap;

  const _ControlButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: OutlinedButton(
        onPressed: enabled ? () => onTap() : null,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: const BorderSide(color: Color(0xFF3B4250)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          foregroundColor: Colors.white,
          disabledForegroundColor: const Color(0xFF6B7383),
        ),
        child: Icon(icon),
      ),
    );
  }
}
