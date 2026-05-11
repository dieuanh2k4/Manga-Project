import 'package:shared_preferences/shared_preferences.dart';

class ReadingProgressService {
  const ReadingProgressService._();

  static String _key(int mangaId, int chapterId) =>
      'reading_progress_${mangaId}_$chapterId';

  static String _lastChapterKey(int mangaId) =>
      'reading_progress_last_chapter_$mangaId';

  static Future<void> saveProgress({
    required int mangaId,
    required int chapterId,
    required int pageIndex,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(mangaId, chapterId), pageIndex);
    await prefs.setInt(_lastChapterKey(mangaId), chapterId);
  }

  static Future<int?> getProgress({
    required int mangaId,
    required int chapterId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key(mangaId, chapterId));
  }

  static Future<int?> getLastChapter({
    required int mangaId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastChapterKey(mangaId));
  }
}