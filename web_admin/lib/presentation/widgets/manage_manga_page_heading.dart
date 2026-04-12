import 'package:flutter/material.dart';

class ManageMangaPageHeading extends StatelessWidget {
  final VoidCallback onAddTap;

  const ManageMangaPageHeading({super.key, required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    final Widget addButton = ElevatedButton.icon(
      onPressed: onAddTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF040617),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.add, size: 16),
      label: const Text(
        'Thêm Manga mới',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isTight = constraints.maxWidth < 760;

        if (isTight) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quản lý Manga',
                style: TextStyle(
                  color: Color(0xFF1D2638),
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Quản lý bộ sưu tập manga của bạn',
                style: TextStyle(color: Color(0xFF7B879B), fontSize: 14),
              ),
              const SizedBox(height: 12),
              addButton,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản lý Manga',
                  style: TextStyle(
                    color: Color(0xFF1D2638),
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Quản lý bộ sưu tập manga của bạn',
                  style: TextStyle(color: Color(0xFF7B879B), fontSize: 14),
                ),
              ],
            ),
            addButton,
          ],
        );
      },
    );
  }
}
