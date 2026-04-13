class MangaEntity {
  final int id;
  final String title;
  final String? description;
  final String? thumbnail;
  final int totalChapter;
  final int rate;
  final String? status;

  const MangaEntity({
    required this.id,
    required this.title,
    this.description,
    this.thumbnail,
    required this.totalChapter,
    required this.rate,
    this.status,
  });
}
