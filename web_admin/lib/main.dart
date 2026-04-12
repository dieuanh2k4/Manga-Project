import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin/config/theme/app_themes.dart';
import 'package:web_admin/presentation/bloc/manga/remote/remote_manga_bloc.dart';
import 'package:web_admin/presentation/bloc/manga/remote/remote_manga_event.dart';
import 'package:web_admin/presentation/pages/home/manage_manga.dart';
import 'package:web_admin/injection_container.dart';

Future<void> main() async {
  await initilizeDependencies();
  runApp(const WebAdmin());
}

class WebAdmin extends StatelessWidget {
  const WebAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RemoteMangaBloc>(
      create: (context) => sl()..add(const GetManga()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme(),
        home: ManageManga(),
      ),
    );
  }
}
