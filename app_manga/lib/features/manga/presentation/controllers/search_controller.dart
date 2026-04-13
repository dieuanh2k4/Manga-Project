import 'package:flutter/foundation.dart';

import '../../domain/entities/genre_entity.dart';
import '../../domain/entities/manga_entity.dart';
import '../../domain/usecases/get_all_genres_usecase.dart';
import '../../domain/usecases/get_all_manga_usecase.dart';
import '../../domain/usecases/get_completed_manga_usecase.dart';
import '../../domain/usecases/get_manga_by_genre_usecase.dart';
import '../../domain/usecases/get_ongoing_manga_usecase.dart';
import '../../domain/usecases/search_manga_usecase.dart';

class MangaSearchController extends ChangeNotifier {
  final GetAllMangaUseCase getAllMangaUseCase;
  final SearchMangaUseCase searchMangaUseCase;
  final GetOngoingMangaUseCase getOngoingMangaUseCase;
  final GetCompletedMangaUseCase getCompletedMangaUseCase;
  final GetAllGenresUseCase getAllGenresUseCase;
  final GetMangaByGenreUseCase getMangaByGenreUseCase;

  MangaSearchController({
    required this.getAllMangaUseCase,
    required this.searchMangaUseCase,
    required this.getOngoingMangaUseCase,
    required this.getCompletedMangaUseCase,
    required this.getAllGenresUseCase,
    required this.getMangaByGenreUseCase,
  });

  List<MangaEntity> allManga = [];
  List<MangaEntity> searchResult = [];
  List<MangaEntity> ongoingManga = [];
  List<MangaEntity> completedManga = [];
  List<GenreEntity> genres = [];
  final Map<int, List<MangaEntity>> genreMangaCache = {};

  bool isLoading = false;
  bool isFilteringGenre = false;
  String? errorMessage;

  String selectedStatus = 'Continuous';
  GenreEntity? selectedGenre;

  Future<void> initialize() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        getAllMangaUseCase(),
        getOngoingMangaUseCase(),
        getCompletedMangaUseCase(),
        getAllGenresUseCase(),
      ]);

      allManga = results[0] as List<MangaEntity>;
      searchResult = allManga;
      ongoingManga = results[1] as List<MangaEntity>;
      completedManga = results[2] as List<MangaEntity>;
      genres = results[3] as List<GenreEntity>;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> onSearchChanged(String value) async {
    final query = value.trim();

    if (query.isEmpty) {
      searchResult = allManga;
      notifyListeners();
      return;
    }

    try {
      searchResult = await searchMangaUseCase(query);
    } catch (_) {
      final keyword = query.toLowerCase();
      searchResult = allManga
          .where((m) => m.title.toLowerCase().contains(keyword))
          .toList();
    }

    notifyListeners();
  }

  List<MangaEntity> popularItems() {
    final copy = List<MangaEntity>.from(searchResult);
    copy.sort((a, b) => b.rate.compareTo(a.rate));
    return copy;
  }

  List<MangaEntity> lastUpdateItems() {
    final copy = List<MangaEntity>.from(searchResult);
    copy.sort((a, b) => b.id.compareTo(a.id));
    return copy;
  }

  List<MangaEntity> directoryItems() {
    List<MangaEntity> base;
    switch (selectedStatus) {
      case 'Continuous':
        base = ongoingManga;
        break;
      case 'Complete':
        base = completedManga;
        break;
      case 'New':
        base = lastUpdateItems();
        break;
      default:
        base = allManga;
    }

    if (selectedGenre == null) {
      return base;
    }

    final genreItems = genreMangaCache[selectedGenre!.id] ?? const <MangaEntity>[];
    final allowedIds = genreItems.map((e) => e.id).toSet();
    return base.where((m) => allowedIds.contains(m.id)).toList();
  }

  void selectStatus(String status) {
    selectedStatus = status;
    notifyListeners();
  }

  Future<void> toggleGenre(GenreEntity genre) async {
    if (selectedGenre?.id == genre.id) {
      selectedGenre = null;
      notifyListeners();
      return;
    }

    selectedGenre = genre;
    notifyListeners();

    if (genreMangaCache.containsKey(genre.id)) {
      return;
    }

    isFilteringGenre = true;
    notifyListeners();

    try {
      genreMangaCache[genre.id] = await getMangaByGenreUseCase(genre.id);
    } catch (_) {
      genreMangaCache[genre.id] = const [];
    } finally {
      isFilteringGenre = false;
      notifyListeners();
    }
  }
}
