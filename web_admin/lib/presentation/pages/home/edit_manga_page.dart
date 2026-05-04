import 'package:flutter/material.dart';
import 'package:web_admin/core/models/upload_file_data.dart';
import 'package:web_admin/domain/entities/author.dart';
import 'package:web_admin/domain/entities/genre.dart';
import 'package:web_admin/domain/entities/manga.dart';
import 'package:web_admin/presentation/pages/home/edit_manga_submit_result.dart';
import 'package:web_admin/presentation/widgets/manga_form_page.dart';

class EditMangaPage extends StatelessWidget {
  final MangaEntity manga;
  final List<AuthorEntity> authors;
  final List<GenreEntity> genres;
  final String Function(String?) normalizeStatus;

  const EditMangaPage({
    super.key,
    required this.manga,
    required this.authors,
    required this.genres,
    required this.normalizeStatus,
  });

  @override
  Widget build(BuildContext context) {
    return MangaFormPage(
      appBarTitle: 'Chỉnh sửa Manga #${manga.id ?? ''}',
      submitLabel: 'Lưu cập nhật',
      initialManga: manga,
      authors: authors,
      genres: genres,
      normalizeStatus: normalizeStatus,
      onSubmit: (MangaEntity updated, UploadFileData? thumbnailFile) {
        Navigator.of(context).pop(
          EditMangaSubmitResult(
            manga: updated,
            thumbnailFile: thumbnailFile,
          ),
        );
      },
    );
  }
}
