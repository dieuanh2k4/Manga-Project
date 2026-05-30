import 'package:flutter/material.dart';
import 'package:web_admin/presentation/models/manga_detail_items.dart';

class MangaChapterPanel extends StatelessWidget {
  final List<ChapterItem> chapters;
  final ChapterItem? selectedChapter;
  final bool loading;
  final VoidCallback onAdd;
  final ValueChanged<ChapterItem> onEdit;
  final ValueChanged<ChapterItem> onDelete;
  final ValueChanged<ChapterItem> onSelect;

  const MangaChapterPanel({
    super.key,
    required this.chapters,
    required this.selectedChapter,
    required this.loading,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E8F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF0F3F8))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.format_list_numbered_rounded,
                        size: 16,
                        color: Color(0xFF1F5BFF),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Danh sách Chapter',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D2638),
                          ),
                        ),
                        Text(
                          '${chapters.length} chapter',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8491A7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: loading ? null : onAdd,
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Thêm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F5BFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1F5BFF),
                    ),
                  )
                : chapters.isEmpty
                ? _EmptyChapterState(onAdd: onAdd)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: chapters.length,
                    itemBuilder: (context, index) {
                      final ChapterItem chapter = chapters[index];
                      final bool selected = chapter.id == selectedChapter?.id;

                      return _ChapterTile(
                        chapter: chapter,
                        selected: selected,
                        onTap: () => onSelect(chapter),
                        onEdit: () => onEdit(chapter),
                        onDelete: () => onDelete(chapter),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final ChapterItem chapter;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChapterTile({
    required this.chapter,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEFF4FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: selected
            ? Border.all(color: const Color(0xFF1F5BFF).withOpacity(0.3))
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Chapter number badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF1F5BFF)
                      : const Color(0xFFF0F3F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    chapter.chapterNumber,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : const Color(0xFF4E5A6F),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? const Color(0xFF1F5BFF)
                            : const Color(0xFF1D2638),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (chapter.isPremium)
                      Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 11,
                            color: const Color(0xFFD97706).withOpacity(0.8),
                          ),
                          const SizedBox(width: 3),
                          const Text(
                            'Premium',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFFD97706),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconBtn(
                    icon: Icons.edit_outlined,
                    color: const Color(0xFF657489),
                    tooltip: 'Sửa',
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 2),
                  _IconBtn(
                    icon: Icons.delete_outline_rounded,
                    color: const Color(0xFFE53935),
                    tooltip: 'Xóa',
                    onTap: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChapterState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyChapterState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3F8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_stories_outlined,
              size: 32,
              color: Color(0xFF9AA8BE),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Chưa có chapter nào',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF4E5A6F),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Thêm chapter đầu tiên để bắt đầu',
            style: TextStyle(fontSize: 12, color: Color(0xFF8491A7)),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Thêm chapter'),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Page panel
// ────────────────────────────────────────────────────────────────────────────

class MangaPagePanel extends StatelessWidget {
  final ChapterItem? selectedChapter;
  final List<PageItem> pages;
  final Set<int> selectedPageIds;
  final bool loading;
  final VoidCallback onUpload;
  final VoidCallback onDeleteSelected;
  final ValueChanged<PageItem> onTogglePage;

  const MangaPagePanel({
    super.key,
    required this.selectedChapter,
    required this.pages,
    required this.selectedPageIds,
    required this.loading,
    required this.onUpload,
    required this.onDeleteSelected,
    required this.onTogglePage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E8F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF0F3F8))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F3F8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.photo_library_outlined,
                        size: 16,
                        color: Color(0xFF657489),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedChapter == null
                              ? 'Trang truyện'
                              : 'Chapter ${selectedChapter!.chapterNumber}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D2638),
                          ),
                        ),
                        Text(
                          '${pages.length} trang${selectedPageIds.isNotEmpty ? ' · ${selectedPageIds.length} đã chọn' : ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8491A7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (selectedPageIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ElevatedButton.icon(
                          onPressed: onDeleteSelected,
                          icon: const Icon(Icons.delete_outline, size: 14),
                          label: Text('Xóa (${selectedPageIds.length})'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD93025),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: selectedChapter == null ? null : onUpload,
                      icon: const Icon(Icons.upload_file_outlined, size: 14),
                      label: const Text('Upload ảnh'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF1F5BFF),
        ),
      );
    }

    if (selectedChapter == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF0F3F8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.touch_app_outlined,
                size: 32,
                color: Color(0xFF9AA8BE),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Chọn một chapter',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF4E5A6F),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'để xem và quản lý các trang truyện',
              style: TextStyle(fontSize: 12, color: Color(0xFF8491A7)),
            ),
          ],
        ),
      );
    }

    if (pages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF0F3F8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.image_outlined,
                size: 32,
                color: Color(0xFF9AA8BE),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Chưa có trang nào',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF4E5A6F),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Upload ảnh để thêm trang truyện',
              style: TextStyle(fontSize: 12, color: Color(0xFF8491A7)),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.68,
      ),
      itemCount: pages.length,
      itemBuilder: (context, index) {
        final PageItem page = pages[index];
        final bool selected = selectedPageIds.contains(page.id);

        return _PageThumbnail(
          page: page,
          selected: selected,
          onTap: () => onTogglePage(page),
        );
      },
    );
  }
}

class _PageThumbnail extends StatelessWidget {
  final PageItem page;
  final bool selected;
  final VoidCallback onTap;

  const _PageThumbnail({
    required this.page,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF1F5BFF) : const Color(0xFFE4E8F2),
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  const BoxShadow(
                    color: Color(0x331F5BFF),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.5),
          child: Stack(
            children: [
              // Image
              Positioned.fill(
                child: Image.network(
                  page.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: const Color(0xFFF0F3F8),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Color(0xFF9AA8BE),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFFE5EAF3),
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Color(0xFF9AA8BE),
                    ),
                  ),
                ),
              ),
              // Selection overlay
              if (selected)
                Positioned.fill(
                  child: Container(color: const Color(0x221F5BFF)),
                ),
              // Check badge
              Positioned(
                top: 6,
                right: 6,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF1F5BFF)
                        : Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF1F5BFF)
                          : const Color(0xFFCCD4E0),
                      width: 1.5,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 13)
                      : null,
                ),
              ),
              // Page number badge
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 6,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xCC000000), Color(0x00000000)],
                    ),
                  ),
                  child: Text(
                    'Trang ${page.id}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
