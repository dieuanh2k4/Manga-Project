import 'package:flutter/material.dart';
import 'package:web_admin/domain/entities/genre.dart';

class ManageMangaFilterBar extends StatelessWidget {
  final TextEditingController searchController;

  // Status
  final String selectedStatus;
  final String allStatus;
  final ValueChanged<String> onStatusChanged;

  // Sort
  final String selectedSort;
  final ValueChanged<String> onSortChanged;

  // Genre
  final List<GenreEntity> genres;
  final Set<int> selectedGenreIds;
  final ValueChanged<Set<int>> onGenresChanged;

  const ManageMangaFilterBar({
    super.key,
    required this.searchController,
    required this.selectedStatus,
    required this.allStatus,
    required this.onStatusChanged,
    required this.selectedSort,
    required this.onSortChanged,
    required this.genres,
    required this.selectedGenreIds,
    required this.onGenresChanged,
  });

  bool get _hasActiveFilters =>
      selectedStatus != allStatus ||
      selectedGenreIds.isNotEmpty ||
      searchController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E8F2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Row chính ──────────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isTight = constraints.maxWidth < 900;

              if (isTight) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSearchField(),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildGenreDropdown(),
                          const SizedBox(width: 8),
                          _buildStatusDropdown(),
                          const SizedBox(width: 8),
                          _buildSortDropdown(),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: _buildSearchField()),
                  const SizedBox(width: 10),
                  _buildGenreDropdown(),
                  const SizedBox(width: 8),
                  _buildStatusDropdown(),
                  const SizedBox(width: 8),
                  _buildSortDropdown(),
                ],
              );
            },
          ),

          // ── Active filter chips ─────────────────────────────
          if (_hasActiveFilters)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _ActiveFilterChips(
                selectedStatus: selectedStatus,
                allStatus: allStatus,
                selectedGenreIds: selectedGenreIds,
                genres: genres,
                searchText: searchController.text,
                onClearStatus: () => onStatusChanged(allStatus),
                onRemoveGenre: (id) {
                  final newIds = Set<int>.from(selectedGenreIds)..remove(id);
                  onGenresChanged(newIds);
                },
                onClearSearch: searchController.clear,
                onClearAll: () {
                  onStatusChanged(allStatus);
                  onGenresChanged({});
                  searchController.clear();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: 'Tìm tên truyện, tác giả...',
        hintStyle: const TextStyle(color: Color(0xFFBBC3D0), fontSize: 13),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Color(0xFFBBC3D0),
          size: 18,
        ),
        suffixIcon: ListenableBuilder(
          listenable: searchController,
          builder: (_, __) => searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Color(0xFF8491A7),
                  ),
                  onPressed: searchController.clear,
                  splashRadius: 16,
                )
              : const SizedBox.shrink(),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        filled: true,
        fillColor: const Color(0xFFF5F7FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE4E8F2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE4E8F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1F5BFF), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildGenreDropdown() {
    final int selectedValue = selectedGenreIds.isNotEmpty ? selectedGenreIds.first : 0;

    return _DropdownFilter<int>(
      value: selectedValue,
      active: selectedValue != 0,
      hint: 'Thể loại',
      icon: Icons.category_outlined,
      items: [
        const DropdownMenuItem(value: 0, child: Text('Tất cả thể loại')),
        ...genres.where((g) => g.id != null).map((g) {
          return DropdownMenuItem(
            value: g.id!,
            child: Text(g.name ?? 'Unknown'),
          );
        }),
      ],
      onChanged: (value) {
        if (value != null) {
          if (value == 0) {
            onGenresChanged({});
          } else {
            onGenresChanged({value});
          }
        }
      },
    );
  }

  Widget _buildStatusDropdown() {
    return _DropdownFilter<String>(
      value: selectedStatus,
      active: selectedStatus != allStatus,
      hint: 'Trạng thái',
      icon: Icons.circle_outlined,
      items: [
        DropdownMenuItem(value: allStatus, child: Text(allStatus)),
        const DropdownMenuItem(value: 'Đang tiến hành', child: Text('Đang tiến hành')),
        const DropdownMenuItem(value: 'Tạm ngưng', child: Text('Tạm ngưng')),
        const DropdownMenuItem(value: 'Đã hoàn thành', child: Text('Đã hoàn thành')),
      ],
      onChanged: (value) {
        if (value != null) {
          onStatusChanged(value);
        }
      },
    );
  }

  Widget _buildSortDropdown() {
    return _DropdownFilter<String>(
      value: selectedSort,
      active: selectedSort != 'A-Z',
      hint: 'Sắp xếp',
      icon: Icons.sort_rounded,
      items: const [
        DropdownMenuItem(value: 'A-Z', child: Text('A-Z')),
        DropdownMenuItem(value: 'Số chương', child: Text('Số chương')),
      ],
      onChanged: (value) {
        if (value != null) {
          onSortChanged(value);
        }
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Active filter chips
// ────────────────────────────────────────────────────────────────────────────

class _ActiveFilterChips extends StatelessWidget {
  final String selectedStatus;
  final String allStatus;
  final Set<int> selectedGenreIds;
  final List<GenreEntity> genres;
  final String searchText;
  final VoidCallback onClearStatus;
  final ValueChanged<int> onRemoveGenre;
  final VoidCallback onClearSearch;
  final VoidCallback onClearAll;

  const _ActiveFilterChips({
    required this.selectedStatus,
    required this.allStatus,
    required this.selectedGenreIds,
    required this.genres,
    required this.searchText,
    required this.onClearStatus,
    required this.onRemoveGenre,
    required this.onClearSearch,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> chips = [];

    if (searchText.isNotEmpty) {
      chips.add(
        _Chip(label: '"$searchText"', onRemove: onClearSearch),
      );
    }

    if (selectedStatus != allStatus) {
      chips.add(
        _Chip(label: selectedStatus, onRemove: onClearStatus),
      );
    }

    for (final genreId in selectedGenreIds) {
      final String genreName = genres
          .where((g) => g.id == genreId)
          .map((g) => g.name ?? 'Thể loại')
          .firstOrNull ?? 'Thể loại';
      chips.add(
        _Chip(label: genreName, onRemove: () => onRemoveGenre(genreId)),
      );
    }

    return Row(
      children: [
        const Text(
          'Lọc:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8491A7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...chips,
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onClearAll,
                  child: const Text(
                    'Xóa tất cả',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1F5BFF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _Chip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF93B4FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1F5BFF),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 13,
              color: Color(0xFF1F5BFF),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Generic dropdown button
// ────────────────────────────────────────────────────────────────────────────

class _DropdownFilter<T> extends StatelessWidget {
  final T value;
  final bool active;
  final String hint;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  const _DropdownFilter({
    required this.value,
    required this.active,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFEFF4FF) : const Color(0xFFF5F7FC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? const Color(0xFF93B4FF) : const Color(0xFFE4E8F2),
          width: active ? 1.5 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: active ? const Color(0xFF1F5BFF) : const Color(0xFF8491A7),
          ),
          style: TextStyle(
            color:
                active ? const Color(0xFF1F5BFF) : const Color(0xFF4D5B72),
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
