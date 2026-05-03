import '../entities/package_plan_entity.dart';
import '../entities/reader_entitlements_entity.dart';
import '../entities/reader_purchase_entity.dart';

abstract class VipRepository {
  Future<List<PackagePlanEntity>> getAllPackages();
  Future<ReaderEntitlementsEntity> getMyEntitlements(String token);
  Future<ReaderPurchaseEntity> purchasePackage({
    required String token,
    required int packageId,
  });
}
