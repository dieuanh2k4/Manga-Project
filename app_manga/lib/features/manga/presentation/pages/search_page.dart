import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/manga_entity.dart';
import '../controllers/search_controller.dart';
import 'home_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MangaSearchController>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MangaSearchController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : controller.errorMessage != null
                ? _buildError(controller)
                : Column(
                    children: [
                      _buildSearchBar(controller),
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
                            _buildMangaList(
                              controller.popularItems(),
                              isUpdateList: false,
                            ),
                            _buildMangaList(
                              controller.lastUpdateItems(),
                              isUpdateList: true,
                            ),
                            _buildDirectoryTab(controller),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildError(MangaSearchController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 40, color: Color(0xFFBA541E)),
            const SizedBox(height: 12),
            const Text(
              'Khong tai duoc du lieu Search',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.initialize(),
              child: const Text('Thu lai'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(MangaSearchController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: controller.onSearchChanged,
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
    List<MangaEntity> items, {
    required bool isUpdateList,
    bool isEmbedded = false,
  }) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Khong co du lieu',
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
      separatorBuilder: (context, separatorIndex) =>
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
                  errorBuilder: (context, error, stackTrace) => Container(
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
                        fontSize: 20,
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
                          const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
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

  Widget _buildDirectoryTab(MangaSearchController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status',
            style: TextStyle(fontSize: 21, color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: ['Continuous', 'Complete', 'New']
                .map(
                  (status) => GestureDetector(
                    onTap: () => controller.selectStatus(status),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 20,
                        color: controller.selectedStatus == status
                            ? const Color(0xFFCC5A15)
                            : const Color(0xFF333333),
                        decoration: controller.selectedStatus == status
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
            style: TextStyle(fontSize: 21, color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 22,
            runSpacing: 18,
            children: controller.genres
                .map(
                  (genre) => GestureDetector(
                    onTap: () => controller.toggleGenre(genre),
                    child: Text(
                      genre.name,
                      style: TextStyle(
                        fontSize: 20,
                        color: controller.selectedGenre?.id == genre.id
                            ? const Color(0xFFCC5A15)
                            : const Color(0xFF333333),
                        decoration: controller.selectedGenre?.id == genre.id
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
          if (controller.isFilteringGenre)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            _buildMangaList(
              controller.directoryItems(),
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
            MaterialPageRoute(builder: (_) => const HomePage()),
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
