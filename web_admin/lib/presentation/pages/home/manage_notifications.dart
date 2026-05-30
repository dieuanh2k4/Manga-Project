import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/domain/entities/manga.dart';
import 'package:web_admin/domain/entities/notification.dart' as domain;
import 'package:web_admin/injection_container.dart';
import 'package:web_admin/presentation/controllers/remote_manga_controller.dart';
import 'package:web_admin/presentation/controllers/remote_notification_controller.dart';
import 'package:web_admin/presentation/controllers/theme_controller.dart';
import 'package:web_admin/presentation/pages/home/manage_authors.dart';
import 'package:web_admin/presentation/pages/home/manage_overview.dart';
import 'package:web_admin/presentation/pages/home/manage_manga.dart';
import 'package:web_admin/presentation/pages/home/manage_users.dart';
import 'package:web_admin/presentation/pages/home/manage_vip_packages.dart';
import 'package:web_admin/presentation/pages/home/manage_genres.dart';
import 'package:web_admin/presentation/widgets/manage_manga_sidebar.dart';
import 'package:web_admin/presentation/widgets/manage_manga_top_header.dart';

class ManageNotifications extends StatefulWidget {
  final RemoteMangaController mangaController;
  final Future<void> Function()? onLogout;

  const ManageNotifications({
    super.key,
    required this.mangaController,
    this.onLogout,
  });

  @override
  State<ManageNotifications> createState() => _ManageNotificationsState();
}

class _ManageNotificationsState extends State<ManageNotifications> {
  final RemoteNotificationController _notificationController =
      sl<RemoteNotificationController>();
  final TextEditingController _searchController = TextEditingController();

  String _selectedSort = 'Mới nhất';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onFilterChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationController.loadNotifications();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onFilterChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _openMangaPage() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ManageManga(
          mangaController: widget.mangaController,
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  void _openAuthorsPage() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ManageAuthors(
          mangaController: widget.mangaController,
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  void _openUsersPage() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ManageUsers(
          mangaController: widget.mangaController,
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  void _openGenresPage() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ManageGenres(
          mangaController: widget.mangaController,
          onLogout: widget.onLogout,
        ),
      ),
    );
  }

  Future<void> _showCreateNotificationDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    String targetRole = 'All';
    int selectedMangaId = 0;

    if (widget.mangaController.state is! RemoteMangaDone) {
      await widget.mangaController.loadManga();
    }

    final RemoteMangaState mangaState = widget.mangaController.state;
    final List<MangaEntity> mangas = mangaState is RemoteMangaDone
        ? (mangaState.manga ?? const <MangaEntity>[])
        : const <MangaEntity>[];

    final domain.NotificationEntity?
    notification = await showDialog<domain.NotificationEntity>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tạo thông báo'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      key: const Key('manage_notification_dialog_title_field'),
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key(
                        'manage_notification_dialog_content_field',
                      ),
                      controller: contentController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Nội dung',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: targetRole,
                      decoration: const InputDecoration(
                        labelText: 'Đối tượng nhận',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'All',
                          child: Text('Tất cả người đọc'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'LikedManga',
                          child: Text('Người đọc theo manga'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          targetRole = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: selectedMangaId,
                      decoration: InputDecoration(
                        labelText: targetRole == 'LikedManga'
                            ? 'Chọn Manga'
                            : 'Manga (optional)',
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: 0,
                          child: Text('Không manga'),
                        ),
                        ...mangas.where((manga) => (manga.id ?? 0) > 0).map((
                          manga,
                        ) {
                          final int mangaId = manga.id!;
                          return DropdownMenuItem<int>(
                            value: mangaId,
                            child: Text(
                              '${manga.title ?? 'Manga'} (#$mangaId)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedMangaId = value ?? 0;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  key: const Key('manage_notification_dialog_cancel_button'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  key: const Key('manage_notification_dialog_submit_button'),
                  onPressed: () {
                    final String title = titleController.text.trim();
                    final String content = contentController.text.trim();
                    final int mangaId = selectedMangaId;

                    if (title.isEmpty || content.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tiêu đề và nội dung là bắt buộc'),
                        ),
                      );
                      return;
                    }

                    if (targetRole == 'LikedManga' && mangaId <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Manga là bắt buộc')),
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      domain.NotificationEntity(
                        title: title,
                        content: content,
                        targetRole: targetRole,
                        mangaId: mangaId,
                      ),
                    );
                  },
                  child: const Text('Tạo'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    contentController.dispose();

    if (notification == null) {
      return;
    }

    final DataState<bool> result = await _notificationController
        .createNotification(notification);

    if (!mounted) {
      return;
    }

    if (result is DataSuccess<bool>) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tạo thông báo thành công')));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_messageFromDataState(result))));
  }

  String _messageFromDataState(DataState<bool> state) {
    final dynamic responseData = state.error?.response?.data;
    if (responseData is Map<String, dynamic>) {
      final dynamic message =
          responseData['message'] ?? responseData['Message'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    if (responseData is String && responseData.trim().isNotEmpty) {
      return responseData;
    }

    final String? dioMessage = state.error?.message;
    if (dioMessage != null && dioMessage.trim().isNotEmpty) {
      return dioMessage;
    }

    return 'Không thể tạo thông báo';
  }

  List<domain.NotificationEntity> _filterNotifications(
    List<domain.NotificationEntity> notifications,
  ) {
    final String keyword = _searchController.text.trim().toLowerCase();
    final List<domain.NotificationEntity> filtered = notifications.where((
      notification,
    ) {
      return keyword.isEmpty ||
          (notification.title ?? '').toLowerCase().contains(keyword) ||
          (notification.content ?? '').toLowerCase().contains(keyword) ||
          (notification.targetRole ?? '').toLowerCase().contains(keyword) ||
          (notification.mangaId?.toString() ?? '').contains(keyword);
    }).toList();

    filtered.sort((a, b) {
      switch (_selectedSort) {
        case 'Cũ nhất':
          return _notificationDate(a).compareTo(_notificationDate(b));
        case 'Tiêu đề A-Z':
          return (a.title ?? '').toLowerCase().compareTo(
            (b.title ?? '').toLowerCase(),
          );
        default:
          return _notificationDate(b).compareTo(_notificationDate(a));
      }
    });

    return filtered;
  }

  DateTime _notificationDate(domain.NotificationEntity notification) {
    return notification.createAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    final themeController = sl<ThemeController>();
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final isDark = themeController.isDarkMode;
        final scaffoldBg = isDark ? const Color(0xFF1A1D2E) : const Color(0xFFDFE3ED);
        final shellBg = isDark ? const Color(0xFF0E1326) : Colors.white;
        final shellBorder = isDark ? const Color(0xFF1E2640) : const Color(0xFFE2E8F0);

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isCompactSidebar = constraints.maxWidth < 1120;
            final double shellHeight = (constraints.maxHeight - 24)
                .clamp(620.0, 920.0)
                .toDouble();

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
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: shellBorder, width: 1),
                          ),
                          child: Row(
                            children: [
                              ManageMangaSidebar(
                                compact: isCompactSidebar,
                                selectedKey: sidebarKeyNotifications,
                                onSelect: (key) {
                                  if (key == sidebarKeyOverview) {
                                    Navigator.of(context).popUntil((route) => route.isFirst);
                                  } else if (key == sidebarKeyManga) {
                                    _openMangaPage();
                                  } else if (key == sidebarKeyAuthors) {
                                    _openAuthorsPage();
                                  } else if (key == sidebarKeyUsers) {
                                    _openUsersPage();
                                  } else if (key == sidebarKeyVip) {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute<void>(
                                        builder: (_) => ManageVipPackages(
                                          mangaController: widget.mangaController,
                                          onLogout: widget.onLogout,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              Expanded(child: _buildMainContent()),
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
      },
    );
  }

  Widget _buildMainContent() {
    final isDark = sl<ThemeController>().isDarkMode;
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(14),
        bottomRight: Radius.circular(14),
      ),
      child: Container(
        color: isDark ? const Color(0xFF080C1B) : const Color(0xFFF7F8FC),
        child: Column(
          children: [
            ManageMangaTopHeader(
              searchController: _searchController,
              onLogout: widget.onLogout,
              onNotificationTap: () {},
              hintText: 'Tìm kiếm thông báo...',
              customHeaderWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF4FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.notifications_active_rounded,
                          size: 18,
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1F5BFF),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Quản lý thông báo',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF1D2638),
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      'Quản lý thông báo hệ thống và gửi thông báo tới độc giả',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : const Color(0xFF7B879B),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: ListenableBuilder(
                  listenable: _notificationController,
                  builder: (_, __) {
                    final RemoteNotificationState state =
                        _notificationController.state;
                    if (state is RemoteNotificationLoading) {
                      return const Center(child: CupertinoActivityIndicator());
                    }

                    if (state is RemoteNotificationError) {
                      return _NotificationErrorState(
                        onRetry: _notificationController.loadNotifications,
                      );
                    }

                    if (state is RemoteNotificationDone) {
                      final List<domain.NotificationEntity> notifications =
                          _filterNotifications(
                            state.notifications ??
                                const <domain.NotificationEntity>[],
                          );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _NotificationFilterBar(
                            selectedSort: _selectedSort,
                            onSortChanged: (value) {
                              setState(() {
                                _selectedSort = value;
                              });
                            },
                            onRefresh: _notificationController.loadNotifications,
                            onCreate: _showCreateNotificationDialog,
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: _NotificationTable(
                              notifications: notifications,
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

class _NotificationFilterBar extends StatelessWidget {
  final String selectedSort;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;

  const _NotificationFilterBar({
    required this.selectedSort,
    required this.onSortChanged,
    required this.onRefresh,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    const List<String> sortOptions = ['Mới nhất', 'Cũ nhất', 'Tiêu đề A-Z'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E8F2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 170,
            child: DropdownButtonFormField<String>(
              value: selectedSort,
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Sắp xếp',
                border: OutlineInputBorder(),
              ),
              items: sortOptions
                  .map(
                    (value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onSortChanged(value);
                }
              },
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: onRefresh,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              side: const BorderSide(color: Color(0xFFCCD6EA)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF1F5BFF)),
            label: const Text(
              'Làm mới',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F5BFF)),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            key: const Key('manage_notifications_create_button'),
            onPressed: onCreate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF040617),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text(
              'Tạo thông báo',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTable extends StatelessWidget {
  final List<domain.NotificationEntity> notifications;

  const _NotificationTable({required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E8F2)),
      ),
      child: notifications.isEmpty
          ? const Center(
              child: Text(
                'Không có thông báo phù hợp',
                style: TextStyle(color: Color(0xFF6C7B92)),
              ),
            )
          : SingleChildScrollView(
              child: DataTable(
                columnSpacing: 24,
                horizontalMargin: 18,
                dataRowMinHeight: 64,
                dataRowMaxHeight: 82,
                headingRowHeight: 46,
                columns: const [
                  DataColumn(label: Text('Tiêu đề')),
                  DataColumn(label: Text('Nội dung')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Manga')),
                  DataColumn(label: Text('Ngày tạo')),
                ],
                rows: notifications.map(_buildRow).toList(),
              ),
            ),
    );
  }

  DataRow _buildRow(domain.NotificationEntity notification) {
    final DateTime? createAt = notification.createAt?.toLocal();
    final String createdText = createAt == null
        ? '-'
        : DateFormat('dd/MM/yyyy HH:mm').format(createAt);

    return DataRow(
      cells: [
        DataCell(_compactText(notification.title ?? 'Notification', 180)),
        DataCell(_compactText(notification.content ?? '-', 320)),
        DataCell(Text(_emptyDash(notification.targetRole))),
        DataCell(Text(notification.mangaId?.toString() ?? '-')),
        DataCell(Text(createdText)),
      ],
    );
  }

  Widget _compactText(String value, double width) {
    return SizedBox(
      width: width,
      child: Tooltip(
        message: value,
        child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  String _emptyDash(String? value) {
    final String normalized = value?.trim() ?? '';
    return normalized.isEmpty ? '-' : normalized;
  }
}

class _NotificationErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _NotificationErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: Color(0xFF8A96A8),
          ),
          const SizedBox(height: 12),
          const Text(
            'Không thể tải danh sách thông báo',
            style: TextStyle(color: Color(0xFF4E5A6F)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
