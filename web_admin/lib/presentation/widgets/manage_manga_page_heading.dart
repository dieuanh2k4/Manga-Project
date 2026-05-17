import 'package:flutter/material.dart';

class ManageMangaPageHeading extends StatelessWidget {
  final VoidCallback onAddTap;

  const ManageMangaPageHeading({super.key, required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    final Widget addButton = Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F5BFF), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x441F5BFF),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onAddTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text(
          'Thêm Manga mới',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isTight = constraints.maxWidth < 760;

        if (isTight) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(),
              const SizedBox(height: 12),
              addButton,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildTitle(),
            addButton,
          ],
        );
      },
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 18,
                color: Color(0xFF1F5BFF),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Quản lý Manga',
              style: TextStyle(
                color: Color(0xFF1D2638),
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.only(left: 2),
          child: Text(
            'Quản lý toàn bộ bộ sưu tập truyện trong hệ thống',
            style: TextStyle(color: Color(0xFF7B879B), fontSize: 13),
          ),
        ),
      ],
    );
  }
}
