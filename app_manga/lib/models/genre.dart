class Genre {
  final int id;
  final String name;

  const Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'] ?? json['Id'] ?? 0,
      name: (json['name'] ?? json['Name'] ?? '').toString(),
    );
  }
}
