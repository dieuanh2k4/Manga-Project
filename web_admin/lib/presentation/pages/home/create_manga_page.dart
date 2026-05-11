import 'package:flutter/material.dart';
import 'package:web_admin/core/models/upload_file_data.dart';
import 'package:web_admin/domain/entities/author.dart';
import 'package:web_admin/domain/entities/genre.dart';
import 'package:web_admin/domain/entities/manga.dart';
import 'package:web_admin/presentation/pages/home/create_manga_submit_result.dart';
import 'package:web_admin/presentation/widgets/manga_form_page.dart';

class CreateMangaPage extends StatelessWidget {
  final List<AuthorEntity> authors;
  final List<GenreEntity> genres;

  const CreateMangaPage({
    super.key,
    required this.authors,
    required this.genres,
  });

  @override
  Widget build(BuildContext context) {
    return MangaFormPage(
      appBarTitle: 'Tạo Manga mới',
      submitLabel: 'Tạo manga',
      authors: authors,
      genres: genres,
      normalizeStatus: _normalizeStatus,
      onSubmit: (MangaEntity manga, UploadFileData? thumbnailFile) {
        Navigator.of(context).pop(
          CreateMangaSubmitResult(
            manga: manga,
            thumbnailFile: thumbnailFile,
          ),
        );
      },
    );
  }

  String _normalizeStatus(String? value) {
    final String status = (value ?? '').trim();
    return status.isEmpty ? 'Đang tiến hành' : status;
  }
}
