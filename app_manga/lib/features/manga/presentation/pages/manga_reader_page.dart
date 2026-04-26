import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/protected_network_image.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/chapter_entity.dart';
import '../../domain/repositories/manga_repository.dart';
import '../../domain/usecases/get_pages_by_chapter_usecase.dart';
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
  final ScrollController _verticalScrollController = ScrollController();
  final PageController _horizontalPageController = PageController();

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MangaReaderController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (controller.mode == ReaderMode.horizontal &&
          _horizontalPageController.hasClients &&
          _horizontalPageController.page?.round() != controller.currentImageIndex) {
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
          Positioned.fill(
            child: _buildContent(controller),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _ReaderTaskbar(
              controller: controller,
              onSelectChapter: (index) async {
                await controller.goToChapter(index);
                _verticalScrollController.jumpTo(0);
              },
              onModeChanged: controller.setReaderMode,
              onPrevChapter: () async {
                await controller.previousChapter();
                _verticalScrollController.jumpTo(0);
              },
              onNextChapter: () async {
                await controller.nextChapter();
                _verticalScrollController.jumpTo(0);
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
              const Icon(Icons.error_outline, color: Color(0xFFE8742B), size: 40),
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
              onPageChanged: controller.onHorizontalPageChanged,
              itemBuilder: (context, index) {
                final page = controller.pages[index];
                return Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: ProtectedNetworkImage(
                      imageUrl: page.imageUrl,
                      fit: BoxFit.contain,
                      errorWidget: Container(
                        color: const Color(0xFF191B1F),
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image, color: Colors.white70),
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

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        controller.updateTaskbarOnScroll(notification.direction);
        return false;
      },
      child: ListView.builder(
        controller: _verticalScrollController,
        padding: EdgeInsets.only(bottom: controller.showTaskbar ? 90 : 20),
        itemCount: controller.pages.length,
        itemBuilder: (context, index) {
          final page = controller.pages[index];
          return ProtectedNetworkImage(
            imageUrl: page.imageUrl,
            fit: BoxFit.fitWidth,
            loadingWidget: Container(
              color: Colors.black,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: const CircularProgressIndicator(color: Color(0xFFE8742B)),
            ),
            errorWidget: Container(
              color: const Color(0xFF191B1F),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: const Icon(Icons.broken_image, color: Colors.white70),
            ),
          );
        },
      ),
    );
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
                            items: List.generate(controller.chapters.length, (index) {
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
