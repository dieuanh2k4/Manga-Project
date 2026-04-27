import 'reader_purchase_entity.dart';

class ReaderEntitlementsEntity {
  final bool hasActivePackage;
  final bool canReadPremium;
  final DateTime? premiumAccessExpiredAt;
  final Map<String, String> features;
  final List<ReaderPurchaseEntity> activePackages;

  const ReaderEntitlementsEntity({
    required this.hasActivePackage,
    required this.canReadPremium,
    this.premiumAccessExpiredAt,
    this.features = const {},
    this.activePackages = const [],
  });
}
