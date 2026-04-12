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
import 'package:web_admin/presentation/pages/home/edit_manga_page.dart';
import 'package:web_admin/presentation/pages/home/edit_manga_submit_result.dart';
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

  final ManageMangaService _manageMangaService = sl<ManageMangaService>();

  final TextEditingController _globalSearchController = TextEditingController();
  final TextEditingController _mangaSearchController = TextEditingController();

  String _selectedStatus = _allStatus;
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
