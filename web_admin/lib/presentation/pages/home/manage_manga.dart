import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin/domain/entities/author.dart';
import 'package:web_admin/domain/entities/genre.dart';
import 'package:web_admin/domain/entities/manga.dart';
import 'package:web_admin/injection_container.dart';
import 'package:web_admin/presentation/helper/manage_manga_helper.dart';
import 'package:web_admin/presentation/helper/manage_manga_service.dart';
import 'package:web_admin/presentation/bloc/manga/remote/remote_manga_bloc.dart';
import 'package:web_admin/presentation/bloc/manga/remote/remote_manga_event.dart';
import 'package:web_admin/presentation/bloc/manga/remote/remote_manga_state.dart';
import 'package:web_admin/presentation/pages/home/create_manga_page.dart';
import 'package:web_admin/presentation/pages/home/create_manga_submit_result.dart';
import 'package:web_admin/presentation/pages/home/edit_manga_page.dart';
import 'package:web_admin/presentation/pages/home/edit_manga_submit_result.dart';
import 'package:web_admin/presentation/pages/home/manage_manga_detail_page.dart';
import 'package:web_admin/presentation/widgets/manage_manga_error_state.dart';
import 'package:web_admin/presentation/widgets/manage_manga_filter_bar.dart';
import 'package:web_admin/presentation/widgets/manage_manga_page_heading.dart';
import 'package:web_admin/presentation/widgets/manage_manga_sidebar.dart';
import 'package:web_admin/presentation/widgets/manage_manga_table_card.dart';
import 'package:web_admin/presentation/widgets/manage_manga_top_header.dart';
import 'manage_authors.dart';

class ManageManga extends StatefulWidget {
  const ManageManga({Key? key}) : super(key: key);

  @override
  State<ManageManga> createState() => _ManageMangaState();
}

class _ManageMangaState extends State<ManageManga> {
  static const String _allStatus = 'Tất cả trạng thái';

  final ManageMangaService _manageMangaService = sl<ManageMangaService>();

  final TextEditingController _globalSearchController = TextEditingController();
  final TextEditingController _mangaSearchController = TextEditingController();

  String _selectedStatus = _allStatus;
  String _selectedSort = 'A-Z';
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
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _loadLookupData() async {
    final ManageMangaLookupResult lookupResult = await _manageMangaService
        .loadLookupData();

    if (!mounted) {
      return;
    }

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

    if (!mounted || editedResult == null) {
      return;
    }

    final ManageMangaUpdateResult updateResult = await _manageMangaService
        .updateManga(
          manga: editedResult.manga,
          thumbnailFile: editedResult.thumbnailFile,
        );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(updateResult.message)));

    if (updateResult.isSuccess) {
      context.read<RemoteMangaBloc>().add(const GetManga());
    }
  }

  Future<void> _onAddTap() async {
    final CreateMangaSubmitResult? createdResult =
        await Navigator.of(context).push<CreateMangaSubmitResult>(
          MaterialPageRoute<CreateMangaSubmitResult>(
            builder: (_) => CreateMangaPage(
              authors: _authors,
              genres: _genres,
            ),
            fullscreenDialog: true,
          ),
        );

    if (!mounted || createdResult == null) {
      return;
    }

    final ManageMangaCreateResult createResult = await _manageMangaService
        .createManga(
          manga: createdResult.manga,
          thumbnailFile: createdResult.thumbnailFile,
        );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(createResult.message)));

    if (createResult.isSuccess) {
      context.read<RemoteMangaBloc>().add(const GetManga());
    }
  }

  void _onViewTap(MangaEntity manga) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ManageMangaDetailPage(manga: manga),
      ),
    );
  }

  Future<void> _onDeleteTap(MangaEntity manga) async {
    final int? mangaId = manga.id;
    if (mangaId == null || mangaId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không xác định được manga cần xóa')),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa manga'),
        content: Text(
          'Bạn có chắc muốn xóa "${manga.title ?? 'Manga'}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final ManageMangaDeleteResult deleteResult = await _manageMangaService
        .deleteManga(mangaId);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(deleteResult.message)));

    if (deleteResult.isSuccess) {
      context.read<RemoteMangaBloc>().add(const GetManga());
    }
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
                          ManageMangaSidebar(
                            compact: isCompactSidebar,
                            selectedKey: sidebarKeyManga,
                            onSelect: (key) {
                              if (key == sidebarKeyAuthors) {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const ManageAuthors(),
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
                          _loadLookupData();
                        },
                      );
                    }

                    if (state is RemoteMangaDone) {
                      final List<MangaEntity> mangas =
                          ManageMangaHelper.applyFilters(
                            items: state.manga ?? const <MangaEntity>[],
                            globalSearchText: _globalSearchController.text,
                            mangaSearchText: _mangaSearchController.text,
                            selectedStatus: _selectedStatus,
                            allStatus: _allStatus,
                            authorNameById: _authorNameById,
                            genreNameById: _genreNameById,
                            sortOption: _selectedSort,
                          );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ManageMangaPageHeading(onAddTap: _onAddTap),
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
                            selectedSort: _selectedSort,
                            onSortChanged: (value) {
                              setState(() {
                                _selectedSort = value;
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: ManageMangaTableCard(
                              mangas: mangas,
                              normalizeStatus:
                                  ManageMangaHelper.normalizeStatus,
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
}
