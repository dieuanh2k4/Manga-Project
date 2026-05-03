class ChapterPageEntity {
  final int id;
  final int chapterId;
  final int mangaId;
  final String imageUrl;

  const ChapterPageEntity({
    required this.id,
    required this.chapterId,
    required this.mangaId,
    required this.imageUrl,
  });
}
