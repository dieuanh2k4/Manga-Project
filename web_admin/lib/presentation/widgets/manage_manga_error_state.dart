import 'package:flutter/material.dart';

class ManageMangaErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const ManageMangaErrorState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 36,
            color: Color(0xFF73809A),
          ),
          const SizedBox(height: 10),
          const Text(
            'Không thể tải danh sách manga',
            style: TextStyle(color: Color(0xFF5D6980), fontSize: 14),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Tải lại'),
          ),
        ],
      ),
    );
  }
}
