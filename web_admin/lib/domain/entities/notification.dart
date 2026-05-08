import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final int? id;
  final String? title;
  final String? content;
  final String? targetRole;
  final int? mangaId;
  final DateTime? createAt;
  final bool? isRead;

  const NotificationEntity({
    this.id,
    this.title,
    this.content,
    this.targetRole,
    this.mangaId,
    this.createAt,
    this.isRead,
  });

  @override
  List<Object?> get props {
    return [id, title, content, targetRole, mangaId, createAt, isRead];
  }
}
