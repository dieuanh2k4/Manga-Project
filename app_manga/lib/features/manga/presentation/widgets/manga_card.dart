import 'package:flutter/material.dart';

import '../../domain/entities/manga_entity.dart';

class MangaCard extends StatelessWidget {
  final MangaEntity manga;
  final double width;
  final double height;
  final bool isGrid;

  const MangaCard({
    super.key,
    required this.manga,
    this.width = 120,
    this.height = 180,
    this.isGrid = false,
  });

  String _getImageUrl(String? thumbnail) {
    if (thumbnail == null || thumbnail.isEmpty) {
      return 'https://via.placeholder.com/150x200?text=No+Image';
    }
    if (thumbnail.startsWith('http')) {
      return thumbnail;
    }
    return 'http://localhost:5219/$thumbnail';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isGrid ? null : width,
      margin: isGrid ? null : const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _getImageUrl(manga.thumbnail),
                width: isGrid ? null : width,
                height: isGrid ? null : height,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: isGrid ? null : width,
                  height: isGrid ? null : height,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            manga.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < manga.rate ? Icons.star : Icons.star_border,
                color: const Color(0xFFC75F25),
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
