import 'package:flutter/material.dart';
import 'package:web_admin/domain/entities/manga.dart';

/// Các trạng thái hợp lệ của manga trong hệ thống.
const List<String> kMangaStatusOptions = <String>[
  'Đang tiến hành',
  'Hoàn thành',
  'Tạm dừng',
];

class ManageMangaTableCard extends StatelessWidget {
  final List<MangaEntity> mangas;
  final String Function(String?) normalizeStatus;
  final String Function(MangaEntity) buildAuthor;
  final String Function(MangaEntity) buildGenres;
  final String Function(MangaEntity) buildViewsText;
  final ValueChanged<MangaEntity> onEditTap;
  final ValueChanged<MangaEntity> onViewTap;
  final ValueChanged<MangaEntity> onDeleteTap;

  /// Callback khi admin chọn đổi trạng thái inline trong bảng.
  /// Nhận vào manga hiện tại và giá trị trạng thái mới.
  final void Function(MangaEntity manga, String newStatus)? onStatusChange;

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
    this.onStatusChange,
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
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF5F7FC),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.search_off_rounded,
                            size: 32,
                            color: Color(0xFFBBC3D0),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Không tìm thấy manga phù hợp',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4E5A6F),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
                          style: TextStyle(
                            color: Color(0xFF8491A7),
                            fontSize: 13,
                          ),
                        ),
                      ],
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
                            ...mangas.map(
                              (manga) => _MangaDataRow(
                                manga: manga,
                                normalizeStatus: normalizeStatus,
                                buildAuthor: buildAuthor,
                                buildGenres: buildGenres,
                                buildViewsText: buildViewsText,
                                onEditTap: onEditTap,
                                onViewTap: onViewTap,
                                onDeleteTap: onDeleteTap,
                                onStatusChange: onStatusChange,
                              ),
                            ),
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
          _headerCell('Trạng thái', 148),
          _headerCell('Số chương', 94),
          _headerCell('Lượt xem', 94),
          _headerCell('Đánh giá', 86),
          _headerCell('Thao tác', 106),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widget: một dòng dữ liệu trong bảng manga
// ---------------------------------------------------------------------------

class _MangaDataRow extends StatelessWidget {
  static const double _coverWidth = 50;
  static const double _coverHeight = 50;

  final MangaEntity manga;
  final String Function(String?) normalizeStatus;
  final String Function(MangaEntity) buildAuthor;
  final String Function(MangaEntity) buildGenres;
  final String Function(MangaEntity) buildViewsText;
  final ValueChanged<MangaEntity> onEditTap;
  final ValueChanged<MangaEntity> onViewTap;
  final ValueChanged<MangaEntity> onDeleteTap;
  final void Function(MangaEntity manga, String newStatus)? onStatusChange;

  const _MangaDataRow({
    required this.manga,
    required this.normalizeStatus,
    required this.buildAuthor,
    required this.buildGenres,
    required this.buildViewsText,
    required this.onEditTap,
    required this.onViewTap,
    required this.onDeleteTap,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
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
          SizedBox(
            width: 148,
            child: _StatusBadge(
              status: status,
              onStatusChange: onStatusChange != null
                  ? (newStatus) => onStatusChange!(manga, newStatus)
                  : null,
            ),
          ),
          _bodyCell('${manga.totalChapter ?? 0}', 94),
          _bodyCell(buildViewsText(manga), 94),
          SizedBox(width: 86, child: _buildRateCell(manga.rate)),
          SizedBox(width: 106, child: _buildActionButtons(context)),
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
        errorBuilder: (_, _, _) {
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

  Widget _actionButton(
    BuildContext context,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        _actionButton(
          context,
          Icons.visibility_outlined,
          const Color(0xFF657489),
          () => onViewTap(manga),
          tooltip: 'Xem chi tiết',
        ),
        const SizedBox(width: 2),
        _actionButton(
          context,
          Icons.edit_outlined,
          const Color(0xFF657489),
          () => onEditTap(manga),
          tooltip: 'Chỉnh sửa',
        ),
        const SizedBox(width: 2),
        _actionButton(
          context,
          Icons.delete_outline_rounded,
          const Color(0xFFF56D6D),
          () => onDeleteTap(manga),
          tooltip: 'Xóa',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Status badge với khả năng đổi trạng thái inline qua PopupMenu
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  final String status;
  final void Function(String newStatus)? onStatusChange;

  const _StatusBadge({required this.status, this.onStatusChange});

  static _StatusStyle _styleFor(String status) {
    switch (status) {
      case 'Đang tiến hành':
        return const _StatusStyle(
          background: Color(0xFF0D1F3C),
          foreground: Colors.white,
          icon: Icons.play_circle_outline_rounded,
        );
      case 'Hoàn thành':
        return const _StatusStyle(
          background: Color(0xFFEBFAF0),
          foreground: Color(0xFF1A7C40),
          icon: Icons.check_circle_outline_rounded,
        );
      case 'Tạm dừng':
        return const _StatusStyle(
          background: Color(0xFFFFF3E5),
          foreground: Color(0xFFA85C00),
          icon: Icons.pause_circle_outline_rounded,
        );
      default:
        return const _StatusStyle(
          background: Color(0xFFEFF3FB),
          foreground: Color(0xFF5E708C),
          icon: Icons.help_outline_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final _StatusStyle style = _styleFor(status);
    final bool canChange = onStatusChange != null;

    final Widget badge = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 12, color: style.foreground),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              status,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: style.foreground,
              ),
            ),
          ),
          if (canChange) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 14,
              color: style.foreground.withValues(alpha: 0.8),
            ),
          ],
        ],
      ),
    );

    if (!canChange) {
      return Align(alignment: Alignment.centerLeft, child: badge);
    }

    final List<String> otherStatuses = kMangaStatusOptions
        .where((s) => s != status)
        .toList();

    return Align(
      alignment: Alignment.centerLeft,
      child: PopupMenuButton<String>(
        tooltip: 'Đổi trạng thái',
        offset: const Offset(0, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onSelected: onStatusChange,
        itemBuilder: (_) => otherStatuses
            .map(
              (s) => PopupMenuItem<String>(
                value: s,
                height: 40,
                child: Row(
                  children: [
                    Icon(
                      _styleFor(s).icon,
                      size: 14,
                      color: _styleFor(s).foreground,
                    ),
                    const SizedBox(width: 8),
                    Text(s, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            )
            .toList(),
        child: badge,
      ),
    );
  }
}

class _StatusStyle {
  final Color background;
  final Color foreground;
  final IconData icon;

  const _StatusStyle({
    required this.background,
    required this.foreground,
    required this.icon,
  });
}
