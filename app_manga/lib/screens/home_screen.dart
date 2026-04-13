import 'package:flutter/material.dart';
import '../models/manga.dart';
import '../services/api_service.dart';
import '../widgets/manga_card.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Manga> _allManga = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await ApiService.getAllManga();
      setState(() {
        _allManga = data;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressPath()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 40, color: Color(0xFFBA541E)),
                const SizedBox(height: 12),
                const Text(
                  'Không tải được dữ liệu truyện',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
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
                    _fetchData();
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      );
    }

    if (_allManga.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: Text(
            'Chưa có truyện để hiển thị',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Banner/Carousel Area
          SliverToBoxAdapter(child: _buildBanner()),

          // Last Updates (Horizontal Scroll)
          SliverToBoxAdapter(
            child: _buildHorizontalSection("Last Updates", _allManga),
          ),

          // Most Viewed (Grid View as requested, maybe grid with 2 columns)
          SliverToBoxAdapter(
            child: _buildSectionHeader("Most Viewed", showGenreBtn: true),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 170,
                childAspectRatio: 0.62,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return MangaCard(
                    // We just reverse or shuffle to simulate diff data
                    manga:
                        _allManga[(_allManga.length - 1 - index) %
                            _allManga.length],
                    isGrid: true,
                  );
                },
                childCount: _allManga.length > 4
                    ? 4
                    : _allManga.length, // Limit to 4 for grid
              ),
            ),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 16)),

          // For You (Horizontal Scroll)
          SliverToBoxAdapter(
            child: _buildHorizontalSection(
              "For you",
              _allManga.reversed.toList(),
            ),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 30)),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBanner() {
    return Container(
      height: 220,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F7),
        image: DecorationImage(
          image: NetworkImage(
            'https://via.placeholder.com/600x300/ffccaa/ffffff?text=Frieren+Banner',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: CircleAvatar(
              backgroundColor: const Color(0xFFE8742B),
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool showGenreBtn = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFBA541E), // Match app theme
            ),
          ),
          if (showGenreBtn)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8742B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Genres >',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalSection(String title, List<Manga> mangas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title),
        SizedBox(
          height: 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: mangas.length,
            itemBuilder: (context, index) {
              return MangaCard(manga: mangas[index], width: 110, height: 160);
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      selectedItemColor: const Color(0xFFE8742B),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      onTap: (index) {
        if (index == 2) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SearchScreen()),
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

class CircularProgressPath extends StatelessWidget {
  const CircularProgressPath({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator(color: Color(0xFFE8742B));
  }
}
