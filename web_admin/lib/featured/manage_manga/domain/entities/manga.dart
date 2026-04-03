import 'package:equatable/equatable.dart';

class MangaEntity extends Equatable {
  final int? id;
  final String? title;
  final String? description;
  final String? thumbnail;
  final String? status;
  final int? totalChapter;
  final int? rate;
  final int? authorId;
  final List<int>? genreIds;
  final DateTime? releaseDate;
  final DateTime? endDate;

  const MangaEntity({
    this.id,
    this.title,
    this.description,
    this.thumbnail,
    this.status,
    this.totalChapter,
    this.rate,
    this.authorId,
    this.genreIds,
    this.releaseDate,
    this.endDate,
  });

  @override
  List<Object?> get props {
    return [
      id,
      title,
      description,
      thumbnail,
      status,
      totalChapter,
      rate,
      authorId,
      genreIds,
      releaseDate,
      endDate,
    ];
  }
}
