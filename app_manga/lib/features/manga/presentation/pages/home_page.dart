import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/manga_entity.dart';
import '../controllers/home_controller.dart';
import '../widgets/manga_card.dart';
import '../../../auth/presentation/pages/me_page.dart';
import '../../../library/presentation/pages/library_page.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'package:provider/provider.dart';
import 'manga_detail_page.dart';
import 'search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeController>().loadManga();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();
    final allManga = controller.mangas;

    if (controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressPath()));
    }

    if (controller.errorMessage != null) {
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
                  'Khong tai duoc du lieu truyen',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  controller.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.loadManga(),
                  child: const Text('Thu lai'),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      );
    }

    if (allManga.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: Text(
            'Chua co truyen de hien thi',
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
          SliverToBoxAdapter(child: _buildBanner()),
          SliverToBoxAdapter(
            child: _buildHorizontalSection('Last Updates', allManga),
          ),
          SliverToBoxAdapter(
            child: _buildSectionHeader('Most Viewed', showGenreBtn: true),
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
                    manga: allManga[(allManga.length - 1 - index) % allManga.length],
                    isGrid: true,
                    onTap: () {
                      final selected = allManga[(allManga.length - 1 - index) % allManga.length];
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MangaDetailPage(mangaId: selected.id),
                        ),
                      );
                    },
                  );
                },
                childCount: allManga.length > 4 ? 4 : allManga.length,
              ),
            ),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: _buildHorizontalSection('For you', allManga.reversed.toList()),
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
            padding: const EdgeInsets.all(16),
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
              color: Color(0xFFBA541E),
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

  Widget _buildHorizontalSection(String title, List<MangaEntity> mangas) {
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
              final selected = mangas[index];
              return MangaCard(
                manga: selected,
                width: 110,
                height: 160,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MangaDetailPage(mangaId: selected.id),
                    ),
                  );
                },
              );
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
        if (index == 1) {
          final auth = Provider.of<AuthController>(context, listen: false);
          if (auth.session != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => LibraryPage(token: auth.session!.token),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bạn cần đăng nhập để xem thư viện!')),
            );
          }
        }
        if (index == 2) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SearchPage()),
          );
        }
        if (index == 3) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MePage()),
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
  const CircularProgressPath({super.key});

  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator(color: Color(0xFFE8742B));
  }
}
