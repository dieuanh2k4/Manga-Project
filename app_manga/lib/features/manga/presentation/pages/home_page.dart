import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/notifications/fcm_notification_service.dart';
import '../../domain/entities/manga_entity.dart';
import '../controllers/home_controller.dart';
import '../widgets/manga_card.dart';
import '../../../auth/presentation/pages/me_page.dart';
import '../../../library/presentation/pages/library_page.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../notification/presentation/controllers/notification_controller.dart';
import '../../../notification/presentation/pages/notification_page.dart';
import 'manga_detail_page.dart';
import 'search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeController>().loadManga();
      final token = context.read<AuthController>().session?.token;
      if (token != null) {
        context.read<NotificationController>().fetchUnreadCount(token);
      }
    });

    _notificationSubscription =
        FcmNotificationService.instance.foregroundMessages.listen((_) {
      if (!mounted) {
        return;
      }

      final token = context.read<AuthController>().session?.token;
      if (token == null) {
        return;
      }

      final notificationController = context.read<NotificationController>();
      notificationController.fetchNotifications(token);
      notificationController.fetchUnreadCount(token);
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();
    final allManga = controller.mangas;

    if (controller.isLoading) {
      return const Scaffold(
        key: Key('home_loading'),
        body: Center(child: CircularProgressPath()),
      );
    }

    if (controller.errorMessage != null) {
      return Scaffold(
        key: const Key('home_error'),
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
                  'Không tải được dữ liệu manga',
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
                  child: const Text('Thử lại'),
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
        key: const Key('home_empty'),
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
      key: const Key('home_page'),
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildBanner()),
          SliverToBoxAdapter(
            child: _buildHorizontalSection(
              'Mới cập nhật',
              allManga,
              onViewMore: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const SearchPage(initialTabIndex: 1),
                  ),
                );
              },
              cardWidth: 170,
              cardHeight: 250,
              listHeight: 270,
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'Phổ biến',
              actionLabel: 'Xem thêm',
              onAction: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const SearchPage(initialTabIndex: 0),
                  ),
                );
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 170,
                mainAxisExtent: 270,
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
          SliverToBoxAdapter(child: const SizedBox(height: 30)),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBanner() {
    final unreadCount = context.watch<NotificationController>().unreadCount;
    const previewSlides = [
      {
        'title': 'Hot pick #1',
        'subtitle': 'Cho manga vào đây',
        'colors': [Color(0xFFFFD3A0), Color(0xFFF59E5B)],
      },
      {
        'title': 'Hot pick #2',
        'subtitle': 'Cho manga vào đây',
        'colors': [Color(0xFFFFE6C7), Color(0xFFED7B2A)],
      },
      {
        'title': 'Hot pick #3',
        'subtitle': 'Cho manga vào đây',
        'colors': [Color(0xFFFFE1B6), Color(0xFFE46C1B)],
      },
      {
        'title': 'Hot pick #4',
        'subtitle': 'Cho manga vào đây',
        'colors': [Color(0xFFFFD4A8), Color(0xFFD85B16)],
      },
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/daruma.png',
                        width: 30,
                        height: 30,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'MangaMINUS',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          fontFamily: 'Georgia',
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(
                          tooltip: 'Thông báo',
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: Color(0xFFBA541E),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const NotificationPage(),
                              ),
                            );
                          },
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              unreadCount > 99
                                  ? '99+'
                                  : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 240,
            child: PageView.builder(
              itemCount: previewSlides.length,
              itemBuilder: (context, index) {
                final slide = previewSlides[index];
                final colors = slide['colors']! as List<Color>;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slide['title']! as String,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          slide['subtitle']! as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
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
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFE8742B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalSection(
    String title,
    List<MangaEntity> mangas, {
    required VoidCallback onViewMore,
    double cardWidth = 150,
    double cardHeight = 220,
    double listHeight = 240,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title,
          actionLabel: 'Xem thêm >',
          onAction: onViewMore,
        ),
        SizedBox(
          height: listHeight,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: mangas.length,
            itemBuilder: (context, index) {
              final selected = mangas[index];
              return MangaCard(
                manga: selected,
                width: cardWidth,
                height: cardHeight,
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
      showSelectedLabels: false,
      showUnselectedLabels: false,
      iconSize: 30,
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
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_outlined),
          label: '',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
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
