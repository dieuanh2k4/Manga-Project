import 'package:flutter/foundation.dart';

import '../../domain/entities/chapter_entity.dart';
import '../../domain/entities/manga_entity.dart';
import '../../domain/usecases/get_chapters_by_manga_usecase.dart';
import '../../domain/usecases/get_manga_detail_usecase.dart';

class MangaDetailController extends ChangeNotifier {
  final GetMangaDetailUseCase getMangaDetailUseCase;
  final GetChaptersByMangaUseCase getChaptersByMangaUseCase;

  MangaDetailController({
    required this.getMangaDetailUseCase,
    required this.getChaptersByMangaUseCase,
  });

  MangaEntity? manga;
  List<ChapterEntity> chapters = const [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load(int mangaId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        getMangaDetailUseCase(mangaId),
        getChaptersByMangaUseCase(mangaId),
      ]);

      manga = results[0] as MangaEntity;
      chapters = results[1] as List<ChapterEntity>;
      chapters = [...chapters]
        ..sort((a, b) {
          final aNumber = double.tryParse(a.chapterNumber) ?? -1;
          final bNumber = double.tryParse(b.chapterNumber) ?? -1;
          return bNumber.compareTo(aNumber);
        });
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
