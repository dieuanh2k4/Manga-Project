import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_admin/core/utils/auth_token_storage.dart';
import 'package:web_admin/data/data_sources/remote/lookup_api_service.dart';
import 'package:web_admin/data/data_sources/remote/manga_update_api_service.dart';
import 'package:web_admin/data/data_sources/remote/new_api_service.dart';
import 'package:web_admin/data/repository/lookup_repo_implement.dart';
import 'package:web_admin/data/repository/manga_repo_implement.dart';
import 'package:web_admin/domain/repository/lookup_repository.dart';
import 'package:web_admin/domain/repository/manga_repository.dart';
import 'package:web_admin/domain/usecases/get_authors.dart';
import 'package:web_admin/domain/usecases/get_genres.dart';
import 'package:web_admin/domain/usecases/get_manga.dart';
import 'package:web_admin/domain/usecases/update_manga.dart';
import 'package:web_admin/presentation/bloc/manga/remote/remote_manga_bloc.dart';
import 'package:web_admin/presentation/helper/manage_manga_service.dart';

final sl = GetIt.instance;

Future<void> initilizeDependencies() async {
  // Dio
  sl.registerSingleton<Dio>(Dio());

  // Local storage
  final SharedPreferences sharedPreferences =
      await SharedPreferences.getInstance();
  sl.registerSingleton<AuthTokenStorage>(AuthTokenStorage(sharedPreferences));

  // Dependencies
  sl.registerSingleton<NewApiService>(NewApiService(sl()));
  sl.registerSingleton<LookupApiService>(LookupApiService(sl()));
  sl.registerSingleton<MangaUpdateApiService>(
    MangaUpdateApiService(sl(), sl()),
  );

  sl.registerSingleton<MangaRepository>(MangaRepoImplement(sl(), sl()));
  sl.registerSingleton<LookupRepository>(LookupRepoImplement(sl()));

  // Usecases
  sl.registerSingleton<GetMangaUseCase>(GetMangaUseCase(sl()));
  sl.registerSingleton<UpdateMangaUseCase>(UpdateMangaUseCase(sl()));
  sl.registerSingleton<GetAuthorsUseCase>(GetAuthorsUseCase(sl()));
  sl.registerSingleton<GetGenresUseCase>(GetGenresUseCase(sl()));

  // Presentation services
  sl.registerSingleton<ManageMangaService>(
    ManageMangaService(sl(), sl(), sl()),
  );

  // Blocs
  sl.registerFactory<RemoteMangaBloc>(() => RemoteMangaBloc(sl()));
}
