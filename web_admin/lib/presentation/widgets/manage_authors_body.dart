import 'package:flutter/material.dart';
import 'package:web_admin/domain/entities/author.dart';
import 'package:web_admin/domain/entities/manga.dart';
import 'package:web_admin/presentation/controllers/theme_controller.dart';
import 'package:web_admin/injection_container.dart';

class ManageAuthorsBody extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedSort;
  final bool onlyNoManga;
  final List<AuthorEntity> visibleAuthors;
  final Map<int, List<MangaEntity>> mangaByAuthor;
  final VoidCallback onAddAuthor;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<bool> onOnlyNoMangaChanged;
  final void Function(AuthorEntity author, List<MangaEntity> mangaList)
  onAuthorTap;

  const ManageAuthorsBody({
    super.key,
    required this.searchController,
    required this.selectedSort,
    required this.onlyNoManga,
    required this.visibleAuthors,
    required this.mangaByAuthor,
    required this.onAddAuthor,
    required this.onSortChanged,
    required this.onOnlyNoMangaChanged,
    required this.onAuthorTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AuthorSearchCard(
          searchController: searchController,
          onAddAuthor: onAddAuthor,
        ),
        const SizedBox(height: 18),
        _AuthorFilterCard(
          selectedSort: selectedSort,
          onlyNoManga: onlyNoManga,
          onSortChanged: onSortChanged,
          onOnlyNoMangaChanged: onOnlyNoMangaChanged,
        ),
        const SizedBox(height: 18),
        Expanded(
          child: _AuthorListCard(
            visibleAuthors: visibleAuthors,
            mangaByAuthor: mangaByAuthor,
            onAuthorTap: onAuthorTap,
          ),
        ),
      ],
    );
  }
}

class _AuthorSearchCard extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onAddAuthor;

  const _AuthorSearchCard({
    required this.searchController,
    required this.onAddAuthor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = sl<ThemeController>().isDarkMode;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _getCardDecoration(isDark),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Nhập tên tác giả...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : const Color(0xFFABB3C2),
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? Colors.white38 : const Color(0xFFABB3C2),
                  size: 18,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                filled: true,
                fillColor: isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF7F8FC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            key: const Key('manage_authors_create_button'),
            onPressed: onAddAuthor,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF040617),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text(
              'Thêm tác giả',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorFilterCard extends StatelessWidget {
  final String selectedSort;
  final bool onlyNoManga;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<bool> onOnlyNoMangaChanged;

  const _AuthorFilterCard({
    required this.selectedSort,
    required this.onlyNoManga,
    required this.onSortChanged,
    required this.onOnlyNoMangaChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = sl<ThemeController>().isDarkMode;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _getCardDecoration(isDark),
      child: Row(
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF7F8FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedSort,
                dropdownColor: isDark ? const Color(0xFF1A1D2E) : Colors.white,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: isDark ? Colors.white60 : const Color(0xFF4D5B72),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF4D5B72),
                  fontSize: 13,
                ),
                items: const [
                  DropdownMenuItem(value: 'A-Z', child: Text('Sắp xếp A-Z')),
                  DropdownMenuItem(
                    value: 'Manga nhiều',
                    child: Text('Manga nhiều nhất'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onSortChanged(value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Checkbox(
            value: onlyNoManga,
            activeColor: const Color(0xFF1F5BFF),
            checkColor: Colors.white,
            onChanged: (value) => onOnlyNoMangaChanged(value ?? false),
          ),
          Text(
            'Chỉ tác giả chưa có truyện',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorListCard extends StatelessWidget {
  final List<AuthorEntity> visibleAuthors;
  final Map<int, List<MangaEntity>> mangaByAuthor;
  final void Function(AuthorEntity author, List<MangaEntity> mangaList)
  onAuthorTap;

  const _AuthorListCard({
    required this.visibleAuthors,
    required this.mangaByAuthor,
    required this.onAuthorTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = sl<ThemeController>().isDarkMode;
    return Container(
      decoration: _getCardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Text(
              'Danh sách tác giả (${visibleAuthors.length})',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E2A3C),
              ),
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF1E2640) : const Color(0xFFEEF1F6),
          ),
          Expanded(
            child: visibleAuthors.isEmpty
                ? Center(
                    child: Text(
                      'Chưa có tác giả nào',
                      style: TextStyle(
                        color: isDark ? Colors.white30 : const Color(0xFF8491A7),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: visibleAuthors.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: isDark ? const Color(0xFF1E2640) : const Color(0xFFEEF1F6),
                    ),
                    itemBuilder: (context, index) {
                      final AuthorEntity author = visibleAuthors[index];
                      final int authorId = author.id ?? 0;
                      final List<MangaEntity> authorManga =
                          mangaByAuthor[authorId] ?? const <MangaEntity>[];

                      return ListTile(
                        title: Text(
                          author.fullName ?? 'Tác giả #$authorId',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          (author.description ?? '').trim().isEmpty
                              ? 'Chưa có mô tả'
                              : author.description!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${authorManga.length}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              'manga',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : const Color(0xFF7B879B),
                              ),
                            ),
                          ],
                        ),
                        onTap: () => onAuthorTap(author, authorManga),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _getCardDecoration(bool isDark) {
  return BoxDecoration(
    color: isDark ? const Color(0xFF0E1326) : Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: isDark ? const Color(0xFF1E2640) : const Color(0xFFE4E8F2),
    ),
  );
}
