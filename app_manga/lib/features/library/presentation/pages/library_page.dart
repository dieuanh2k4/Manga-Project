import 'package:flutter/material.dart';
import '../controllers/library_controller.dart';
import '../../../manga/presentation/widgets/manga_card.dart';
import 'package:provider/provider.dart';

class LibraryPage extends StatelessWidget {
  final String token;
  const LibraryPage({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LibraryController(
        getLibraryMangaUseCase: context.read(),
        addMangaToLibraryUseCase: context.read(),
        deleteMangaFromLibraryUseCase: context.read(),
      )..fetchLibraryManga(token),
      child: Consumer<LibraryController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.error != null) {
            return Center(child: Text('Lỗi: ${controller.error}'));
          }
          if (controller.libraryManga.isEmpty) {
            return const Center(child: Text('Thư viện của bạn trống.')); 
          }
          return ListView.builder(
            itemCount: controller.libraryManga.length,
            itemBuilder: (context, index) {
              final manga = controller.libraryManga[index];
              return MangaCard(manga: manga);
            },
          );
        },
      ),
    );
  }
}
