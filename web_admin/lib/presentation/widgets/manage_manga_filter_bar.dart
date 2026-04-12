import 'package:flutter/material.dart';

class ManageMangaFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedStatus;
  final String allStatus;
  final ValueChanged<String> onStatusChanged;

  const ManageMangaFilterBar({
    super.key,
    required this.searchController,
    required this.selectedStatus,
    required this.allStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Widget searchField = TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: 'Tìm kiếm theo tên hoặc tác giả...',
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
    );

    final Widget statusDropdown = Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedStatus,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          style: const TextStyle(color: Color(0xFF4D5B72), fontSize: 13),
          items: [
            DropdownMenuItem(
              value: allStatus,
              child: const Text('Tất cả trạng thái'),
            ),
            const DropdownMenuItem(
              value: 'Đang tiến hành',
              child: Text('Đang tiến hành'),
            ),
            const DropdownMenuItem(
              value: 'Hoàn thành',
              child: Text('Hoàn thành'),
            ),
            const DropdownMenuItem(value: 'Tạm dừng', child: Text('Tạm dừng')),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            onStatusChanged(value);
          },
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E8F2)),
      ),
      padding: const EdgeInsets.all(10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isTight = constraints.maxWidth < 760;

          if (isTight) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchField,
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerLeft, child: statusDropdown),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 12),
              statusDropdown,
            ],
          );
        },
      ),
    );
  }
}
