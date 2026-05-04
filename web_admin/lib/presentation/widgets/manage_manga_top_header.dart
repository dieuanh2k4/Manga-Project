import 'package:flutter/material.dart';

class ManageMangaTopHeader extends StatelessWidget {
  final TextEditingController searchController;
  final Future<void> Function()? onLogout;
  final String hintText;

  const ManageMangaTopHeader({
    super.key,
    required this.searchController,
    this.onLogout,
    this.hintText = 'Tìm kiếm manga, người dùng...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7EBF3))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 380,
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      color: Color(0xFFA6ADBB),
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFFA6ADBB),
                      size: 18,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    fillColor: const Color(0xFFF4F6FA),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF68758C),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.settings_outlined,
              color: Color(0xFF68758C),
              size: 20,
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: onLogout == null ? null : () => onLogout!(),
            icon: const Icon(
              Icons.logout_rounded,
              color: Color(0xFF68758C),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
