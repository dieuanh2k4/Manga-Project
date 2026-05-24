import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:web_admin/presentation/widgets/hover_dropdown.dart';
import 'package:web_admin/presentation/controllers/auth_controller.dart';
import 'package:web_admin/presentation/controllers/remote_notification_controller.dart';
import 'package:web_admin/injection_container.dart';

class ManageMangaTopHeader extends StatefulWidget {
  final TextEditingController searchController;
  final Future<void> Function()? onLogout;
  final VoidCallback? onNotificationTap;
  final String hintText;

  final Widget? customHeaderWidget;

  const ManageMangaTopHeader({
    super.key,
    required this.searchController,
    this.onLogout,
    this.onNotificationTap,
    this.hintText = 'Tìm kiếm manga, người dùng...',
    this.customHeaderWidget,
  });

  @override
  State<ManageMangaTopHeader> createState() => _ManageMangaTopHeaderState();
}

class _ManageMangaTopHeaderState extends State<ManageMangaTopHeader> {
  late final RemoteNotificationController _notificationController;

  @override
  void initState() {
    super.initState();
    _notificationController = sl<RemoteNotificationController>();
    // Pre-load notifications asynchronously if not loaded yet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_notificationController.hasLoaded) {
        _notificationController.loadNotifications();
      }
    });
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.settings_outlined, color: Color(0xFF2563EB)),
              SizedBox(width: 10),
              Text(
                'Cài đặt hệ thống',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ],
          ),
          content: const SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cấu hình Web Admin',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Chế độ tối (Dark Mode)'),
                  trailing: Icon(Icons.toggle_off_outlined, size: 28, color: Colors.grey),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Tự động đồng bộ với máy chủ'),
                  trailing: Icon(Icons.toggle_on_rounded, size: 28, color: Color(0xFF2563EB)),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Ngôn ngữ hiển thị'),
                  trailing: Text('Tiếng Việt (VI)', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Đóng'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Lưu thay đổi'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropdownItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF64748B),
    Color textColor = const Color(0xFF334155),
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: const Color(0xFFEFF6FF), // Soft premium highlight on hover
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8491A7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFABB3C2),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic account info loaded from shared AuthController state
    final authController = sl<AuthController>();
    final userName = authController.auth?.userName ?? 'Quản trị viên';
    final userRole = authController.auth?.role ?? 'Admin';
    final userEmail = authController.auth != null
        ? '${authController.auth!.userName.toLowerCase().replaceAll(' ', '')}@manga.vn'
        : 'admin@manga.vn';

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7EBF3))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: widget.customHeaderWidget ??
                  SizedBox(
                    width: 380,
                    child: TextField(
                      controller: widget.searchController,
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: const TextStyle(
                          color: Color(0xFFA6ADBB),
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFFA6ADBB),
                          size: 18,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 11,
                        ),
                        fillColor: const Color(0xFFF4F6FA),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
            ),
          ),
          const SizedBox(width: 16),
          
          // 1. DEDICATED NOTIFICATION BELL DROPDOWN
          ListenableBuilder(
            listenable: _notificationController,
            builder: (context, _) {
              final state = _notificationController.state;
              final list = state.notifications ?? [];
              final unreadCount = list.where((n) => n.isRead != true).length;

              return ProfileDropdown(
                dropdownWidth: 340.0, // Wider for beautiful title previewing
                yOffset: 8.0,
                targetAnchor: Alignment.bottomRight,
                followerAnchor: Alignment.topRight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: 1,
                        right: 1,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444), // Crimson Red Badge
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 8,
                            minHeight: 8,
                          ),
                        ),
                      ),
                  ],
                ),
                dropdownContent: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Thông báo mới nhận',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (list.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${list.length}',
                                  style: const TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      
                      // Body/Previews Section
                      if (state is RemoteNotificationLoading && list.isEmpty)
                        const SizedBox(
                          height: 180,
                          child: Center(
                            child: CupertinoActivityIndicator(),
                          ),
                        )
                      else if (list.isEmpty)
                        const SizedBox(
                          height: 180,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.notifications_off_outlined,
                                  color: Color(0xFFABB3C2),
                                  size: 32,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Không có thông báo mới',
                                  style: TextStyle(
                                    color: Color(0xFF8491A7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 280),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: list.length > 4 ? 4 : list.length, // Display up to 4
                            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            itemBuilder: (context, index) {
                              final notification = list[index];
                              final isUnread = notification.isRead != true;
                              
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    if (widget.onNotificationTap != null) {
                                      widget.onNotificationTap!();
                                    }
                                  },
                                  hoverColor: const Color(0xFFEFF6FF),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: isUnread 
                                                ? const Color(0xFFEFF6FF) 
                                                : const Color(0xFFF1F5F9),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.notifications_active_rounded,
                                            color: isUnread 
                                                ? const Color(0xFF2563EB) 
                                                : const Color(0xFF64748B),
                                            size: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                notification.title ?? 'Thông báo hệ thống',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: const Color(0xFF1E293B),
                                                  fontSize: 12,
                                                  fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                notification.content ?? '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Color(0xFF64748B),
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isUnread)
                                          Container(
                                            margin: const EdgeInsets.only(top: 4, left: 6),
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF2563EB),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      
                      // Footer Hyperlink Section
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (widget.onNotificationTap != null) {
                              widget.onNotificationTap!();
                            }
                          },
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          hoverColor: const Color(0xFFEFF6FF),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            child: const Text(
                              'Xem tất cả thông báo',
                              style: TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          
          // 2. GOOGLE-STYLE PROFILE PILL BUTTON & CARD DROPDOWN
          ProfileDropdown(
            yOffset: 8.0,
            dropdownWidth: 300.0,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24), // Pill shape
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFF2563EB),
                    child: Icon(Icons.person, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Xin chào, $userName!',
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF64748B),
                    size: 16,
                  ),
                ],
              ),
            ),
            dropdownContent: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Profile Header Box
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC), // Cool grey background
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: Color(0xFF2563EB),
                          child: Icon(Icons.person, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            '${userRole.toUpperCase()} HỆ THỐNG',
                            style: const TextStyle(
                              color: Color(0xFF1D4ED8),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  // Options List (Settings & Logout)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDropdownItem(
                          icon: Icons.settings_outlined,
                          title: 'Cài đặt hệ thống',
                          subtitle: 'Cấu hình giao diện và tham số',
                          onTap: () {
                            _showSettingsDialog(context);
                          },
                        ),
                        const SizedBox(height: 4),
                        const Divider(height: 1, color: Color(0xFFEFF2F6)),
                        const SizedBox(height: 4),
                        _buildDropdownItem(
                          icon: Icons.logout_rounded,
                          title: 'Thoát đăng nhập',
                          subtitle: 'Đăng xuất tài khoản an toàn',
                          iconColor: const Color(0xFFEF4444),
                          textColor: const Color(0xFFEF4444),
                          onTap: () {
                            if (widget.onLogout != null) {
                              widget.onLogout!();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
