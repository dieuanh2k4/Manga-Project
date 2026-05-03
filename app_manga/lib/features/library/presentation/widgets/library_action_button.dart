import 'package:flutter/material.dart';

class LibraryActionButton extends StatelessWidget {
  final bool isInLibrary;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const LibraryActionButton({
    super.key,
    required this.isInLibrary,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return isInLibrary
        ? IconButton(
            icon: const Icon(Icons.bookmark_remove),
            tooltip: 'Xóa khỏi thư viện',
            onPressed: onRemove,
          )
        : IconButton(
            icon: const Icon(Icons.bookmark_add),
            tooltip: 'Thêm vào thư viện',
            onPressed: onAdd,
          );
  }
}
