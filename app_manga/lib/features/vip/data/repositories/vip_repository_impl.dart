import '../../domain/entities/package_plan_entity.dart';
import '../../domain/entities/reader_entitlements_entity.dart';
import '../../domain/entities/reader_purchase_entity.dart';
import '../../domain/repositories/vip_repository.dart';
import '../datasources/vip_remote_data_source.dart';

class VipRepositoryImpl implements VipRepository {
  final VipRemoteDataSource remoteDataSource;

  VipRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<PackagePlanEntity>> getAllPackages() async {
    final items = await remoteDataSource.getAllPackages();
    return items.map((e) => e.toEntity()).toList();
  }

  @override
  Future<ReaderEntitlementsEntity> getMyEntitlements(String token) async {
    final item = await remoteDataSource.getMyEntitlements(token);
    return item.toEntity();
  }

  @override
  Future<ReaderPurchaseEntity> purchasePackage({
    required String token,
    required int packageId,
  }) async {
    final item = await remoteDataSource.purchasePackage(
      token: token,
      packageId: packageId,
    );

    return item.toEntity();
  }
}
