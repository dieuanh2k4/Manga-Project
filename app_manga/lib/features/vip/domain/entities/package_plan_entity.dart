class PackagePlanEntity {
  final int id;
  final String title;
  final int price;
  final int durationDays;
  final List<String> privileges;

  const PackagePlanEntity({
    required this.id,
    required this.title,
    required this.price,
    required this.durationDays,
    this.privileges = const [],
  });
}
