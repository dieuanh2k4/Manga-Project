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
import '../../domain/entities/history_item_entity.dart';
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
  final Set<String> _expandedHistoryGroups = {'Hôm nay', 'Hôm qua'};
  bool _groupHistoryByTime = true;

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
      create: (_) =>
          LibraryController(
              getLibraryMangaUseCase: context.read(),
              getHistoryUseCase: context.read(),
              addMangaToLibraryUseCase: context.read(),
              deleteMangaFromLibraryUseCase: context.read(),
            )
            ..fetchLibraryManga(widget.token)
            ..fetchHistory(widget.token),
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
                  if (_tabController.index == 1)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          const Spacer(),
                          const Text(
                            'Nhóm theo thời gian',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _groupHistoryByTime,
                            activeColor: _primaryColor,
                            onChanged: (value) {
                              setState(() {
                                _groupHistoryByTime = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  Expanded(child: _buildBody(controller)),
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

    if (_tabController.index == 1) {
      final filteredHistory = _filterHistory(controller.historyItems);
      if (filteredHistory.isEmpty) {
        return const Center(child: Text('Lịch sử đọc của bạn trống.'));
      }
      return _groupHistoryByTime
          ? _buildHistoryGroupedList(filteredHistory)
          : _buildHistoryGrid(filteredHistory);
    }

    final filtered = _filterManga(controller.libraryManga);
    if (filtered.isEmpty) {
      return const Center(child: Text('Thư viện của bạn trống.'));
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

  List<HistoryItemEntity> _filterHistory(List<HistoryItemEntity> input) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return input;
    }
    return input.where((item) {
      final titleMatch = item.title.toLowerCase().contains(query);
      final authorMatch = (item.authorName ?? '').toLowerCase().contains(query);
      return titleMatch || authorMatch;
    }).toList();
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

  Widget _buildHistoryGroupedList(List<HistoryItemEntity> items) {
    final grouped = _groupHistoryByRange(items);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final entry in grouped.entries)
          if (entry.value.isNotEmpty)
            _buildHistoryRangeSection(entry.key, entry.value),
      ],
    );
  }

  Widget _buildHistoryGrid(List<HistoryItemEntity> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 380 ? 2 : 3;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.58,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _HistoryGridItem(item: items[index]);
          },
        );
      },
    );
  }

  Widget _buildDownloadsList(List<LibraryMangaEntity> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: _dividerColor),
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

  Map<String, List<HistoryItemEntity>> _groupHistoryByRange(
    List<HistoryItemEntity> items,
  ) {
    const rangeOrder = [
      'Hôm nay',
      'Hôm qua',
      'Tuần này',
      'Tháng này',
      'Cũ hơn',
    ];
    final sorted = [...items]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final Map<String, List<HistoryItemEntity>> grouped = {
      for (final range in rangeOrder) range: [],
    };
    for (final item in sorted) {
      final range = _historyRangeLabel(item.updatedAt);
      grouped.putIfAbsent(range, () => []).add(item);
    }
    return grouped;
  }

  String _historyRangeLabel(DateTime updatedAt) {
    final now = DateTime.now();
    final local = updatedAt.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(local.year, local.month, local.day);
    final diff = today.difference(itemDay).inDays;

    if (diff == 0) {
      return 'Hôm nay';
    }
    if (diff == 1) {
      return 'Hôm qua';
    }

    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final isSameWeek =
        itemDay.isAtSameMomentAs(weekStart) || itemDay.isAfter(weekStart);
    if (isSameWeek) {
      return 'Tuần này';
    }

    final isSameMonth =
        itemDay.year == today.year && itemDay.month == today.month;
    if (isSameMonth) {
      return 'Tháng này';
    }
    return 'Cũ hơn';
  }

  List<MapEntry<DateTime, List<HistoryItemEntity>>> _groupHistoryByDay(
    List<HistoryItemEntity> items,
  ) {
    final Map<DateTime, List<HistoryItemEntity>> grouped = {};
    for (final item in items) {
      final local = item.updatedAt.toLocal();
      final dayKey = DateTime(local.year, local.month, local.day);
      grouped.putIfAbsent(dayKey, () => []).add(item);
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return entries;
  }

  String _formatDayLabel(DateTime day) {
    final dayStr = day.day.toString().padLeft(2, '0');
    final monthStr = day.month.toString().padLeft(2, '0');
    return '$dayStr/$monthStr/${day.year}';
  }

  Widget _buildHistoryRangeSection(
    String range,
    List<HistoryItemEntity> items,
  ) {
    final isExpanded = _expandedHistoryGroups.contains(range);
    final dayGroups = _groupHistoryByDay(items);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      initiallyExpanded: isExpanded,
      onExpansionChanged: (expanded) {
        setState(() {
          if (expanded) {
            _expandedHistoryGroups.add(range);
          } else {
            _expandedHistoryGroups.remove(range);
          }
        });
      },
      title: Text(
        range,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _primaryDark,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, right: 6, bottom: 8),
          child: Column(
            children: [
              if (range == 'Cũ hơn')
                ..._buildHistoryItems(items)
              else
                for (final entry in dayGroups) ...[
                  _buildHistoryDayHeader(_formatDayLabel(entry.key)),
                  ..._buildHistoryItems(entry.value),
                ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryDayHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildHistoryItems(List<HistoryItemEntity> items) {
    final sorted = [...items]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final widgets = <Widget>[];
    for (final item in sorted) {
      widgets.add(_HistoryListItem(item: item));
      widgets.add(const Divider(height: 1, color: _dividerColor));
    }
    return widgets;
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
          MaterialPageRoute(builder: (_) => MangaDetailPage(mangaId: manga.id)),
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
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
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

class _HistoryListItem extends StatelessWidget {
  final HistoryItemEntity item;

  const _HistoryListItem({required this.item});

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
    final chapterLabel = (item.lastChapterNumber == null ||
        item.lastChapterNumber!.trim().isEmpty)
      ? item.lastChapterId.toString()
      : item.lastChapterNumber!.trim();
    final subtitle = item.isCompleted
        ? 'Đã hoàn thành'
      : 'Đọc tiếp Chapter $chapterLabel';
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MangaDetailPage(mangaId: item.mangaId),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ProtectedNetworkImage(
                imageUrl: _getImageUrl(item.thumbnail),
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
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  if ((item.authorName ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.authorName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryGridItem extends StatelessWidget {
  final HistoryItemEntity item;

  const _HistoryGridItem({required this.item});

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
    final chapterLabel = (item.lastChapterNumber == null ||
        item.lastChapterNumber!.trim().isEmpty)
      ? item.lastChapterId.toString()
      : item.lastChapterNumber!.trim();
    final subtitle = item.isCompleted
        ? 'Đã hoàn thành'
      : 'Đọc tiếp Chapter $chapterLabel';
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MangaDetailPage(mangaId: item.mangaId),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ProtectedNetworkImage(
              imageUrl: _getImageUrl(item.thumbnail),
              width: double.infinity,
              height: 150,
              fit: BoxFit.cover,
              errorWidget: Container(
                height: 150,
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported_outlined),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
