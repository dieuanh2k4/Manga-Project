import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../../core/presentation/widgets/top_bar.dart';
import '../widgets/manga_card.dart';
import '../widgets/hottest_item.dart';
import '../../data/models/manga_mock.dart'; // We'll create this to feed mock data
import '../../data/data_sources/manga_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Manga>> _mangaListFuture;
  final MangaService _mangaService = MangaService();

  @override
  void initState() {
    super.initState();
    // Gọi API khi màn hình khởi tạo
    _mangaListFuture = _mangaService.fetchAllManga();
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.transparent, // Làm trong suốt nền web để thấy ảnh
      appBar: const TopBar(),
      body: Container(
        decoration: const BoxDecoration(
          // Dùng 1 ảnh đen nhám hoặc ảnh manga mờ làm background toàn web
          image: DecorationImage(
            image: AssetImage('assets/images/update_back.52cd45fd.jpeg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black87, BlendMode.darken), // Làm tối ảnh để chữ dễ đọc
          ),
        ),
        child: Center( // Căn giữa nội dung
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1300), // Max width cho màn hình lớn
            child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column - Mới cập nhật (chiếm khoảng lớn)
                Expanded(
                  flex: 7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Mới cập nhật 24h', showTimeIcon: true),
                      const SizedBox(height: 16),
                      // Dữ liệu từ API Backend cho Big Banner
                      _buildBigBannerFromApi(),
                      const SizedBox(height: 24),
                      // Grid 4 cột cho các manga mới
                      _buildMangaGrid(),
                      const SizedBox(height: 24),
                      // Ads or Banners
                      _buildMiddleBanners(),
                      const SizedBox(height: 24),
                      // Xem thêm manga...
                      _buildMangaGrid2FromApi(),
                    ],
                  ),
                ),
                const SizedBox(width: 48), // Khoảng cách giữa 2 cột thư mục
                // Right Column - Hottest 
                Expanded(
                  flex: 3,
                  child: _buildHottestSidebarFromApi(),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool showTimeIcon = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (showTimeIcon) ...[
              const Icon(Icons.access_time, color: Colors.redAccent, size: 24),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBigBannerFromApi() {
    return FutureBuilder<List<Manga>>(
      future: _mangaListFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 350, child: Center(child: CircularProgressIndicator(color: Colors.redAccent)));
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildBigBanner(); // Chứa sẵn bản Fallback nếu API sập
        }

        var mangas = snapshot.data!;
        var topMangas = mangas.take(5).toList(); // Lấy 5 truyện đầu làm Banner

        return CarouselSlider(
          options: CarouselOptions(
            height: 350.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            viewportFraction: 1.0,
            enlargeCenterPage: false,
          ),
          items: topMangas.map((manga) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(manga.thumbnail),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                        begin: Alignment.bottomLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Mới cập nhật 24h', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          manga.title,
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          manga.authorName,
                          style: const TextStyle(fontSize: 20, color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              manga.latestChapter,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${manga.views} lượt xem',
                              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      }
    );
  }

  Widget _buildBigBanner() {
    final List<Map<String, String>> banners = [
      {
        'title': 'Đỉnh Núi Ma Ám',
        'author': 'Ryo Minenami',
        'chap': '#001',
        'views': '23.2K',
        'img': 'https://images.unsplash.com/photo-1493246507139-91e8fad9978e?q=80&w=1200'
      },
      {
        'title': 'Chuyến Phiêu Lưu Bí Ẩn',
        'author': 'Masashi Kishimoto',
        'chap': '#700',
        'views': '999.9K',
        'img': 'https://images.unsplash.com/photo-1518770660439-4636190af475?q=80&w=1200'
      },
      {
        'title': 'One Piece Cực Dài',
        'author': 'Eiichiro Oda',
        'chap': '#1110',
        'views': '2.4M',
        'img': 'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?q=80&w=1200'
      },
    ];

    return CarouselSlider(
      options: CarouselOptions(
        height: 350.0,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 4),
        viewportFraction: 1.0, // Hình ảnh tràn đầy khung
        enlargeCenterPage: false,
      ),
      items: banners.map((banner) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(banner['img']!),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                    begin: Alignment.bottomLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Mới cập nhật 24h', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      banner['title']!,
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      banner['author']!,
                      style: const TextStyle(fontSize: 20, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          banner['chap']!,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${banner['views']} lượt xem',
                          style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildMangaGrid() {
    return FutureBuilder<List<Manga>>(
      future: _mangaListFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Khi đang lấy dữ liệu API
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(color: Colors.redAccent),
            ),
          );
        } else if (snapshot.hasError) {
          // Báo lỗi nếu server chết hoặc URL sai
          return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // Server rỗng data
          return const Center(child: Text('Không có truyện nào trên hệ thống', style: TextStyle(color: Colors.white)));
        }

        // Lấy dữ liệu thành công -> render ra Grid
        var mangas = snapshot.data!;
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 24,
            childAspectRatio: 0.65,
          ),
          itemCount: mangas.length < 8 ? mangas.length : 8, // Hiển thị tạm 8 truyện
          itemBuilder: (context, index) {
            return MangaCard(manga: mangas[index]);
          },
        );
      }
    );
  }
  
  Widget _buildMangaGrid2FromApi() {
    return FutureBuilder<List<Manga>>(
      future: _mangaListFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: Colors.redAccent)));
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildMangaGrid2(); // fallback mock
        }

        var mangas = snapshot.data!;
        // Đảo ngược danh sách cho mục bên dưới
        var reversedList = mangas.reversed.toList();
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 24,
            childAspectRatio: 0.65, 
          ),
          itemCount: reversedList.length < 8 ? reversedList.length : 8,
          itemBuilder: (context, index) {
            return MangaCard(manga: reversedList[index]);
          },
        );
      }
    );
  }

  Widget _buildMangaGrid2() {
    // Dùng lại list test nhưng đảo ngược để ra danh sách khac
    var reversedList = mockMangaList.reversed.toList();
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 24,
        childAspectRatio: 0.65, 
      ),
      itemCount: reversedList.length,
      itemBuilder: (context, index) {
        return MangaCard(manga: reversedList[index]);
      },
    );
  }

  Widget _buildMiddleBanners() {
    final List<Map<String, dynamic>> ads = [
      {'color': Colors.blueAccent, 'title': 'Truyện Hành Động', 'img': 'https://images.unsplash.com/photo-1542204165-65bf26472b9b?q=80&w=800'},
      {'color': Colors.purpleAccent, 'title': 'Lãng Mạn Cảm Động', 'img': 'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?q=80&w=800'},
      {'color': Colors.orangeAccent, 'title': 'Thế Giới Fantasy', 'img': 'https://images.unsplash.com/photo-1618331835717-801e976710b2?q=80&w=800'},
      {'color': Colors.teal, 'title': 'Hài Hước Giải Trí', 'img': 'https://images.unsplash.com/photo-1513360371669-4adf3dd7dff8?q=80&w=800'},
    ];

    return CarouselSlider(
      options: CarouselOptions(
        height: 120.0,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 5), // Lướt chậm hơn banner chính 1 chút
        viewportFraction: 0.5, // 2 Banner nằm cùng 1 dòng
        enlargeCenterPage: false,
        padEnds: false,
      ),
      items: ads.map((ad) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: ad['color'],
                image: DecorationImage(
                  image: NetworkImage(ad['img']),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
                )
              ),
              alignment: Alignment.center,
              child: Text(ad['title'], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildHottestSidebarFromApi() {
    return FutureBuilder<List<Manga>>(
      future: _mangaListFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: Colors.redAccent)));
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildHottestSidebar(); // Fallback khi lỗi
        }

        var mangas = snapshot.data!;
        // Giả lập sắp xếp theo lượt rate cao xuống thấp lấy 10 bộ đầu tiên
        var hottestList = List<Manga>.from(mangas);
        hottestList.sort((a, b) => b.views.compareTo(a.views));
        var top10 = hottestList.take(10).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nổi bật nhất',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Xem tất cả >', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: top10.length,
              separatorBuilder: (_, __) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                return HottestItem(
                  manga: top10[index],
                  rank: index + 1,
                );
              },
            ),
          ],
        );
      }
    );
  }

  Widget _buildHottestSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Nổi bật nhất',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Xem tất cả >', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: mockHottestList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 20),
          itemBuilder: (context, index) {
            return HottestItem(
              manga: mockHottestList[index],
              rank: index + 1,
            );
          },
        ),
      ],
    );
  }
}
