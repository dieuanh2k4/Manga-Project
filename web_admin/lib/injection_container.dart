import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:web_admin/data/data_sources/remote/new_api_service.dart';
import 'package:web_admin/data/repository/manga_repo_implement.dart';
import 'package:web_admin/domain/repository/manga_repository.dart';
import 'package:web_admin/domain/usecases/get_manga.dart';
import 'package:web_admin/presentation/bloc/manga/remote/remote_manga_bloc.dart';

final sl = GetIt.instance;

Future<void> initilizeDependencies() async {
  // Dio
  sl.registerSingleton<Dio>(Dio());

  // Dependencies
  sl.registerSingleton<NewApiService>(NewApiService(sl()));

  sl.registerSingleton<MangaRepository>(MangaRepoImplement(sl()));

  // Usecases
  sl.registerSingleton<GetMangaUseCase>(GetMangaUseCase(sl()));

  // Blocs
  sl.registerFactory<RemoteMangaBloc>(() => RemoteMangaBloc(sl()));
}
