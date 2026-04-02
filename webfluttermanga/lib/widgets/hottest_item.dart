import 'package:flutter/material.dart';
import '../models/manga_mock.dart';

class HottestItem extends StatelessWidget {
  final Manga manga;
  final int rank;

  const HottestItem({super.key, required this.manga, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Khối chứa ảnh và xếp hạng bên trong ảnh
        Stack(
          children: [
            Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                image: DecorationImage(
                  image: NetworkImage(manga.thumbnail),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(4)),
                ),
                child: Text(
                  rank.toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        // Thông tin truyện
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                manga.title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                manga.authorName,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.arrow_upward, color: Colors.redAccent, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${(manga.views).toString().replaceAllMapped(RegExp(r"(\d)(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
