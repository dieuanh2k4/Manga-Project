import '../entities/package_plan_entity.dart';
import '../repositories/vip_repository.dart';

class GetAllPackagesUseCase {
  final VipRepository repository;

  GetAllPackagesUseCase(this.repository);

  Future<List<PackagePlanEntity>> call() {
    return repository.getAllPackages();
  }
}
