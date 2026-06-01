import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../manga/presentation/pages/manga_detail_page.dart';
import '../controllers/notification_controller.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      final token = auth.session?.token;
      if (token != null) {
        context.read<NotificationController>().fetchNotifications(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotificationController>();
    final auth = context.watch<AuthController>();
    final token = auth.session?.token;

    return Scaffold(
      key: const Key('notification_page'),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFBA541E),
        elevation: 0,
        title: const Text(
          'Thông báo',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton.icon(
            key: const Key('notifications_mark_all_read_button'),
            onPressed: token == null || controller.unreadCount == 0
                ? null
                : () => controller.markAllAsRead(token),
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Đã đọc tất cả'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFBA541E),
              disabledForegroundColor: Colors.black26,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFFE8742B),
        onRefresh: () async {
          if (token != null) {
            await controller.fetchNotifications(token);
          }
        },
        child: _buildBody(controller, token),
      ),
    );
  }

  Widget _buildBody(NotificationController controller, String? token) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE8742B)),
      );
    }

    if (controller.error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          const Icon(
            Icons.notifications_off_outlined,
            size: 44,
            color: Color(0xFFBA541E),
          ),
          const SizedBox(height: 12),
          Text(
            controller.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      );
    }

    if (controller.notifications.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 120),
          Icon(Icons.notifications_none, size: 44, color: Color(0xFFBA541E)),
          SizedBox(height: 12),
          Text(
            'Chưa có thông báo',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: controller.notifications.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final notification = controller.notifications[index];
        final hasManga = notification.mangaId > 0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: notification.isRead
                ? const Color(0xFFFAFAFA)
                : const Color(0xFFFFF1E8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: notification.isRead
                  ? const Color(0xFFF2F2F2)
                  : const Color(0xFFFFD6BE),
              child: Icon(
                notification.isRead
                    ? Icons.notifications_none
                    : Icons.notifications_active,
                color: notification.isRead
                    ? Colors.black38
                    : const Color(0xFFBA541E),
              ),
            ),
            title: Text(
              notification.title,
              style: TextStyle(
                fontWeight: notification.isRead
                    ? FontWeight.w500
                    : FontWeight.w800,
                color: notification.isRead ? Colors.black54 : Colors.black87,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                notification.content,
                style: TextStyle(
                  color: notification.isRead ? Colors.black45 : Colors.black87,
                ),
              ),
            ),
            trailing: hasManga
                ? const Icon(Icons.chevron_right, color: Color(0xFFBA541E))
                : null,
            onTap: token == null
                ? null
                : () async {
                    if (!notification.isRead) {
                      try {
                        await controller.markAsRead(
                          notificationId: notification.id,
                          token: token,
                        );
                      } catch (_) {
                        if (!context.mounted || !hasManga) {
                          return;
                        }
                      }
                    }

                    if (!context.mounted || !hasManga) {
                      return;
                    }

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            MangaDetailPage(mangaId: notification.mangaId),
                      ),
                    );
                  },
          ),
        );
      },
    );
  }
}
