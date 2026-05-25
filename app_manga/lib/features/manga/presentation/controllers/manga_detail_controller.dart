import 'package:flutter/foundation.dart';

import '../../domain/entities/chapter_entity.dart';
import '../../domain/entities/manga_entity.dart';
import '../../domain/usecases/get_chapters_by_manga_usecase.dart';
import '../../domain/usecases/get_manga_detail_usecase.dart';
import '../../../library/domain/entities/history_item_entity.dart';
import '../../../library/domain/usecases/get_history_usecase.dart';

class MangaDetailController extends ChangeNotifier {
  final GetMangaDetailUseCase getMangaDetailUseCase;
  final GetChaptersByMangaUseCase getChaptersByMangaUseCase;
  final GetHistoryUseCase getHistoryUseCase;

  MangaDetailController({
    required this.getMangaDetailUseCase,
    required this.getChaptersByMangaUseCase,
    required this.getHistoryUseCase,
  });

  MangaEntity? manga;
  List<ChapterEntity> chapters = const [];
  HistoryItemEntity? lastHistoryItem;
  bool isLoading = false;
  String? errorMessage;

  Future<void> load(int mangaId, {String? token}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (token == null || token.isEmpty) {
        final results = await Future.wait([
          getMangaDetailUseCase(mangaId),
          getChaptersByMangaUseCase(mangaId),
        ]);

        manga = results[0] as MangaEntity;
        chapters = results[1] as List<ChapterEntity>;
        lastHistoryItem = null;
      } else {
        final results = await Future.wait([
          getMangaDetailUseCase(mangaId),
          getChaptersByMangaUseCase(mangaId),
          getHistoryUseCase(token),
        ]);

        manga = results[0] as MangaEntity;
        chapters = results[1] as List<ChapterEntity>;
        final historyItems = results[2] as List<HistoryItemEntity>;
        final matches = historyItems.where((item) => item.mangaId == mangaId);
        lastHistoryItem = matches.isEmpty ? null : matches.first;
      }
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
