import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/datasources/library_remote_data_source.dart';
import 'data/repositories/library_repository_impl.dart';
import 'domain/repositories/library_repository.dart';
import 'domain/usecases/get_library_manga_usecase.dart';
import 'domain/usecases/add_manga_to_library_usecase.dart';
import 'domain/usecases/delete_manga_from_library_usecase.dart';
import 'presentation/controllers/library_controller.dart';

class LibraryProviders extends StatelessWidget {
  final Widget child;
  const LibraryProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final remoteDataSource = LibraryRemoteDataSource();
    final repository = LibraryRepositoryImpl(remoteDataSource);
    return MultiProvider(
      providers: [
        Provider<LibraryRepository>.value(value: repository),
        Provider<GetLibraryMangaUseCase>.value(value: GetLibraryMangaUseCase(repository)),
        Provider<AddMangaToLibraryUseCase>.value(value: AddMangaToLibraryUseCase(repository)),
        Provider<DeleteMangaFromLibraryUseCase>.value(value: DeleteMangaFromLibraryUseCase(repository)),
        ChangeNotifierProvider(
          create: (_) => LibraryController(
            getLibraryMangaUseCase: GetLibraryMangaUseCase(repository),
            addMangaToLibraryUseCase: AddMangaToLibraryUseCase(repository),
            deleteMangaFromLibraryUseCase: DeleteMangaFromLibraryUseCase(repository),
          ),
        ),
      ],
      child: child,
    );
  }
}
