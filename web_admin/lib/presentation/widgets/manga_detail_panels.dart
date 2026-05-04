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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE3E7F0)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Danh sách Chapter',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D2638),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: loading ? null : onAdd,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Thêm'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : chapters.isEmpty
                ? const Center(child: Text('Chưa có chapter'))
                : ListView.builder(
                    itemCount: chapters.length,
                    itemBuilder: (context, index) {
                      final ChapterItem chapter = chapters[index];
                      final bool selected = chapter.id == selectedChapter?.id;

                      return ListTile(
                        selected: selected,
                        title: Text(
                          'Chapter ${chapter.chapterNumber}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(chapter.title),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (chapter.isPremium)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.lock,
                                  size: 16,
                                  color: Color(0xFFEF8354),
                                ),
                              ),
                            IconButton(
                              tooltip: 'Sửa',
                              onPressed: () => onEdit(chapter),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                            ),
                            IconButton(
                              tooltip: 'Xóa',
                              onPressed: () => onDelete(chapter),
                              icon: const Icon(Icons.delete_outline, size: 18),
                            ),
                          ],
                        ),
                        onTap: () => onSelect(chapter),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE3E7F0)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedChapter == null
                      ? 'Trang truyện'
                      : 'Trang truyện - Chapter ${selectedChapter!.chapterNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D2638),
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: selectedChapter == null ? null : onUpload,
                      icon: const Icon(Icons.upload_file_outlined, size: 16),
                      label: const Text('Upload'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: selectedPageIds.isEmpty
                          ? null
                          : onDeleteSelected,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: Text('Xóa (${selectedPageIds.length})'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (selectedChapter == null) {
      return const Center(child: Text('Chọn chapter để xem trang'));
    }

    if (pages.isEmpty) {
      return const Center(child: Text('Chưa có trang nào'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: pages.length,
      itemBuilder: (context, index) {
        final PageItem page = pages[index];
        final bool selected = selectedPageIds.contains(page.id);

        return InkWell(
          onTap: () => onTogglePage(page),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? const Color(0xFF1F5BFF)
                    : const Color(0xFFE3E7F0),
                width: selected ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      page.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: const Color(0xFFE5EAF3),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Color(0xFF9AA8BE),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF1F5BFF)
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF1F5BFF)
                            : const Color(0xFFB8C2D6),
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${page.id}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
