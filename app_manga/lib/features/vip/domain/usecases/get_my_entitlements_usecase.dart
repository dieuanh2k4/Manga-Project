import '../entities/reader_entitlements_entity.dart';
import '../repositories/vip_repository.dart';

class GetMyEntitlementsUseCase {
  final VipRepository repository;

  GetMyEntitlementsUseCase(this.repository);

  Future<ReaderEntitlementsEntity> call(String token) {
    return repository.getMyEntitlements(token);
  }
}
