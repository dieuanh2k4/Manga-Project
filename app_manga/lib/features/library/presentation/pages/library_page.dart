import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/protected_network_image.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/pages/me_page.dart';
import '../../../manga/presentation/pages/manga_detail_page.dart';
import '../../../manga/presentation/pages/search_page.dart';
import '../../../manga/presentation/pages/home_page.dart';
import '../../domain/entities/library_manga_entity.dart';
import '../controllers/library_controller.dart';

class LibraryPage extends StatefulWidget {
  final String token;
  const LibraryPage({super.key, required this.token});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>
    with SingleTickerProviderStateMixin {
  static const Color _primaryColor = Color(0xFFE8742B);
  static const Color _primaryDark = Color(0xFFC75F25);
  static const Color _dividerColor = Color(0xFFE6E6E6);

  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LibraryController(
        getLibraryMangaUseCase: context.read(),
        addMangaToLibraryUseCase: context.read(),
        deleteMangaFromLibraryUseCase: context.read(),
      )..fetchLibraryManga(widget.token),
      child: Consumer<LibraryController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Library - ${_currentTabLabel()}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search here',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                size: 20,
                                color: Colors.grey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: _primaryColor,
                                  width: 1.2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: _primaryColor,
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: _primaryColor,
                                  width: 1.5,
                                ),
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  Container(height: 4, color: _primaryColor),
                  TabBar(
                    controller: _tabController,
                    labelColor: _primaryColor,
                    unselectedLabelColor: Colors.black54,
                    indicatorColor: _primaryColor,
                    indicatorWeight: 2.5,
                    tabs: const [
                      Tab(text: 'Your Library'),
                      Tab(text: 'History'),
                      Tab(text: 'Downloads'),
                    ],
                  ),
                  Expanded(
                    child: _buildBody(controller),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: _buildBottomNav(context),
          );
        },
      ),
    );
  }

  Widget _buildBody(LibraryController controller) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryColor),
      );
    }

    if (controller.error != null) {
      return Center(child: Text('Lỗi: ${controller.error}'));
    }

    final filtered = _filterManga(controller.libraryManga);
    if (filtered.isEmpty) {
      return const Center(child: Text('Thư viện của bạn trống.'));
    }

    if (_tabController.index == 1) {
      return _buildHistoryList(filtered);
    }

    if (_tabController.index == 2) {
      return Stack(
        children: [
          _buildDownloadsList(filtered),
          Positioned(
            right: 16,
            bottom: 16,
            child: Material(
              elevation: 2,
              shape: const CircleBorder(),
              color: Colors.white,
              child: InkWell(
                onTap: () {},
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.download, color: _primaryColor),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return _buildLibraryList(filtered);
  }

  String _currentTabLabel() {
    switch (_tabController.index) {
      case 1:
        return 'History';
      case 2:
        return 'Downloads';
      default:
        return 'Your Library';
    }
  }

  List<LibraryMangaEntity> _filterManga(List<LibraryMangaEntity> input) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return input;
    }
    return input
        .where((manga) => manga.title.toLowerCase().contains(query))
        .toList();
  }

  Widget _buildLibraryList(List<LibraryMangaEntity> items) {
    final sections = _groupByLetter(items);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final entry in sections.entries) ...[
          _buildSectionHeader(entry.key),
          for (final manga in entry.value) ...[
            _LibraryListItem(
              manga: manga,
              primaryText: 'Cap ${manga.totalChapter}',
              secondaryText: 'Cap ${_lastReadChapter(manga)}  →',
              badgeText: _badgeText(manga),
            ),
            const Divider(height: 1, color: _dividerColor),
          ],
        ],
      ],
    );
  }

  Widget _buildHistoryList(List<LibraryMangaEntity> items) {
    final sections = _groupByLetter(items);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final entry in sections.entries) ...[
          _buildSectionHeader(entry.key),
          for (final manga in entry.value) ...[
            _LibraryListItem(
              manga: manga,
              primaryText: 'Cap ${manga.totalChapter}',
              secondaryText: _historyStatus(manga),
            ),
            const Divider(height: 1, color: _dividerColor),
          ],
        ],
      ],
    );
  }

  Widget _buildDownloadsList(List<LibraryMangaEntity> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: _dividerColor),
      itemBuilder: (context, index) {
        final manga = items[index];
        return _LibraryListItem(
          manga: manga,
          primaryText: 'Complete (${manga.totalChapter})',
          secondaryText: 'Complete',
        );
      },
    );
  }

  Map<String, List<LibraryMangaEntity>> _groupByLetter(
    List<LibraryMangaEntity> items,
  ) {
    final Map<String, List<LibraryMangaEntity>> grouped = {};
    for (final manga in items) {
      final title = manga.title.trim();
      final letter = title.isEmpty ? '#' : title[0].toUpperCase();
      grouped.putIfAbsent(letter, () => []).add(manga);
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return {for (final entry in entries) entry.key: entry.value};
  }

  Widget _buildSectionHeader(String letter) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _primaryDark,
        ),
      ),
    );
  }

  String _badgeText(LibraryMangaEntity manga) {
    final status = (manga.status ?? '').toLowerCase();
    if (status.contains('new')) {
      return 'New!';
    }
    return '';
  }

  String _historyStatus(LibraryMangaEntity manga) {
    final status = (manga.status ?? '').toLowerCase();
    if (status.contains('complete') || status.contains('finished')) {
      return 'Finished';
    }
    return 'Reading';
  }

  int _lastReadChapter(LibraryMangaEntity manga) {
    if (manga.totalChapter <= 1) {
      return manga.totalChapter;
    }
    return manga.totalChapter - 1;
  }

  BottomNavigationBar _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 1,
      selectedItemColor: _primaryColor,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      onTap: (index) {
        if (index == 0) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
        if (index == 2) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SearchPage()),
          );
        }
        if (index == 3) {
          final auth = Provider.of<AuthController>(context, listen: false);
          if (auth.session != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MePage()),
            );
          }
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_outlined),
          label: 'Library',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Me'),
      ],
    );
  }
}

class _LibraryListItem extends StatelessWidget {
  final LibraryMangaEntity manga;
  final String primaryText;
  final String secondaryText;
  final String badgeText;

  const _LibraryListItem({
    required this.manga,
    required this.primaryText,
    required this.secondaryText,
    this.badgeText = '',
  });

  String _getImageUrl(String? thumbnail) {
    if (thumbnail == null || thumbnail.isEmpty) {
      return 'https://via.placeholder.com/150x200?text=No+Image';
    }
    if (thumbnail.startsWith('http')) {
      return thumbnail;
    }
    return '${AppConfig.apiOrigin}/${thumbnail.replaceFirst(RegExp(r'^/+'), '')}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MangaDetailPage(mangaId: manga.id),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ProtectedNetworkImage(
                imageUrl: _getImageUrl(manga.thumbnail),
                width: 56,
                height: 78,
                fit: BoxFit.cover,
                errorWidget: Container(
                  width: 56,
                  height: 78,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manga.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        primaryText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      if (badgeText.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          badgeText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFE8742B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    secondaryText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
