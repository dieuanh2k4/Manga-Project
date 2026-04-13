import 'package:flutter/material.dart';

import '../models/genre.dart';
import '../models/manga.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late final TabController _tabController;

  List<Manga> _allManga = [];
  List<Manga> _searchResult = [];
  List<Manga> _ongoingManga = [];
  List<Manga> _completedManga = [];
  List<Genre> _genres = [];
  final Map<int, List<Manga>> _genreMangaCache = {};

  bool _isLoading = true;
  bool _isFilteringGenre = false;
  String? _errorMessage;

  String _selectedStatus = 'Continuous';
  Genre? _selectedGenre;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchSearchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchSearchData() async {
    try {
      final results = await Future.wait([
        ApiService.getAllManga(),
        ApiService.getOngoingManga(),
        ApiService.getCompletedManga(),
        ApiService.getAllGenres(),
      ]);

      setState(() {
        _allManga = results[0] as List<Manga>;
        _searchResult = _allManga;
        _ongoingManga = results[1] as List<Manga>;
        _completedManga = results[2] as List<Manga>;
        _genres = results[3] as List<Genre>;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _onSearchChanged(String value) async {
    final query = value.trim();

    if (query.isEmpty) {
      setState(() {
        _searchResult = _allManga;
      });
      return;
    }

    try {
      final response = await ApiService.searchManga(query);
      if (!mounted) return;
      setState(() {
        _searchResult = response;
      });
    } catch (_) {
      if (!mounted) return;
      final keyword = query.toLowerCase();
      setState(() {
        _searchResult = _allManga
            .where((m) => m.title.toLowerCase().contains(keyword))
            .toList();
      });
    }
  }

  List<Manga> _popularItems() {
    final copy = List<Manga>.from(_searchResult);
    copy.sort((a, b) => b.rate.compareTo(a.rate));
    return copy;
  }

  List<Manga> _lastUpdateItems() {
    final copy = List<Manga>.from(_searchResult);
    copy.sort((a, b) => b.id.compareTo(a.id));
    return copy;
  }

  List<Manga> _directoryItems() {
    List<Manga> base;
    switch (_selectedStatus) {
      case 'Continuous':
        base = _ongoingManga;
        break;
      case 'Complete':
        base = _completedManga;
        break;
      case 'New':
        base = _lastUpdateItems();
        break;
      default:
        base = _allManga;
    }

    if (_selectedGenre == null) {
      return base;
    }

    final genreItems = _genreMangaCache[_selectedGenre!.id] ?? const <Manga>[];
    final allowedIds = genreItems.map((e) => e.id).toSet();

    return base.where((m) => allowedIds.contains(m.id)).toList();
  }

  Future<void> _onGenreTapped(Genre genre) async {
    if (_selectedGenre?.id == genre.id) {
      setState(() {
        _selectedGenre = null;
      });
      return;
    }

    setState(() {
      _selectedGenre = genre;
    });

    if (_genreMangaCache.containsKey(genre.id)) {
      return;
    }

    setState(() {
      _isFilteringGenre = true;
    });

    try {
      final result = await ApiService.getMangaByGenre(genre.id);
      if (!mounted) return;

      setState(() {
        _genreMangaCache[genre.id] = result;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _genreMangaCache[genre.id] = const [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isFilteringGenre = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildError()
                : Column(
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 8),
                      Container(height: 8, color: const Color(0xFFFF6200)),
                      TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFFCC5A15),
                        unselectedLabelColor: const Color(0xFF2E2E2E),
                        indicatorColor: const Color(0xFFCC5A15),
                        tabs: const [
                          Tab(text: 'POPULAR'),
                          Tab(text: 'LAST UPDATES'),
                          Tab(text: 'DIRECTORY'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildMangaList(_popularItems(), isUpdateList: false),
                            _buildMangaList(_lastUpdateItems(), isUpdateList: true),
                            _buildDirectoryTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 40, color: Color(0xFFBA541E)),
            const SizedBox(height: 12),
            const Text(
              'Không tải được dữ liệu Search',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _fetchSearchData();
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Enter title or author\'s name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFCC5A15)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFCC5A15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide:
                      const BorderSide(color: Color(0xFFCC5A15), width: 1.2),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.more_vert, size: 30, color: Color(0xFF333333)),
        ],
      ),
    );
  }

  Widget _buildMangaList(
    List<Manga> items, {
    required bool isUpdateList,
    bool isEmbedded = false,
  }) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Không có dữ liệu',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: isEmbedded,
      physics: isEmbedded
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Color(0xFFD0D0D0)),
      itemBuilder: (context, index) {
        final manga = items[index];
        return Container(
          color: const Color(0xFFF2F2F2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Image.network(
                  manga.thumbnail ??
                      'https://via.placeholder.com/60x85?text=Manga',
                  width: 54,
                  height: 74,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 54,
                    height: 74,
                    color: Colors.grey.shade300,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported_outlined,
                        size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manga.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 30 / 1.5,
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      manga.status ?? 'Unknown status',
                      style:
                          const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'cap ${manga.totalChapter}',
                      style:
                          const TextStyle(fontSize: 16 / 1.2, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isUpdateList
                          ? '${(index + 1) * 12} minutes ago'
                          : 'This have ${(manga.id * 246813) % 99999999} views',
                      style:
                          const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDirectoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status',
            style: TextStyle(fontSize: 32 / 1.5, color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: ['Continuous', 'Complete', 'New']
                .map(
                  (status) => GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedStatus = status;
                      });
                    },
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 31 / 1.5,
                        color: _selectedStatus == status
                            ? const Color(0xFFCC5A15)
                            : const Color(0xFF333333),
                        decoration: _selectedStatus == status
                            ? TextDecoration.underline
                            : TextDecoration.none,
                        decorationColor: const Color(0xFFCC5A15),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            'Genres',
            style: TextStyle(fontSize: 32 / 1.5, color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 22,
            runSpacing: 18,
            children: _genres
                .map(
                  (genre) => GestureDetector(
                    onTap: () => _onGenreTapped(genre),
                    child: Text(
                      genre.name,
                      style: TextStyle(
                        fontSize: 30 / 1.5,
                        color: _selectedGenre?.id == genre.id
                            ? const Color(0xFFCC5A15)
                            : const Color(0xFF333333),
                        decoration: _selectedGenre?.id == genre.id
                            ? TextDecoration.underline
                            : TextDecoration.none,
                        decorationColor: const Color(0xFFCC5A15),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 10),
          if (_isFilteringGenre)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            _buildMangaList(
              _directoryItems(),
              isUpdateList: true,
              isEmbedded: true,
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 2,
      selectedItemColor: const Color(0xFFE8742B),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      onTap: (index) {
        if (index == 0) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
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
