import 'package:flutter/material.dart';
import 'package:web_admin/domain/entities/author.dart';
import 'package:web_admin/domain/entities/manga.dart';

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
        _AuthorsHeading(onAddAuthor: onAddAuthor),
        const SizedBox(height: 18),
        _AuthorSearchCard(searchController: searchController),
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

class _AuthorsHeading extends StatelessWidget {
  final VoidCallback onAddAuthor;

  const _AuthorsHeading({required this.onAddAuthor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản lý tác giả',
              style: TextStyle(
                color: Color(0xFF1D2638),
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Danh sách tác giả và tác phẩm liên quan',
              style: TextStyle(color: Color(0xFF7B879B), fontSize: 14),
            ),
          ],
        ),
        ElevatedButton.icon(
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
    );
  }
}

class _AuthorSearchCard extends StatelessWidget {
  final TextEditingController searchController;

  const _AuthorSearchCard({required this.searchController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration,
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Nhập tên tác giả...',
          hintStyle: const TextStyle(color: Color(0xFFABB3C2), fontSize: 13),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFFABB3C2),
            size: 18,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
          filled: true,
          fillColor: const Color(0xFFF7F8FC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration,
      child: Row(
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedSort,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                style: const TextStyle(
                  color: Color(0xFF4D5B72),
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
            onChanged: (value) => onOnlyNoMangaChanged(value ?? false),
          ),
          const Text('Chỉ tác giả chưa có truyện'),
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
    return Container(
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Text(
              'Danh sách tác giả (${visibleAuthors.length})',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E2A3C),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEF1F6)),
          Expanded(
            child: visibleAuthors.isEmpty
                ? const Center(
                    child: Text(
                      'Chưa có tác giả nào',
                      style: TextStyle(color: Color(0xFF8491A7)),
                    ),
                  )
                : ListView.separated(
                    itemCount: visibleAuthors.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final AuthorEntity author = visibleAuthors[index];
                      final int authorId = author.id ?? 0;
                      final List<MangaEntity> authorManga =
                          mangaByAuthor[authorId] ?? const <MangaEntity>[];

                      return ListTile(
                        title: Text(
                          author.fullName ?? 'Tác giả #$authorId',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          (author.description ?? '').trim().isEmpty
                              ? 'Chưa có mô tả'
                              : author.description!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${authorManga.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Text(
                              'manga',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF7B879B),
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

BoxDecoration get _cardDecoration {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: const Color(0xFFE4E8F2)),
  );
}
