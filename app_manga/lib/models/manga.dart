import 'dart:convert';

class Manga {
  final int id;
  final String title;
  final String? description;
  final String? thumbnail;
  final int totalChapter;
  final int rate;
  final String? status;

  Manga({
    required this.id,
    required this.title,
    this.description,
    this.thumbnail,
    required this.totalChapter,
    required this.rate,
    this.status,
  });

  factory Manga.fromJson(Map<String, dynamic> json) {
    return Manga(
      id: json['id'] ?? json['Id'] ?? 0,
      title: json['title'] ?? json['Title'] ?? 'Unknown Title',
      description: json['description'] ?? json['Description'],
      thumbnail: json['thumbnail'] ?? json['Thumbnail'],
      totalChapter: json['totalChapter'] ?? json['TotalChapter'] ?? 0,
      rate: json['rate'] ?? json['Rate'] ?? 0,
      status: json['status'] ?? json['Status'],
    );
  }
}
