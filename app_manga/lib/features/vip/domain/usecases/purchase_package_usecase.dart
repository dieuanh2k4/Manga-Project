import '../entities/reader_purchase_entity.dart';
import '../repositories/vip_repository.dart';

class PurchasePackageUseCase {
  final VipRepository repository;

  PurchasePackageUseCase(this.repository);

  Future<ReaderPurchaseEntity> call({
    required String token,
    required int packageId,
  }) {
    return repository.purchasePackage(token: token, packageId: packageId);
  }
}
