import '../../domain/entities/package_plan_entity.dart';
import '../../../../core/network/json_list_parser.dart';

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
    final rawPrivileges = JsonListParser.extractList(
      json['previlages'] ??
          json['Previlages'] ??
          json['privileges'] ??
          json['Privileges'],
    );

    return PackagePlanModel(
      id: json['id'] ?? json['Id'] ?? 0,
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      price: json['price'] ?? json['Price'] ?? 0,
      durationDays: json['durationDays'] ?? json['DurationDays'] ?? 0,
      privileges: rawPrivileges
          .whereType<Map<String, dynamic>>()
          .map((item) => (item['content'] ?? item['Content'] ?? '').toString())
          .where((item) => item.isNotEmpty)
          .toList(),
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
