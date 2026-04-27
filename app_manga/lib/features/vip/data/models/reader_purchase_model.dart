import '../../domain/entities/reader_purchase_entity.dart';

class ReaderPurchaseModel {
  final int purchaseId;
  final int packageId;
  final String packageTitle;
  final int packagePrice;
  final int packageDurationDays;
  final DateTime purchasedAt;
  final DateTime? expiredAt;
  final List<String> packagePrivileges;

  const ReaderPurchaseModel({
    required this.purchaseId,
    required this.packageId,
    required this.packageTitle,
    required this.packagePrice,
    required this.packageDurationDays,
    required this.purchasedAt,
    required this.expiredAt,
    this.packagePrivileges = const [],
  });

  factory ReaderPurchaseModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value, {DateTime? fallback}) {
      final raw = value?.toString();
      if (raw == null || raw.isEmpty) {
        return fallback ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      }

      return DateTime.tryParse(raw)?.toLocal() ??
          fallback ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }

    DateTime? parseNullableDate(dynamic value) {
      final raw = value?.toString();
      if (raw == null || raw.isEmpty) {
        return null;
      }

      return DateTime.tryParse(raw)?.toLocal();
    }

    final rawPrivileges =
        (json['packagePrevilages'] ?? json['PackagePrevilages']) as List?;

    return ReaderPurchaseModel(
      purchaseId: json['purchaseId'] ?? json['PurchaseId'] ?? 0,
      packageId: json['packageId'] ?? json['PackageId'] ?? 0,
      packageTitle: (json['packageTitle'] ?? json['PackageTitle'] ?? '')
          .toString(),
      packagePrice: json['packagePrice'] ?? json['PackagePrice'] ?? 0,
      packageDurationDays:
          json['packageDurationDays'] ?? json['PackageDurationDays'] ?? 0,
      purchasedAt: parseDate(json['purchasedAt'] ?? json['PurchasedAt']),
      expiredAt: parseNullableDate(json['expiredAt'] ?? json['ExpiredAt']),
      packagePrivileges:
          rawPrivileges
              ?.map((e) => e?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
    );
  }

  ReaderPurchaseEntity toEntity() {
    return ReaderPurchaseEntity(
      purchaseId: purchaseId,
      packageId: packageId,
      packageTitle: packageTitle,
      packagePrice: packagePrice,
      packageDurationDays: packageDurationDays,
      purchasedAt: purchasedAt,
      expiredAt: expiredAt,
      packagePrivileges: packagePrivileges,
    );
  }
}
