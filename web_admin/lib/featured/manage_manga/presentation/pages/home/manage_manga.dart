import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin/featured/manage_manga/presentation/bloc/manga/remote/remote_manga_bloc.dart';
import 'package:web_admin/featured/manage_manga/presentation/bloc/manga/remote/remote_manga_state.dart';

class ManageManga extends StatelessWidget {
  const ManageManga({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(), body: _buildBody());
  }

  _buildAppBar() {
    return AppBar(
      title: const Text('Quản lý Manga', style: TextStyle(color: Colors.black)),
    );
  }

  _buildBody() {
    return BlocBuilder<RemoteMangaBloc, RemoteMangaState>(
      builder: (_, state) {
        if (state is RemoteMangaLoading) {
          return const Center(child: CupertinoActivityIndicator());
        }

        if (state is RemoteMangaError) {
          return const Center(child: Icon(Icons.refresh));
        }

        if (state is RemoteMangaDone) {
          return ListView.builder(
            itemBuilder: (context, index) {
              return ListTile(title: Text('$index'));
            },
            itemCount: state.manga!.length,
          );
        }
        return const SizedBox();
      },
    );
  }
}
