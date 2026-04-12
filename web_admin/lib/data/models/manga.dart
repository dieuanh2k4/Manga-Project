class MangaModel {
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

  MangaModel({
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

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'thumbnail': thumbnail,
      'status': status,
      'totalChapter': totalChapter,
      'rate': rate,
      'authorId': authorId,
      'genreIds': genreIds,
      'releaseDate': releaseDate,
      'endDate': endDate,
    };
  }

  factory MangaModel.fromJson(Map<String, dynamic> map) {
    return MangaModel(
      id: _toInt(map['id']),
      title: _toString(map['title']),
      description: _toString(map['description']),
      thumbnail: _toString(map['thumbnail']),
      status: _toString(map['status']),
      totalChapter: _toInt(map['totalChapter']),
      rate: _toInt(map['rate']),
      authorId: _toInt(map['authorId'] ?? map['authorid']),
      genreIds: _toIntList(map['genreIds']),
      releaseDate: _toDateTime(map['releaseDate']),
      endDate: _toDateTime(map['endDate']),
    );
  }

  static String _toString(dynamic value) {
    return value?.toString() ?? '';
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static List<int>? _toIntList(dynamic value) {
    if (value == null) return null;

    if (value is List) {
      return value.map(_toInt).whereType<int>().toList();
    }

    if (value is Map<String, dynamic>) {
      final wrappedValues = value[r'$values'];
      if (wrappedValues is List) {
        return wrappedValues.map(_toInt).whereType<int>().toList();
      }
    }

    return null;
  }
}
