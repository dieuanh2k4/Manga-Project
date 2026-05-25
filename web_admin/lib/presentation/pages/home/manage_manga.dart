import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:web_admin/domain/entities/author.dart';
import 'package:web_admin/domain/entities/genre.dart';
import 'package:web_admin/domain/entities/manga.dart';
import 'package:web_admin/injection_container.dart';
import 'package:web_admin/presentation/helper/manage_manga_helper.dart';
import 'package:web_admin/presentation/helper/manage_manga_service.dart';
import 'package:web_admin/presentation/controllers/remote_manga_controller.dart';
import 'package:web_admin/presentation/controllers/theme_controller.dart';
import 'package:web_admin/presentation/pages/home/create_manga_page.dart';
import 'package:web_admin/presentation/pages/home/create_manga_submit_result.dart';
import 'package:web_admin/presentation/pages/home/edit_manga_page.dart';
import 'package:web_admin/presentation/pages/home/edit_manga_submit_result.dart';
import 'package:web_admin/presentation/pages/home/manage_manga_detail_page.dart';
import 'package:web_admin/presentation/pages/home/manage_notifications.dart';
import 'package:web_admin/presentation/widgets/manage_manga_error_state.dart';
import 'package:web_admin/presentation/widgets/manage_manga_filter_bar.dart';
import 'package:web_admin/presentation/widgets/manage_manga_page_heading.dart';
import 'package:web_admin/presentation/widgets/manage_manga_sidebar.dart';
import 'package:web_admin/presentation/widgets/manage_manga_table_card.dart';
import 'package:web_admin/presentation/widgets/manage_manga_top_header.dart';
import 'manage_authors.dart';
import 'manage_users.dart';
import 'manage_vip_packages.dart';
import 'manage_overview.dart';

class ManageManga extends StatefulWidget {
  final RemoteMangaController mangaController;
  final Future<void> Function()? onLogout;

  const ManageManga({
    Key? key,
    required this.mangaController,
    this.onLogout,
  }) : super(key: key);

  @override
  State<ManageManga> createState() => _ManageMangaState();
}

class _ManageMangaState extends State<ManageManga> {
  static const String _allStatus = 'Tất cả trạng thái';

  final ManageMangaService _manageMangaService = sl<ManageMangaService>();

  final TextEditingController _globalSearchController =
      TextEditingController();
  final TextEditingController _mangaSearchController = TextEditingController();

  String _selectedStatus = _allStatus;
  String _selectedSort = 'A-Z';
  Set<int> _selectedGenreIds = {};    // Hỗ trợ chọn nhiều thể loại
  List<AuthorEntity> _authors = const <AuthorEntity>[];
  List<GenreEntity> _genres = const <GenreEntity>[];
  Map<int, String> _authorNameById = const {};
  Map<int, String> _genreNameById = const {};

  @override
  void initState() {
    super.initState();
    _globalSearchController.addListener(_onFilterChanged);
    _mangaSearchController.addListener(_onFilterChanged);
    _loadLookupData();
  }

  @override
  void dispose() {
    _globalSearchController.removeListener(_onFilterChanged);
    _mangaSearchController.removeListener(_onFilterChanged);
    _globalSearchController.dispose();
    _mangaSearchController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadLookupData() async {
    final ManageMangaLookupResult lookupResult =
        await _manageMangaService.loadLookupData();
    if (!mounted) return;
    setState(() {
      _authors = lookupResult.authors;
      _genres = lookupResult.genres;
      _authorNameById = lookupResult.authorNameById;
      _genreNameById = lookupResult.genreNameById;
    });
  }

  Future<void> _onEditTap(MangaEntity manga) async {
    final EditMangaSubmitResult? editedResult = await Navigator.of(context)
        .push<EditMangaSubmitResult>(
          MaterialPageRoute<EditMangaSubmitResult>(
            builder: (_) => EditMangaPage(
              manga: manga,
              authors: _authors,
              genres: _genres,
              normalizeStatus: ManageMangaHelper.normalizeStatus,
            ),
            fullscreenDialog: true,
          ),
        );

    if (!mounted || editedResult == null) return;

    _showLoadingSnackBar('Đang cập nhật manga...');
    final ManageMangaUpdateResult updateResult = await _manageMangaService
        .updateManga(
          manga: editedResult.manga,
          thumbnailFile: editedResult.thumbnailFile,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    _showResultSnackBar(updateResult.message, updateResult.isSuccess);
    if (updateResult.isSuccess) widget.mangaController.loadManga();
  }

  Future<void> _onAddTap() async {
    final CreateMangaSubmitResult? createdResult = await Navigator.of(context)
        .push<CreateMangaSubmitResult>(
          MaterialPageRoute<CreateMangaSubmitResult>(
            builder: (_) => CreateMangaPage(authors: _authors, genres: _genres),
            fullscreenDialog: true,
          ),
        );

    if (!mounted || createdResult == null) return;

    _showLoadingSnackBar('Đang thêm manga mới...');
    final ManageMangaCreateResult createResult = await _manageMangaService
        .createManga(
          manga: createdResult.manga,
          thumbnailFile: createdResult.thumbnailFile,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    _showResultSnackBar(createResult.message, createResult.isSuccess);
    if (createResult.isSuccess) widget.mangaController.loadManga();
  }

  void _onViewTap(MangaEntity manga) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ManageMangaDetailPage(manga: manga),
      ),
    );
  }

  Future<void> _onNestedRouteLogout() async {
    Navigator.of(context).popUntil((route) => route.isFirst);
    await widget.onLogout?.call();
  }

  void _openNotificationsPage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ManageNotifications(
          mangaController: widget.mangaController,
          onLogout: _onNestedRouteLogout,
        ),
      ),
    );
  }

  Future<void> _onDeleteTap(MangaEntity manga) async {
    final int? mangaId = manga.id;
    if (mangaId == null || mangaId <= 0) {
      _showResultSnackBar('Không xác định được manga cần xóa', false);
      return;
    }

    final bool? confirmed = await _showConfirmDialog(
      title: 'Xóa Manga',
      content:
          'Bạn có chắc muốn xóa "${manga.title ?? 'Manga'}" không?\n\nHành động này không thể hoàn tác.',
      confirmLabel: 'Xóa',
      isDestructive: true,
    );

    if (confirmed != true) return;

    _showLoadingSnackBar('Đang xóa manga...');
    final ManageMangaDeleteResult deleteResult = await _manageMangaService
        .deleteManga(mangaId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    _showResultSnackBar(deleteResult.message, deleteResult.isSuccess);
    if (deleteResult.isSuccess) widget.mangaController.loadManga();
  }

  Future<void> _onStatusChange(MangaEntity manga, String newStatus) async {
    final ManageMangaUpdateResult result = await _manageMangaService
        .updateMangaStatus(manga: manga, newStatus: newStatus);

    if (!mounted) return;
    _showResultSnackBar(result.message, result.isSuccess);
    if (result.isSuccess) widget.mangaController.loadManga();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _showLoadingSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 30),
        backgroundColor: const Color(0xFF1F5BFF),
      ),
    );
  }

  void _showResultSnackBar(String message, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess
            ? const Color(0xFF1A7C40)
            : const Color(0xFFD93025),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    String confirmLabel = 'Xác nhận',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          content,
          style: const TextStyle(color: Color(0xFF4E5A6F), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive
                  ? const Color(0xFFD93025)
                  : const Color(0xFF1F5BFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMangaButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F5BFF), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x441F5BFF),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _onAddTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text(
          'Thêm Manga mới',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = sl<ThemeController>();
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final isDark = themeController.isDarkMode;
        final scaffoldBg = isDark ? const Color(0xFF1A1D2E) : const Color(0xFFDFE3ED);
        final shellBg = isDark ? const Color(0xFF0E1326) : Colors.white;
        final shellBorder = isDark ? const Color(0xFF1E2640) : const Color(0xFFE2E8F0);

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isCompactSidebar = constraints.maxWidth < 1120;
            final double shellHeight = (constraints.maxHeight - 24)
                .clamp(620.0, 920.0)
                .toDouble();

            return Scaffold(
              backgroundColor: scaffoldBg,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1440),
                      child: SizedBox(
                        height: shellHeight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: shellBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: shellBorder, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 32,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          children: [
                            ManageMangaSidebar(
                              compact: isCompactSidebar,
                              selectedKey: sidebarKeyManga,
                              onSelect: (key) {
                                if (key == sidebarKeyOverview) {
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                } else if (key == sidebarKeyAuthors) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ManageAuthors(
                                        mangaController: widget.mangaController,
                                        onLogout: _onNestedRouteLogout,
                                      ),
                                    ),
                                  );
                                } else if (key == sidebarKeyUsers) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ManageUsers(
                                        mangaController: widget.mangaController,
                                        onLogout: _onNestedRouteLogout,
                                      ),
                                    ),
                                  );
                                } else if (key == sidebarKeyVip) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ManageVipPackages(
                                        mangaController: widget.mangaController,
                                        onLogout: _onNestedRouteLogout,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            Expanded(child: _buildMainContent(context)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
      },
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final isDark = sl<ThemeController>().isDarkMode;
    return Container(
      color: isDark ? const Color(0xFF080C1B) : const Color(0xFFF7F8FC),
      child: Column(
        children: [
          ManageMangaTopHeader(
            searchController: _globalSearchController,
            onLogout: widget.onLogout,
            customHeaderWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        size: 18,
                        color: Color(0xFF1F5BFF),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Quản lý Manga',
                      style: TextStyle(
                        color: Color(0xFF1D2638),
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Padding(
                  padding: EdgeInsets.only(left: 2),
                  child: Text(
                    'Quản lý toàn bộ bộ sưu tập truyện trong hệ thống',
                    style: TextStyle(color: Color(0xFF7B879B), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: ListenableBuilder(
                listenable: widget.mangaController,
                builder: (_, __) {
                  final RemoteMangaState state = widget.mangaController.state;

                  if (state is RemoteMangaLoading) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CupertinoActivityIndicator(radius: 16),
                          SizedBox(height: 14),
                          Text(
                            'Đang tải dữ liệu...',
                            style: TextStyle(color: Color(0xFF8491A7)),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is RemoteMangaError) {
                    return ManageMangaErrorState(
                      onRetry: () {
                        widget.mangaController.loadManga();
                        _loadLookupData();
                      },
                    );
                  }

                  if (state is RemoteMangaDone) {
                    final List<MangaEntity> allMangas =
                        state.manga ?? const <MangaEntity>[];
                    final List<MangaEntity> mangas =
                        ManageMangaHelper.applyFilters(
                          items: allMangas,
                          globalSearchText: _globalSearchController.text,
                          mangaSearchText: _mangaSearchController.text,
                          selectedStatus: _selectedStatus,
                          allStatus: _allStatus,
                          authorNameById: _authorNameById,
                          genreNameById: _genreNameById,
                          selectedGenreIds: _selectedGenreIds,
                          sortOption: _selectedSort,
                        );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildAddMangaButton(),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _MangaStatsRow(mangas: allMangas),
                        const SizedBox(height: 16),
                        ManageMangaFilterBar(
                          searchController: _mangaSearchController,
                          selectedStatus: _selectedStatus,
                          allStatus: _allStatus,
                          onStatusChanged: (value) {
                            setState(() => _selectedStatus = value);
                          },
                          selectedSort: _selectedSort,
                          onSortChanged: (value) {
                            setState(() => _selectedSort = value);
                          },
                          genres: _genres,
                          selectedGenreIds: _selectedGenreIds,
                          onGenresChanged: (ids) {
                            setState(() => _selectedGenreIds = ids);
                          },
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ManageMangaTableCard(
                            mangas: mangas,
                            normalizeStatus: ManageMangaHelper.normalizeStatus,
                            buildAuthor: (MangaEntity manga) =>
                                ManageMangaHelper.buildAuthor(
                                  manga,
                                  _authorNameById,
                                ),
                            buildGenres: (MangaEntity manga) =>
                                ManageMangaHelper.buildGenres(
                                  manga,
                                  _genreNameById,
                                ),
                            buildViewsText: ManageMangaHelper.buildViewsText,
                            onEditTap: _onEditTap,
                            onViewTap: _onViewTap,
                            onDeleteTap: _onDeleteTap,
                            onStatusChange: _onStatusChange,
                          ),
                        ),
                      ],
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Stats row widget
// ────────────────────────────────────────────────────────────────────────────

class _MangaStatsRow extends StatelessWidget {
  final List<MangaEntity> mangas;

  const _MangaStatsRow({required this.mangas});

  @override
  Widget build(BuildContext context) {
    final int total = mangas.length;
    final int ongoing = mangas
        .where(
          (m) =>
              ManageMangaHelper.normalizeStatus(m.status) == 'Đang tiến hành',
        )
        .length;
    final int completed = mangas
        .where(
          (m) => ManageMangaHelper.normalizeStatus(m.status) == 'Hoàn thành',
        )
        .length;
    final int paused = mangas
        .where(
          (m) => ManageMangaHelper.normalizeStatus(m.status) == 'Tạm dừng',
        )
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool stacked = constraints.maxWidth < 600;
        final bool twoColumn =
            constraints.maxWidth >= 600 && constraints.maxWidth < 1000;

        final List<Widget> cards = <Widget>[
          _MangaStatCard(
            label: 'Tổng bộ truyện',
            value: '$total',
            icon: Icons.menu_book_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF1F5BFF), Color(0xFF3B82F6)],
            ),
          ),
          _MangaStatCard(
            label: 'Đang tiến hành',
            value: '$ongoing',
            icon: Icons.play_circle_outline_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            ),
          ),
          _MangaStatCard(
            label: 'Hoàn thành',
            value: '$completed',
            icon: Icons.check_circle_outline_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF34D399)],
            ),
          ),
          _MangaStatCard(
            label: 'Tạm dừng',
            value: '$paused',
            icon: Icons.pause_circle_outline_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFD97706), Color(0xFFFBBF24)],
            ),
          ),
        ];

        if (stacked) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        if (twoColumn) {
          final double cardWidth =
              (constraints.maxWidth - 12).clamp(320.0, 1000.0).toDouble() / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map((card) => SizedBox(width: cardWidth, child: card))
                .toList(),
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
            const SizedBox(width: 12),
            Expanded(child: cards[2]),
            const SizedBox(width: 12),
            Expanded(child: cards[3]),
          ],
        );
      },
    );
  }
}

class _MangaStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback? onTap;
  final String? actionLabel;

  const _MangaStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    this.onTap,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: <Widget>[
                  Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    final BorderRadius borderRadius = BorderRadius.circular(14);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: borderRadius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: content,
        ),
      ),
    );
  }
}
