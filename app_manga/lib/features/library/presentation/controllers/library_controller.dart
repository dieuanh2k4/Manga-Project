import '../../domain/entities/library_manga_entity.dart';
import '../../domain/usecases/get_library_manga_usecase.dart';
import '../../domain/usecases/add_manga_to_library_usecase.dart';
import '../../domain/usecases/delete_manga_from_library_usecase.dart';
import '../../../../core/notifications/fcm_notification_service.dart';
import 'package:flutter/material.dart';

class LibraryController extends ChangeNotifier {
  final GetLibraryMangaUseCase getLibraryMangaUseCase;
  final AddMangaToLibraryUseCase addMangaToLibraryUseCase;
  final DeleteMangaFromLibraryUseCase deleteMangaFromLibraryUseCase;

  List<LibraryMangaEntity> libraryManga = [];
  bool isLoading = false;
  String? error;

  LibraryController({
    required this.getLibraryMangaUseCase,
    required this.addMangaToLibraryUseCase,
    required this.deleteMangaFromLibraryUseCase,
  });

  Future<void> fetchLibraryManga(String token) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      libraryManga = await getLibraryMangaUseCase(token);
      await FcmNotificationService.instance.syncMangaTopics(
        libraryManga.map((manga) => manga.id),
      );
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> addManga(int mangaId, String token) async {
    try {
      await addMangaToLibraryUseCase(mangaId, token);
      // app subcribe topic khi user add manga vào library
      await FcmNotificationService.instance.subscribeToManga(mangaId);
      await fetchLibraryManga(token);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteManga(int mangaId, String token) async {
    try {
      await deleteMangaFromLibraryUseCase(mangaId, token);
      // app unsubcribe topic khi user add manga vào library
      await FcmNotificationService.instance.unsubscribeFromManga(mangaId);
      await fetchLibraryManga(token);
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}
