import '../../domain/entities/package_plan_entity.dart';

class PackagePlanModel {
  final int id;
  final String title;
  final int price;
  final int durationDays;
  final List<String> privileges;

  const PackagePlanModel({
    required this.id,
    required this.title,
    required this.price,
    required this.durationDays,
    this.privileges = const [],
  });

  factory PackagePlanModel.fromJson(Map<String, dynamic> json) {
    final rawPrivileges = (json['previlages'] ?? json['Previlages']) as List?;

    return PackagePlanModel(
      id: json['id'] ?? json['Id'] ?? 0,
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      price: json['price'] ?? json['Price'] ?? 0,
      durationDays: json['durationDays'] ?? json['DurationDays'] ?? 0,
      privileges:
          rawPrivileges
              ?.whereType<Map<String, dynamic>>()
              .map(
                (item) => (item['content'] ?? item['Content'] ?? '').toString(),
              )
              .where((item) => item.isNotEmpty)
              .toList() ??
          const [],
    );
  }

  PackagePlanEntity toEntity() {
    return PackagePlanEntity(
      id: id,
      title: title,
      price: price,
      durationDays: durationDays,
      privileges: privileges,
    );
  }
}
