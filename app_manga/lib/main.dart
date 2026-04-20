import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:provider/provider.dart';

import 'core/security/screen_security_service.dart';

import 'features/manga/data/datasources/manga_remote_data_source.dart';
import 'features/manga/data/repositories/manga_repository_impl.dart';
import 'features/manga/domain/usecases/get_all_genres_usecase.dart';
import 'features/manga/domain/usecases/get_all_manga_usecase.dart';
import 'features/manga/domain/usecases/get_completed_manga_usecase.dart';
import 'features/manga/domain/usecases/get_manga_by_genre_usecase.dart';
import 'features/manga/domain/usecases/get_ongoing_manga_usecase.dart';
import 'features/manga/domain/usecases/search_manga_usecase.dart';
import 'features/manga/presentation/controllers/home_controller.dart';
import 'features/manga/presentation/controllers/search_controller.dart';
import 'features/manga/presentation/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScreenSecurityService.instance.initialize();
  await _enableScreenSecurity();
  runApp(const MangaApp());
}

Future<void> _enableScreenSecurity() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return;
  }

  try {
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  } catch (_) {
    // Keep app startup resilient if the platform channel is unavailable.
  }
}

class MangaApp extends StatelessWidget {
  const MangaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final remoteDataSource = MangaRemoteDataSource();
    final repository = MangaRepositoryImpl(remoteDataSource: remoteDataSource);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HomeController(
            getAllMangaUseCase: GetAllMangaUseCase(repository),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => MangaSearchController(
            getAllMangaUseCase: GetAllMangaUseCase(repository),
            searchMangaUseCase: SearchMangaUseCase(repository),
            getOngoingMangaUseCase: GetOngoingMangaUseCase(repository),
            getCompletedMangaUseCase: GetCompletedMangaUseCase(repository),
            getAllGenresUseCase: GetAllGenresUseCase(repository),
            getMangaByGenreUseCase: GetMangaByGenreUseCase(repository),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Manga App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFFC75F25),
          scaffoldBackgroundColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC75F25)),
        ),
        home: const HomePage(),
      ),
    );
  }
}
