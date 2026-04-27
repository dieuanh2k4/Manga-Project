class ReaderPurchaseEntity {
  final int purchaseId;
  final int packageId;
  final String packageTitle;
  final int packagePrice;
  final int packageDurationDays;
  final DateTime purchasedAt;
  final DateTime? expiredAt;
  final List<String> packagePrivileges;

  const ReaderPurchaseEntity({
    required this.purchaseId,
    required this.packageId,
    required this.packageTitle,
    required this.packagePrice,
    required this.packageDurationDays,
    required this.purchasedAt,
    required this.expiredAt,
    this.packagePrivileges = const [],
  });
}
