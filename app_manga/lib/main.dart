import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:provider/provider.dart';

import 'core/security/screen_security_service.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_my_profile_usecase.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/domain/usecases/restore_session_usecase.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/manga/data/datasources/manga_remote_data_source.dart';
import 'features/manga/data/repositories/manga_repository_impl.dart';
import 'features/manga/domain/repositories/manga_repository.dart';
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
    final mangaRemoteDataSource = MangaRemoteDataSource();
    final mangaRepository = MangaRepositoryImpl(remoteDataSource: mangaRemoteDataSource);

    final authRemoteDataSource = AuthRemoteDataSource();
    final authLocalDataSource = AuthLocalDataSource();
    final authRepository = AuthRepositoryImpl(
      remote: authRemoteDataSource,
      local: authLocalDataSource,
    );

    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepository),
        Provider<MangaRepository>.value(value: mangaRepository),
        ChangeNotifierProvider(
          create: (_) => AuthController(
            loginUseCase: LoginUseCase(authRepository),
            registerUseCase: RegisterUseCase(authRepository),
            getMyProfileUseCase: GetMyProfileUseCase(authRepository),
            restoreSessionUseCase: RestoreSessionUseCase(authRepository),
            logoutUseCase: LogoutUseCase(authRepository),
          )..bootstrap(),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeController(
            getAllMangaUseCase: GetAllMangaUseCase(mangaRepository),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => MangaSearchController(
            getAllMangaUseCase: GetAllMangaUseCase(mangaRepository),
            searchMangaUseCase: SearchMangaUseCase(mangaRepository),
            getOngoingMangaUseCase: GetOngoingMangaUseCase(mangaRepository),
            getCompletedMangaUseCase: GetCompletedMangaUseCase(mangaRepository),
            getAllGenresUseCase: GetAllGenresUseCase(mangaRepository),
            getMangaByGenreUseCase: GetMangaByGenreUseCase(mangaRepository),
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
        home: const AuthGatePage(),
      ),
    );
  }
}

class AuthGatePage extends StatelessWidget {
  const AuthGatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        if (auth.isBootstrapping) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFE8742B)),
            ),
          );
        }

        if (auth.isAuthenticated) {
          return const HomePage();
        }

        return const AuthPage();
      },
    );
  }
}
