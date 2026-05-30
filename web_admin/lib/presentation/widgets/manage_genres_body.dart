import 'package:flutter/material.dart';
import 'package:web_admin/domain/entities/genre.dart';
import 'package:web_admin/injection_container.dart';
import 'package:web_admin/presentation/controllers/theme_controller.dart';

class ManageGenresBody extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedSort;
  final ValueChanged<String> onSortChanged;
  final List<GenreEntity> visibleGenres;
  final VoidCallback onAddGenre;
  final ValueChanged<GenreEntity> onEditGenre;
  final ValueChanged<GenreEntity> onDeleteGenre;

  const ManageGenresBody({
    super.key,
    required this.searchController,
    required this.selectedSort,
    required this.onSortChanged,
    required this.visibleGenres,
    required this.onAddGenre,
    required this.onEditGenre,
    required this.onDeleteGenre,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = sl<ThemeController>().isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GenresHeading(onAddGenre: onAddGenre, isDark: isDark),
        const SizedBox(height: 18),
        _GenreSearchCard(
          searchController: searchController,
          selectedSort: selectedSort,
          onSortChanged: onSortChanged,
          isDark: isDark,
        ),
        const SizedBox(height: 18),
        Expanded(
          child: _GenreListCard(
            visibleGenres: visibleGenres,
            onEditGenre: onEditGenre,
            onDeleteGenre: onDeleteGenre,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _GenresHeading extends StatelessWidget {
  final VoidCallback onAddGenre;
  final bool isDark;

  const _GenresHeading({required this.onAddGenre, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản lý thể loại',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1D2638),
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Danh sách thể loại trong hệ thống',
              style: TextStyle(
                color: isDark ? Colors.white60 : const Color(0xFF7B879B),
                fontSize: 14,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: onAddGenre,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1F5BFF),
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
  final String selectedSort;
  final ValueChanged<String> onSortChanged;
  final bool isDark;

  const _GenreSearchCard({
    required this.searchController,
    required this.selectedSort,
    required this.onSortChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _getCardDecoration(isDark),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'Nhập thể loại...',
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
                  DropdownMenuItem(value: 'ID', child: Text('Sắp xếp theo ID')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onSortChanged(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreListCard extends StatelessWidget {
  final List<GenreEntity> visibleGenres;
  final ValueChanged<GenreEntity> onEditGenre;
  final ValueChanged<GenreEntity> onDeleteGenre;
  final bool isDark;

  const _GenreListCard({
    required this.visibleGenres,
    required this.onEditGenre,
    required this.onDeleteGenre,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _getCardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Text(
              'Danh sách thể loại (${visibleGenres.length})',
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
            child: visibleGenres.isEmpty
                ? Center(
                    child: Text(
                      'Chưa có thể loại nào',
                      style: TextStyle(
                        color: isDark ? Colors.white30 : const Color(0xFF8491A7),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: visibleGenres.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: isDark ? const Color(0xFF1E2640) : const Color(0xFFEEF1F6),
                    ),
                    itemBuilder: (context, index) {
                      final GenreEntity genre = visibleGenres[index];
                      final int genreId = genre.id ?? 0;

                      return ListTile(
                        title: Text(
                          genre.name ?? 'Thể loại #$genreId',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        subtitle: Text(
                          'ID: $genreId',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Sửa thể loại',
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                              ),
                              onPressed: () => onEditGenre(genre),
                            ),
                            IconButton(
                              tooltip: 'Xóa thể loại',
                              icon: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: isDark ? Colors.redAccent : const Color(0xFF64748B),
                              ),
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

BoxDecoration _getCardDecoration(bool isDark) {
  return BoxDecoration(
    color: isDark ? const Color(0xFF0E1326) : Colors.white,
    borderRadius: const BorderRadius.all(Radius.circular(14)),
    border: Border.all(
      color: isDark ? const Color(0xFF1E2640) : const Color(0xFFE4E8F2),
      width: 1,
    ),
    boxShadow: isDark
        ? []
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
  );
}
