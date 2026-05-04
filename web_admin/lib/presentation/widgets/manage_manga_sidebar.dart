import 'package:flutter/material.dart';

const String sidebarKeyOverview = 'overview';
const String sidebarKeyManga = 'manga';
const String sidebarKeyAuthors = 'authors';
const String sidebarKeyUsers = 'users';
const String sidebarKeyAnalytics = 'analytics';

class ManageMangaSidebar extends StatelessWidget {
  final bool compact;
  final String selectedKey;
  final ValueChanged<String> onSelect;

  const ManageMangaSidebar({
    super.key,
    required this.compact,
    required this.selectedKey,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 82 : 230,
      decoration: const BoxDecoration(
        color: Color(0xFF081C3A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(14),
          bottomLeft: Radius.circular(14),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(compact ? 14 : 24, 28, 14, 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: compact
                  ? const Icon(Icons.menu_book_rounded, color: Colors.white)
                  : const Text(
                      'Quản Trị Manga',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          _SidebarItem(
            icon: Icons.grid_view_rounded,
            label: 'Tổng quan',
            compact: compact,
            selected: selectedKey == sidebarKeyOverview,
            onTap: () => onSelect(sidebarKeyOverview),
          ),
          _SidebarItem(
            icon: Icons.menu_book_rounded,
            label: 'Quản lý Manga',
            compact: compact,
            selected: selectedKey == sidebarKeyManga,
            onTap: () => onSelect(sidebarKeyManga),
          ),
          _SidebarItem(
            icon: Icons.person_pin_rounded,
            label: 'Quản lý Tác giả',
            compact: compact,
            selected: selectedKey == sidebarKeyAuthors,
            onTap: () => onSelect(sidebarKeyAuthors),
          ),
          _SidebarItem(
            icon: Icons.people_outline_rounded,
            label: 'Người dùng',
            compact: compact,
            selected: selectedKey == sidebarKeyUsers,
            onTap: () => onSelect(sidebarKeyUsers),
          ),
          _SidebarItem(
            icon: Icons.bar_chart_rounded,
            label: 'Phân tích',
            compact: compact,
            selected: selectedKey == sidebarKeyAnalytics,
            onTap: () => onSelect(sidebarKeyAnalytics),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 16,
              0,
              compact ? 12 : 16,
              16,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F2D5A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1C3E71)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: compact ? 8 : 12,
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: Color(0xFF2563EB),
                      child: Icon(Icons.person, color: Colors.white, size: 16),
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Quản trị viên',
                              style: TextStyle(
                                color: Color(0xFFE6EDFF),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'admin@manga.vn',
                              style: TextStyle(
                                color: Color(0xFF9DB3D9),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 10 : 12, 4, compact ? 10 : 12, 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1F5BFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 14,
              vertical: compact ? 10 : 12,
            ),
            child: Row(
              mainAxisAlignment: compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: selected ? Colors.white : const Color(0xFF9BB2D4),
                  size: 18,
                ),
                if (!compact) ...[
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF9BB2D4),
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
