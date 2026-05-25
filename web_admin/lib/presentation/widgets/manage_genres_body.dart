import 'package:flutter/material.dart';
import 'package:web_admin/domain/entities/genre.dart';

class ManageGenresBody extends StatelessWidget {
  final TextEditingController searchController;
  final List<GenreEntity> visibleGenres;
  final VoidCallback onAddGenre;
  final ValueChanged<GenreEntity> onEditGenre;
  final ValueChanged<GenreEntity> onDeleteGenre;

  const ManageGenresBody({
    super.key,
    required this.searchController,
    required this.visibleGenres,
    required this.onAddGenre,
    required this.onEditGenre,
    required this.onDeleteGenre,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GenresHeading(onAddGenre: onAddGenre),
        const SizedBox(height: 18),
        _GenreSearchCard(searchController: searchController),
        const SizedBox(height: 18),
        Expanded(
          child: _GenreListCard(
            visibleGenres: visibleGenres,
            onEditGenre: onEditGenre,
            onDeleteGenre: onDeleteGenre,
          ),
        ),
      ],
    );
  }
}

class _GenresHeading extends StatelessWidget {
  final VoidCallback onAddGenre;

  const _GenresHeading({required this.onAddGenre});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản lý thể loại',
              style: TextStyle(
                color: Color(0xFF1D2638),
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Danh sách thể loại trong hệ thống',
              style: TextStyle(color: Color(0xFF7B879B), fontSize: 14),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: onAddGenre,
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
            'Thêm thể loại',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _GenreSearchCard extends StatelessWidget {
  final TextEditingController searchController;

  const _GenreSearchCard({required this.searchController});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration,
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Nhập thể loại...',
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

class _GenreListCard extends StatelessWidget {
  final List<GenreEntity> visibleGenres;
  final ValueChanged<GenreEntity> onEditGenre;
  final ValueChanged<GenreEntity> onDeleteGenre;

  const _GenreListCard({
    required this.visibleGenres,
    required this.onEditGenre,
    required this.onDeleteGenre,
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
              'Danh sách thể loại (${visibleGenres.length})',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E2A3C),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEF1F6)),
          Expanded(
            child: visibleGenres.isEmpty
                ? const Center(
                    child: Text(
                      'Chưa có thể loại nào',
                      style: TextStyle(color: Color(0xFF8491A7)),
                    ),
                  )
                : ListView.separated(
                    itemCount: visibleGenres.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final GenreEntity genre = visibleGenres[index];
                      final int genreId = genre.id ?? 0;

                      return ListTile(
                        title: Text(
                          genre.name ?? 'Thể loại #$genreId',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('ID: $genreId'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Sửa thể loại',
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => onEditGenre(genre),
                            ),
                            IconButton(
                              tooltip: 'Xóa thể loại',
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () => onDeleteGenre(genre),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

const BoxDecoration _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(14)),
  boxShadow: [
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ],
);
