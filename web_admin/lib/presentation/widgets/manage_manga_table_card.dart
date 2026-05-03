import 'package:flutter/material.dart';
import 'package:web_admin/domain/entities/manga.dart';

class ManageMangaTableCard extends StatelessWidget {
  static const double _coverWidth = 50;
  static const double _coverHeight = 50;

  final List<MangaEntity> mangas;
  final String Function(String?) normalizeStatus;
  final String Function(MangaEntity) buildAuthor;
  final String Function(MangaEntity) buildGenres;
  final String Function(MangaEntity) buildViewsText;
  final ValueChanged<MangaEntity> onEditTap;
  final ValueChanged<MangaEntity> onViewTap;
  final ValueChanged<MangaEntity> onDeleteTap;

  const ManageMangaTableCard({
    super.key,
    required this.mangas,
    required this.normalizeStatus,
    required this.buildAuthor,
    required this.buildGenres,
    required this.buildViewsText,
    required this.onEditTap,
    required this.onViewTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E8F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Text(
              'Danh sách Manga (${mangas.length})',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E2A3C),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEF1F6)),
          Expanded(
            child: mangas.isEmpty
                ? const Center(
                    child: Text(
                      'Không tìm thấy manga phù hợp',
                      style: TextStyle(color: Color(0xFF8491A7)),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 1080),
                        child: Column(
                          children: [
                            _buildHeaderRow(),
                            const Divider(height: 1, color: Color(0xFFEEF1F6)),
                            ...mangas.map(_buildDataRow),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF344055),
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          _headerCell('Ảnh bìa', 86),
          _headerCell('Tên truyện', 180),
          _headerCell('Tác giả', 136),
          _headerCell('Thể loại', 170),
          _headerCell('Trạng thái', 128),
          _headerCell('Số chương', 94),
          _headerCell('Lượt xem', 94),
          _headerCell('Đánh giá', 86),
          _headerCell('Thao tác', 106),
        ],
      ),
    );
  }

  Widget _buildCoverImage(String? thumbnail) {
    final String image = thumbnail?.trim() ?? '';

    if (image.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: _coverWidth,
          height: _coverHeight,
          color: const Color(0xFFE5EAF3),
          child: const Icon(
            Icons.image_outlined,
            size: 18,
            color: Color(0xFF9AA8BE),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        image,
        width: _coverWidth,
        height: _coverHeight,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: _coverWidth,
            height: _coverHeight,
            color: const Color(0xFFE5EAF3),
            child: const Icon(
              Icons.broken_image_outlined,
              size: 18,
              color: Color(0xFF9AA8BE),
            ),
          );
        },
      ),
    );
  }

  Widget _bodyCell(
    String text,
    double width, {
    bool bold = false,
    int? maxLines,
  }) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: maxLines,
        softWrap: true,
        overflow: maxLines == null
            ? TextOverflow.visible
            : TextOverflow.ellipsis,
        style: TextStyle(
          color: const Color(0xFF4E5A6F),
          fontSize: 13,
          height: 1.35,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final bool isOngoing = status == 'Đang tiến hành';
    final bool isDone = status == 'Hoàn thành';
    final bool isPaused = status == 'Tạm dừng';

    Color background;
    Color foreground;

    if (isOngoing) {
      background = const Color(0xFF050B1C);
      foreground = Colors.white;
    } else if (isDone) {
      background = const Color(0xFFF0F3F8);
      foreground = const Color(0xFF56647A);
    } else if (isPaused) {
      background = const Color(0xFFFFF3E5);
      foreground = const Color(0xFFA85C00);
    } else {
      background = const Color(0xFFEFF3FB);
      foreground = const Color(0xFF5E708C);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      ),
    );
  }

  Widget _buildRateCell(int? rate) {
    final String text = rate == null ? '--' : rate.toString();

    return Row(
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 13, color: Color(0xFF4E5A6F)),
        ),
      ],
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildActionButtons(MangaEntity manga) {
    return Row(
      children: [
        _actionButton(
          Icons.visibility_outlined,
          const Color(0xFF657489),
          () => onViewTap(manga),
        ),
        const SizedBox(width: 2),
        _actionButton(
          Icons.edit_outlined,
          const Color(0xFF657489),
          () => onEditTap(manga),
        ),
        const SizedBox(width: 2),
        _actionButton(
          Icons.delete_outline_rounded,
          const Color(0xFFF56D6D),
          () => onDeleteTap(manga),
        ),
      ],
    );
  }

  Widget _buildDataRow(MangaEntity manga) {
    final String status = normalizeStatus(manga.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F3F8))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildCoverImage(manga.thumbnail),
            ),
          ),
          _bodyCell(manga.title ?? 'Chưa có tên', 180, bold: true),
          _bodyCell(buildAuthor(manga), 136),
          _bodyCell(buildGenres(manga), 170),
          SizedBox(width: 128, child: _buildStatusBadge(status)),
          _bodyCell('${manga.totalChapter ?? 0}', 94),
          _bodyCell(buildViewsText(manga), 94),
          SizedBox(width: 86, child: _buildRateCell(manga.rate)),
          SizedBox(width: 106, child: _buildActionButtons(manga)),
        ],
      ),
    );
  }
}
