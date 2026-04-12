class GenreModel {
  final int? id;
  final String? name;

  const GenreModel({this.id, this.name});

  factory GenreModel.fromJson(Map<String, dynamic> map) {
    return GenreModel(
      id: _toInt(map['id'] ?? map['Id']),
      name: _toString(map['name'] ?? map['Name']),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static String _toString(dynamic value) {
    return value?.toString().trim() ?? '';
  }
}
