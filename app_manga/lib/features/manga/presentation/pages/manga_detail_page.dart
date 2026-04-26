import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/entities/chapter_entity.dart';
import '../../domain/entities/manga_entity.dart';
import '../../domain/repositories/manga_repository.dart';
import '../../domain/usecases/get_chapters_by_manga_usecase.dart';
import '../../domain/usecases/get_manga_detail_usecase.dart';
import '../controllers/manga_detail_controller.dart';
import 'manga_reader_page.dart';

class MangaDetailPage extends StatelessWidget {
  final int mangaId;

  const MangaDetailPage({super.key, required this.mangaId});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<MangaRepository>();

    return ChangeNotifierProvider(
      create: (_) => MangaDetailController(
        getMangaDetailUseCase: GetMangaDetailUseCase(repository),
        getChaptersByMangaUseCase: GetChaptersByMangaUseCase(repository),
      )..load(mangaId),
      child: const _MangaDetailView(),
    );
  }
}

class _MangaDetailView extends StatelessWidget {
  const _MangaDetailView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MangaDetailController>();

    if (controller.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE8742B))),
      );
    }

    if (controller.errorMessage != null || controller.manga == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manga'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF222222),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 42, color: Color(0xFFBA541E)),
                const SizedBox(height: 12),
                const Text(
                  'Khong tai duoc chi tiet truyen',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  controller.errorMessage ?? 'Du lieu khong hop le',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final manga = controller.manga!;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        title: const Text('Manga'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF222222),
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.info_outline),
          ),
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderSection(manga: manga),
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              child: Text(
                'Introduction',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF32363F),
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                manga.description?.trim().isNotEmpty == true
                    ? manga.description!.trim()
                    : 'No introduction available.',
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.45,
                  color: Color(0xFF5B616E),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
              child: Text(
                'Genres',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF32363F),
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: manga.genres.isEmpty
                    ? const [
                        _TagChip(label: 'Updating'),
                      ]
                    : manga.genres.map((genre) => _TagChip(label: genre.name)).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chapters',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF32363F),
                        ),
                  ),
                  Text(
                    '${controller.chapters.length} chap',
                    style: const TextStyle(color: Color(0xFF6F7785)),
                  ),
                ],
              ),
            ),
            if (controller.chapters.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 28),
                child: Text(
                  'Chua co chapter nao.',
                  style: TextStyle(color: Color(0xFF6F7785), fontSize: 16),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                child: Column(
                  children: controller.chapters
                      .map(
                        (chapter) => _ChapterTile(
                          chapter: chapter,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MangaReaderPage(
                                  mangaId: manga.id,
                                  mangaTitle: manga.title,
                                  chapters: controller.chapters,
                                  initialChapterId: chapter.id,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final MangaEntity manga;

  const _HeaderSection({required this.manga});

  String _resolveImageUrl() {
    final thumbnail = manga.thumbnail;
    if (thumbnail == null || thumbnail.isEmpty) {
      return 'https://picsum.photos/seed/manga-cover/320/420';
    }

    if (thumbnail.startsWith('http')) {
      return thumbnail;
    }

    return '${AppConfig.apiOrigin}/${thumbnail.replaceFirst(RegExp(r'^/+'), '')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _resolveImageUrl(),
              width: 88,
              height: 128,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 88,
                height: 128,
                color: Colors.grey.shade300,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  manga.title,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E2E2E),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < manga.rate ? Icons.star : Icons.star_border,
                      size: 17,
                      color: const Color(0xFFC75F25),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  manga.status ?? 'Unknown status',
                  style: const TextStyle(fontSize: 21, color: Color(0xFF6D7482)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Expanded(child: _ActionButton(label: 'FOLLOWING')),
                    SizedBox(width: 10),
                    Expanded(child: _ActionButton(label: 'CONTINUE')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE8742B)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 20, color: Color(0xFFAF4D1A)),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;

  const _ActionButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE8742B)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        foregroundColor: const Color(0xFFE8742B),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Text(label),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final ChapterEntity chapter;
  final VoidCallback onTap;

  const _ChapterTile({required this.chapter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final chapterLabel = chapter.chapterNumber.trim().isEmpty
        ? 'Chapter'
        : 'Chapter ${chapter.chapterNumber}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE1E4EA)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        title: Text(
          chapterLabel,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2E2E2E)),
        ),
        subtitle: Text(
          chapter.title.trim().isEmpty ? 'No title' : chapter.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF6F7785)),
        ),
        trailing: chapter.isPremium
            ? const Icon(Icons.lock_outline, color: Color(0xFFE8742B))
            : const Icon(Icons.chevron_right, color: Color(0xFFB1B7C2)),
        onTap: onTap,
      ),
    );
  }
}
