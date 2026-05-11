class NotificationModel {
  final int? id;
  final String? title;
  final String? content;
  final String? targetRole;
  final int? mangaId;
  final DateTime? createAt;
  final bool? isRead;

  const NotificationModel({
    this.id,
    this.title,
    this.content,
    this.targetRole,
    this.mangaId,
    this.createAt,
    this.isRead,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'content': content,
      'targetRole': targetRole,
      'mangaId': mangaId,
      'createAt': createAt,
      'isRead': isRead,
    };
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

  static bool? _tobool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    return bool.tryParse(value.toString());
  }

  factory NotificationModel.fromJson(Map<String, dynamic> map) {
    return NotificationModel(
      id: _toInt(map['id']),
      title: _toString(map['title']),
      content: _toString(map['content']),
      targetRole: _toString(map['targetRole']),
      mangaId: _toInt(map['mangaId']),
      createAt: _toDateTime(map['createAt']),
      isRead: _tobool(map['isRead']),
    );
  }
}
