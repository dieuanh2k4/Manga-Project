import 'package:flutter/foundation.dart';

import '../../domain/entities/manga_entity.dart';
import '../../domain/usecases/get_all_manga_usecase.dart';

class HomeController extends ChangeNotifier {
  final GetAllMangaUseCase getAllMangaUseCase;

  HomeController({required this.getAllMangaUseCase});

  List<MangaEntity> mangas = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadManga() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      mangas = await getAllMangaUseCase();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
