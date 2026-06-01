import 'package:flutter/material.dart';

import '../../../../core/notifications/fcm_notification_service.dart';
import '../../../manga/domain/entities/manga_entity.dart';
import '../../domain/entities/history_item_entity.dart';
import '../../domain/entities/library_manga_entity.dart';
import '../../domain/usecases/add_manga_to_library_usecase.dart';
import '../../domain/usecases/delete_manga_from_library_usecase.dart';
import '../../domain/usecases/get_history_usecase.dart';
import '../../domain/usecases/get_library_manga_usecase.dart';

class LibraryController extends ChangeNotifier {
  final GetLibraryMangaUseCase getLibraryMangaUseCase;
  final GetHistoryUseCase getHistoryUseCase;
  final AddMangaToLibraryUseCase addMangaToLibraryUseCase;
  final DeleteMangaFromLibraryUseCase deleteMangaFromLibraryUseCase;

  List<LibraryMangaEntity> libraryManga = [];
  List<HistoryItemEntity> historyItems = [];
  bool isLoading = false;
  String? error;

  LibraryController({
    required this.getLibraryMangaUseCase,
    required this.getHistoryUseCase,
    required this.addMangaToLibraryUseCase,
    required this.deleteMangaFromLibraryUseCase,
  });

  Future<void> fetchLibraryManga(String token) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      libraryManga = await getLibraryMangaUseCase(token);
      await _runNotificationSideEffect(
        () => FcmNotificationService.instance.syncMangaTopics(
          libraryManga.map((manga) => manga.id),
        ),
      );
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchHistory(String token) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      historyItems = await getHistoryUseCase(token);
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> addManga(
    int mangaId,
    String token, {
    MangaEntity? manga,
  }) async {
    try {
      error = null;
      await addMangaToLibraryUseCase(mangaId, token);
      await _refreshLibraryMangaAfterMutation(token);
      if (!libraryManga.any((item) => item.id == mangaId) && manga != null) {
        libraryManga = [
          ...libraryManga,
          LibraryMangaEntity(
            id: manga.id,
            title: manga.title,
            description: manga.description,
            thumbnail: manga.thumbnail,
            totalChapter: manga.totalChapter,
            rate: manga.rate,
            status: manga.status,
            genres: manga.genres,
          ),
        ];
        notifyListeners();
      }
      await _runNotificationSideEffect(
        () => FcmNotificationService.instance.subscribeToManga(mangaId),
      );
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteManga(int mangaId, String token) async {
    try {
      error = null;
      await deleteMangaFromLibraryUseCase(mangaId, token);
      await _refreshLibraryMangaAfterMutation(token);
      if (libraryManga.any((item) => item.id == mangaId)) {
        libraryManga = libraryManga
            .where((item) => item.id != mangaId)
            .toList(growable: false);
        notifyListeners();
      }
      await _runNotificationSideEffect(
        () => FcmNotificationService.instance.unsubscribeFromManga(mangaId),
      );
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> _refreshLibraryMangaAfterMutation(String token) async {
    try {
      libraryManga = await getLibraryMangaUseCase(token);
      await _runNotificationSideEffect(
        () => FcmNotificationService.instance.syncMangaTopics(
          libraryManga.map((manga) => manga.id),
        ),
      );
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _runNotificationSideEffect(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Library state must still update when notification topic sync is unavailable.
    }
  }
}
