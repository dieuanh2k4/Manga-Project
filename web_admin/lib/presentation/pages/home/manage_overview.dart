import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/injection_container.dart';
import 'package:web_admin/presentation/controllers/remote_manga_controller.dart';
import 'package:web_admin/presentation/controllers/dashboard_controller.dart';
import 'package:web_admin/presentation/controllers/theme_controller.dart';
import 'package:web_admin/presentation/widgets/manage_manga_sidebar.dart';
import 'package:web_admin/presentation/widgets/manage_manga_top_header.dart';
import 'package:web_admin/presentation/widgets/dashboard_charts.dart';
import 'package:web_admin/data/models/dashboard_dto.dart';
import 'package:web_admin/presentation/pages/home/manage_manga.dart';
import 'package:web_admin/presentation/pages/home/manage_authors.dart';
import 'package:web_admin/presentation/pages/home/manage_users.dart';
import 'package:web_admin/presentation/pages/home/manage_vip_packages.dart';
import 'package:web_admin/presentation/pages/home/manage_notifications.dart';

class ManageOverview extends StatefulWidget {
  final RemoteMangaController mangaController;
  final Future<void> Function()? onLogout;

  const ManageOverview({
    super.key,
    required this.mangaController,
    this.onLogout,
  });

  @override
  State<ManageOverview> createState() => _ManageOverviewState();
}

class _ManageOverviewState extends State<ManageOverview> {
  late final DashboardController _dashboardController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dashboardController = sl<DashboardController>();
    _dashboardController.loadDashboardStats();
    _dashboardController.loadRecentActivities();
    _dashboardController.startActivityPolling(intervalSeconds: 60);
  }

  @override
  void dispose() {
    _dashboardController.stopActivityPolling();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onNestedRouteLogout() async {
    Navigator.of(context).popUntil((route) => route.isFirst);
    await widget.onLogout?.call();
  }

  void _openNotificationsPage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ManageNotifications(
          mangaController: widget.mangaController,
          onLogout: _onNestedRouteLogout,
        ),
      ),
    );
  }

  void _openMangaPage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ManageManga(
          mangaController: widget.mangaController,
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = sl<ThemeController>();

    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final isDark = themeController.isDarkMode;

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isCompactSidebar = constraints.maxWidth < 1120;
            final double shellHeight = (constraints.maxHeight - 24)
                .clamp(620.0, 920.0)
                .toDouble();

            final scaffoldBg = isDark ? const Color(0xFF1A1D2E) : const Color(0xFFDFE3ED);
            final shellBg = isDark ? const Color(0xFF0E1326) : Colors.white;
            final shellBorder = isDark ? const Color(0xFF1E2640) : const Color(0xFFE2E8F0);

            return Scaffold(
              backgroundColor: scaffoldBg,
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
                            color: shellBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: shellBorder, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
                                blurRadius: 32,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Row(
                              children: [
                                ManageMangaSidebar(
                                  compact: isCompactSidebar,
                                  selectedKey: sidebarKeyOverview,
                                  onSelect: (key) {
                                    if (key == sidebarKeyManga) {
                                      _openMangaPage();
                                    } else if (key == sidebarKeyAuthors) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => ManageAuthors(
                                            mangaController: widget.mangaController,
                                            onLogout: _onNestedRouteLogout,
                                          ),
                                        ),
                                      );
                                    } else if (key == sidebarKeyUsers) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => ManageUsers(
                                            mangaController: widget.mangaController,
                                            onLogout: _onNestedRouteLogout,
                                          ),
                                        ),
                                      );
                                    } else if (key == sidebarKeyVip) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => ManageVipPackages(
                                            mangaController: widget.mangaController,
                                            onLogout: _onNestedRouteLogout,
                                          ),
                                        ),
                                      );
                                    } else if (key == sidebarKeyNotifications) {
                                      _openNotificationsPage();
                                    }
                                  },
                                ),
                                Expanded(child: _buildMainContent(context, isDark)),
                              ],
                            ),
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
      },
    );
  }

  Widget _buildMainContent(BuildContext context, bool isDark) {
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white70.withOpacity(0.6) : const Color(0xFF64748B);

    return Container(
      color: isDark ? const Color(0xFF080C1B) : const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // Standard Top Header integrated dynamically
          ManageMangaTopHeader(
            searchController: _searchController,
            onLogout: _onNestedRouteLogout,
            onNotificationTap: _openNotificationsPage,
            customHeaderWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF512F).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    size: 18,
                    color: Color(0xFFFF512F),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tổng quan Hệ thống',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Báo cáo phân tích hoạt động kinh doanh thực tế',
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white70 : const Color(0xFF64748B), size: 18),
                  tooltip: 'Làm mới số liệu',
                  onPressed: () => _dashboardController.loadDashboardStats(),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListenableBuilder(
              listenable: _dashboardController,
              builder: (context, _) {
                final state = _dashboardController.state;

                if (state is DashboardLoading) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CupertinoActivityIndicator(radius: 16, color: Color(0xFFFF512F)),
                        const SizedBox(height: 14),
                        Text(
                          'Đang tổng hợp số liệu thực tế...',
                          style: TextStyle(color: isDark ? const Color(0xFF8491A7) : const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  );
                }

                if (state is DashboardError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Lỗi kết nối cơ sở dữ liệu backend',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A), 
                              fontSize: 16, 
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            state.errorMessage ?? '',
                            style: TextStyle(color: isDark ? const Color(0xFF8491A7) : const Color(0xFF64748B), fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _dashboardController.loadDashboardStats(),
                            child: const Text('Thử lại'),
                          )
                        ],
                      ),
                    ),
                  );
                }

                if (state is DashboardDone && state.stats != null) {
                  final stats = state.stats!;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildKpiHeroGrid(stats),
                        const SizedBox(height: 20),
                        _buildChartsHub(stats),
                        const SizedBox(height: 20),
                        _buildBottomRow(stats, isDark),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiHeroGrid(DashboardModel stats) {
    final formatCurrency = NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool stacked = constraints.maxWidth < 600;
        final bool twoColumn = constraints.maxWidth >= 600 && constraints.maxWidth < 1100;

        final List<Widget> cards = [
          _buildKpiCard(
            label: 'TỔNG DOANH THU',
            value: formatCurrency.format(stats.totalRevenue),
            icon: Icons.monetization_on_rounded,
            gradientColors: [const Color(0xFFFF512F), const Color(0xFFDD2476)],
          ),
          _buildKpiCard(
            label: 'ĐỘC GIẢ HOẠT ĐỘNG',
            value: '${stats.activeReadersCount}',
            icon: Icons.people_alt_rounded,
            gradientColors: [const Color(0xFF02AAB0), const Color(0xFF00CDAC)],
          ),
          _buildKpiCard(
            label: 'TỔNG LƯỢT ĐỌC CHƯƠNG',
            value: '${stats.totalViews}',
            icon: Icons.menu_book_rounded,
            gradientColors: [const Color(0xFFF09819), const Color(0xFFEDDE5D)],
          ),
          _buildKpiCard(
            label: 'TỶ LỆ VIP',
            value: '${stats.vipConversionRate}%',
            icon: Icons.stars_rounded,
            gradientColors: [const Color(0xFF8A2387), const Color(0xFFE94057)],
          ),
        ];

        if (stacked) {
          return Column(
            children: cards.map((card) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: card,
            )).toList(),
          );
        }

        if (twoColumn) {
          final double cardWidth = (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards.map((card) => SizedBox(width: cardWidth, child: card)).toList(),
          );
        }

        return Row(
          children: cards.map((card) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: card,
            ),
          )).toList(),
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return StatefulBuilder(
      builder: (context, setCardState) {
        bool isHovered = false;

        return MouseRegion(
          onEnter: (_) => setCardState(() => isHovered = true),
          onExit: (_) => setCardState(() => isHovered = false),
          child: AnimatedScale(
            scale: isHovered ? 1.03 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.last.withOpacity(isHovered ? 0.45 : 0.25),
                    blurRadius: isHovered ? 20 : 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChartsHub(DashboardModel stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isColumn = constraints.maxWidth < 950;
        final double width = isColumn ? constraints.maxWidth : (constraints.maxWidth - 20) / 2;

        final List<Widget> children = [
          _buildChartContainer(
            title: 'DOANH THU & VIP (30 NGÀY QUA)',
            subtitle: 'Đường cong tăng trưởng theo thời gian thực',
            width: width,
            height: 280,
            child: DashboardLineChart(data: stats.revenueHistory),
          ),
          _buildChartContainer(
            title: 'THỂ LOẠI ĐƯỢC ĐỌC NHIỀU NHẤT',
            subtitle: 'Phần trăm quan tâm của độc giả hệ thống',
            width: width,
            height: 280,
            child: DashboardBarChart(data: stats.genreShare),
          ),
        ];

        if (isColumn) {
          return Column(
            children: [
              children[0],
              const SizedBox(height: 20),
              children[1],
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children,
        );
      },
    );
  }

  Widget _buildChartContainer({
    required String title,
    required String subtitle,
    required double width,
    required double height,
    required Widget child,
  }) {
    final isDark = sl<ThemeController>().isDarkMode;

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1326) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2640) : const Color(0xFFE2E8F0), 
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white.withOpacity(0.4) : const Color(0xFF64748B),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.analytics_outlined, 
                color: isDark ? Colors.white24 : const Color(0xFFABB3C2), 
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildBottomRow(DashboardModel stats, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isColumn = constraints.maxWidth < 950;
        final double leftWidth = isColumn ? constraints.maxWidth : constraints.maxWidth * 0.40 - 10;
        final double rightWidth = isColumn ? constraints.maxWidth : constraints.maxWidth * 0.60 - 10;

        final List<Widget> children = [
          _buildLiveFeedWidget(leftWidth, isDark),
          _buildTopMangaTable(stats.topManga, rightWidth, isDark),
        ];

        if (isColumn) {
          return Column(
            children: [
              children[0],
              const SizedBox(height: 20),
              children[1],
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );
      },
    );
  }

  Widget _buildLiveFeedWidget(double width, bool isDark) {
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderCol = isDark ? const Color(0xFF1E2640) : const Color(0xFFE2E8F0);
    final itemTextCol = isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF334155);
    final itemTimeCol = isDark ? Colors.white.withOpacity(0.3) : const Color(0xFF94A3B8);

    return Container(
      width: width,
      height: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1326) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LUỒNG HOẠT ĐỘNG LIVE',
                style: TextStyle(
                  color: titleColor, 
                  fontSize: 12, 
                  fontWeight: FontWeight.w800, 
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.fiber_manual_record, color: Colors.green, size: 8),
                    SizedBox(width: 4),
                    Text('TRỰC TUYẾN', style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.w700)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListenableBuilder(
              listenable: _dashboardController,
              builder: (context, _) {
                final activities = _dashboardController.recentActivities;
                final isLoading = _dashboardController.activitiesLoading;

                if (isLoading && activities.isEmpty) {
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF512F)),
                    ),
                  );
                }

                if (activities.isEmpty) {
                  return Center(
                    child: Text(
                      'Chưa có hoạt động nào',
                      style: TextStyle(color: itemTimeCol, fontSize: 11),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: activities.length,
                  separatorBuilder: (_, __) => Divider(
                    color: isDark ? const Color(0xFF1E2640) : const Color(0xFFF1F5F9),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final act = activities[index];

                    Color iconColor;
                    IconData iconData;

                    switch (act.type) {
                      case 'vip':
                        iconColor = const Color(0xFFFF512F);
                        iconData = Icons.stars_rounded;
                        break;
                      case 'register':
                      default:
                        iconColor = const Color(0xFF00CDAC);
                        iconData = Icons.person_add_rounded;
                        break;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(iconData, color: iconColor, size: 14),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  act.message,
                                  style: TextStyle(color: itemTextCol, fontSize: 10, height: 1.4),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  DateFormat('HH:mm:ss').format(act.timestamp),
                                  style: TextStyle(
                                    color: itemTimeCol,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTopMangaTable(List<MangaRankModel> list, double width, bool isDark) {
    final formatCurrency = NumberFormat.simpleCurrency(locale: 'vi_VN', decimalDigits: 0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderCol = isDark ? const Color(0xFF1E2640) : const Color(0xFFE2E8F0);
    final tableCellTextCol = isDark ? Colors.white70 : const Color(0xFF334155);
    final labelStyleCol = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Container(
      width: width,
      height: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1326) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BẢNG XẾP HẠNG TOP MANGA',
                style: TextStyle(
                  color: titleColor, 
                  fontSize: 12, 
                  fontWeight: FontWeight.w800, 
                  letterSpacing: 0.5,
                ),
              ),
              const Icon(Icons.emoji_events_outlined, color: Color(0xFFF09819), size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: max(width - 32, 540),
                child: DataTable(
                  columnSpacing: 10,
                  horizontalMargin: 4,
                  headingRowHeight: 28,
                  dataRowMinHeight: 45,
                  dataRowMaxHeight: 45,
                  dividerThickness: 0.5,
                  columns: [
                    DataColumn(label: Text('MANGA', style: TextStyle(color: labelStyleCol, fontSize: 9, fontWeight: FontWeight.w700))),
                    DataColumn(label: Text('LƯỢT ĐỌC', style: TextStyle(color: labelStyleCol, fontSize: 9, fontWeight: FontWeight.w700))),
                    DataColumn(label: Text('ĐÁNH GIÁ', style: TextStyle(color: labelStyleCol, fontSize: 9, fontWeight: FontWeight.w700))),
                    DataColumn(label: Text('ĐIỂM SỐ', style: TextStyle(color: labelStyleCol, fontSize: 9, fontWeight: FontWeight.w700))),
                    DataColumn(label: Text('D.THU ƯỚC TÍNH', style: TextStyle(color: labelStyleCol, fontSize: 9, fontWeight: FontWeight.w700))),
                  ],
                  rows: list.map((manga) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  width: 22,
                                  height: 32,
                                  color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                                  child: manga.thumbnail.isNotEmpty
                                      ? Image.network(
                                          manga.thumbnail,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(Icons.image, size: 12, color: isDark ? Colors.white24 : Colors.grey),
                                        )
                                      : Icon(Icons.image, size: 12, color: isDark ? Colors.white24 : Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 110,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      manga.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF0F172A), 
                                        fontSize: 10, 
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      manga.authorName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isDark ? Colors.white.withOpacity(0.4) : const Color(0xFF64748B), 
                                        fontSize: 8,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            '${manga.views}',
                            style: TextStyle(color: tableCellTextCol, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                '${manga.rating}',
                                style: TextStyle(color: tableCellTextCol, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF512F).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${manga.score}',
                              style: const TextStyle(color: Color(0xFFFF512F), fontSize: 9, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            formatCurrency.format(manga.estimatedRevenue),
                            style: const TextStyle(color: Color(0xFF00CDAC), fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
