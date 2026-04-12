class AuthorModel {
  final int? id;
  final String? fullName;

  const AuthorModel({this.id, this.fullName});

  factory AuthorModel.fromJson(Map<String, dynamic> map) {
    return AuthorModel(
      id: _toInt(map['id'] ?? map['Id']),
      fullName: _toString(
        map['fullName'] ?? map['fullname'] ?? map['FullName'] ?? map['name'],
      ),
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
