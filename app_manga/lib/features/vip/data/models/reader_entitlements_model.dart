import '../../domain/entities/reader_entitlements_entity.dart';
import '../../../../core/network/json_list_parser.dart';
import 'reader_purchase_model.dart';

class ReaderEntitlementsModel {
  final bool hasActivePackage;
  final bool canReadPremium;
  final DateTime? premiumAccessExpiredAt;
  final Map<String, String> features;
  final List<ReaderPurchaseModel> activePackages;

  const ReaderEntitlementsModel({
    required this.hasActivePackage,
    required this.canReadPremium,
    required this.premiumAccessExpiredAt,
    required this.features,
    required this.activePackages,
  });

  factory ReaderEntitlementsModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseNullableDate(dynamic value) {
      final raw = value?.toString();
      if (raw == null || raw.isEmpty) {
        return null;
      }

      return DateTime.tryParse(raw)?.toLocal();
    }

    final rawFeatures = json['features'] ?? json['Features'];
    final rawPackages = JsonListParser.extractList(
      json['activePackages'] ?? json['ActivePackages'],
    );

    return ReaderEntitlementsModel(
      hasActivePackage:
          json['hasActivePackage'] ?? json['HasActivePackage'] ?? false,
      canReadPremium: json['canReadPremium'] ?? json['CanReadPremium'] ?? false,
      premiumAccessExpiredAt: parseNullableDate(
        json['premiumAccessExpiredAt'] ?? json['PremiumAccessExpiredAt'],
      ),
      features: rawFeatures is Map
          ? rawFeatures.entries
                .where((entry) => !entry.key.toString().startsWith(r'$'))
                .fold<Map<String, String>>({}, (result, entry) {
                  result[entry.key.toString()] = entry.value?.toString() ?? '';
                  return result;
                })
          : const {},
      activePackages: rawPackages
          .whereType<Map<String, dynamic>>()
          .map(ReaderPurchaseModel.fromJson)
          .toList(),
    );
  }

  ReaderEntitlementsEntity toEntity() {
    return ReaderEntitlementsEntity(
      hasActivePackage: hasActivePackage,
      canReadPremium: canReadPremium,
      premiumAccessExpiredAt: premiumAccessExpiredAt,
      features: features,
      activePackages: activePackages.map((e) => e.toEntity()).toList(),
    );
  }
}
