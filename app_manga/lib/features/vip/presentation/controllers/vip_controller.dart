import 'package:flutter/foundation.dart';

import '../../domain/entities/package_plan_entity.dart';
import '../../domain/entities/reader_entitlements_entity.dart';
import '../../domain/usecases/get_all_packages_usecase.dart';
import '../../domain/usecases/get_my_entitlements_usecase.dart';
import '../../domain/usecases/purchase_package_usecase.dart';

class VipController extends ChangeNotifier {
  final GetAllPackagesUseCase getAllPackagesUseCase;
  final GetMyEntitlementsUseCase getMyEntitlementsUseCase;
  final PurchasePackageUseCase purchasePackageUseCase;

  VipController({
    required this.getAllPackagesUseCase,
    required this.getMyEntitlementsUseCase,
    required this.purchasePackageUseCase,
  });

  List<PackagePlanEntity> packages = const [];
  ReaderEntitlementsEntity? entitlements;

  bool isLoading = false;
  bool isRefreshingEntitlements = false;
  int? purchasingPackageId;
  String? errorMessage;
  String? purchaseMessage;

  String _token = '';

  bool get isPurchasing => purchasingPackageId != null;

  Future<void> initialize({required String token}) async {
    _token = token;
    isLoading = true;
    errorMessage = null;
    purchaseMessage = null;
    notifyListeners();

    try {
      packages = await getAllPackagesUseCase();
      if (_token.isNotEmpty) {
        entitlements = await getMyEntitlementsUseCase(_token);
      }
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshEntitlements() async {
    if (_token.isEmpty) {
      return;
    }

    isRefreshingEntitlements = true;
    errorMessage = null;
    notifyListeners();

    try {
      entitlements = await getMyEntitlementsUseCase(_token);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isRefreshingEntitlements = false;
      notifyListeners();
    }
  }

  bool isPackageActive(int packageId) {
    final activePackages = entitlements?.activePackages ?? const [];
    return activePackages.any((item) => item.packageId == packageId);
  }

  Future<bool> purchase(int packageId) async {
    if (_token.isEmpty) {
      errorMessage = 'Ban can dang nhap de mua goi';
      notifyListeners();
      return false;
    }

    if (isPackageActive(packageId)) {
      errorMessage = 'Goi nay dang con hieu luc';
      notifyListeners();
      return false;
    }

    purchasingPackageId = packageId;
    errorMessage = null;
    purchaseMessage = null;
    notifyListeners();

    try {
      await purchasePackageUseCase(token: _token, packageId: packageId);
      entitlements = await getMyEntitlementsUseCase(_token);
      purchaseMessage = 'Mua goi thanh cong';
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      purchasingPackageId = null;
      notifyListeners();
    }
  }
}
