import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin/domain/entities/manga.dart';
import 'package:web_admin/presentation/bloc/manga/remote/remote_manga_bloc.dart';
import 'package:web_admin/presentation/bloc/manga/remote/remote_manga_event.dart';
import 'package:web_admin/presentation/bloc/manga/remote/remote_manga_state.dart';
import 'package:web_admin/presentation/widgets/manage_manga_error_state.dart';
import 'package:web_admin/presentation/widgets/manage_manga_filter_bar.dart';
import 'package:web_admin/presentation/widgets/manage_manga_page_heading.dart';
import 'package:web_admin/presentation/widgets/manage_manga_sidebar.dart';
import 'package:web_admin/presentation/widgets/manage_manga_table_card.dart';
import 'package:web_admin/presentation/widgets/manage_manga_top_header.dart';

class ManageManga extends StatefulWidget {
  const ManageManga({Key? key}) : super(key: key);

  @override
  State<ManageManga> createState() => _ManageMangaState();
}

class _ManageMangaState extends State<ManageManga> {
  static const String _allStatus = 'Tất cả trạng thái';

  final TextEditingController _globalSearchController = TextEditingController();
  final TextEditingController _mangaSearchController = TextEditingController();

  String _selectedStatus = _allStatus;

  @override
  void initState() {
    super.initState();
    _globalSearchController.addListener(_onFilterChanged);
    _mangaSearchController.addListener(_onFilterChanged);
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
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompactSidebar = constraints.maxWidth < 1120;
        final double shellHeight = (constraints.maxHeight - 24)
            .clamp(620.0, 920.0)
            .toDouble();

        return Scaffold(
          backgroundColor: const Color(0xFF2F3034),
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
                        color: const Color(0xFFF5F7FC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          ManageMangaSidebar(compact: isCompactSidebar),
                          Expanded(child: _buildMainContent(context)),
                        ],
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
  }

  Widget _buildMainContent(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(14),
        bottomRight: Radius.circular(14),
      ),
      child: Container(
        color: const Color(0xFFF7F8FC),
        child: Column(
          children: [
            ManageMangaTopHeader(searchController: _globalSearchController),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: BlocBuilder<RemoteMangaBloc, RemoteMangaState>(
                  builder: (_, state) {
                    if (state is RemoteMangaLoading) {
                      return const Center(child: CupertinoActivityIndicator());
                    }

                    if (state is RemoteMangaError) {
                      return ManageMangaErrorState(
                        onRetry: () {
                          context.read<RemoteMangaBloc>().add(const GetManga());
                        },
                      );
                    }

                    if (state is RemoteMangaDone) {
                      final List<MangaEntity> mangas = _applyFilters(
                        state.manga ?? const [],
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ManageMangaPageHeading(onAddTap: () {}),
                          const SizedBox(height: 18),
                          ManageMangaFilterBar(
                            searchController: _mangaSearchController,
                            selectedStatus: _selectedStatus,
                            allStatus: _allStatus,
                            onStatusChanged: (value) {
                              setState(() {
                                _selectedStatus = value;
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: ManageMangaTableCard(
                              mangas: mangas,
                              normalizeStatus: _normalizeStatus,
                              buildAuthor: _buildAuthor,
                              buildGenres: _buildGenres,
                              buildViewsText: _buildViewsText,
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
      ),
    );
  }

  List<MangaEntity> _applyFilters(List<MangaEntity> items) {
    final String keyword =
        '${_globalSearchController.text} ${_mangaSearchController.text}'
            .trim()
            .toLowerCase();

    return items.where((manga) {
      final String title = (manga.title ?? '').toLowerCase();
      final String description = (manga.description ?? '').toLowerCase();
      final String status = _normalizeStatus(manga.status).toLowerCase();
      final String author = _buildAuthor(manga).toLowerCase();
      final String genres = _buildGenres(manga).toLowerCase();

      final bool matchesKeyword =
          keyword.isEmpty ||
          title.contains(keyword) ||
          description.contains(keyword) ||
          author.contains(keyword) ||
          genres.contains(keyword) ||
          status.contains(keyword);

      final bool matchesStatus =
          _selectedStatus == _allStatus ||
          _normalizeStatus(manga.status) == _selectedStatus;

      return matchesKeyword && matchesStatus;
    }).toList();
  }

  String _normalizeStatus(String? value) {
    final String status = (value ?? '').trim().toLowerCase();

    if (status.contains('ongoing') || status.contains('đang')) {
      return 'Đang tiến hành';
    }

    if (status.contains('completed') || status.contains('hoàn')) {
      return 'Hoàn thành';
    }

    if (status.contains('pause') ||
        status.contains('hiatus') ||
        status.contains('tạm')) {
      return 'Tạm dừng';
    }

    if (status.isEmpty) {
      return 'Chưa cập nhật';
    }

    return value!.trim();
  }

  String _buildAuthor(MangaEntity manga) {
    if (manga.authorId == null || manga.authorId == 0) {
      return 'Chưa cập nhật';
    }
    return 'Tác giả #${manga.authorId}';
  }

  String _buildGenres(MangaEntity manga) {
    if (manga.genreIds == null || manga.genreIds!.isEmpty) {
      return 'Chưa phân loại';
    }

    return manga.genreIds!.take(3).map((id) => 'Thể loại #$id').join(', ');
  }

  String _buildViewsText(MangaEntity manga) {
    final int chapters = manga.totalChapter ?? 0;
    final int seed = manga.id ?? 1;
    final int views = chapters * 2300 + seed * 1700;
    return _formatCompactNumber(views);
  }

  String _formatCompactNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toString();
  }
}
