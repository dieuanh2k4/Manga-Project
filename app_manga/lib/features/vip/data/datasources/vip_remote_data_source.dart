import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/network/json_list_parser.dart';
import '../models/package_plan_model.dart';
import '../models/reader_entitlements_model.dart';
import '../models/reader_purchase_model.dart';

class VipRemoteDataSource {
  Future<List<PackagePlanModel>> getAllPackages() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/Package/get-all-package'),
    );

    final body = response.body.isEmpty ? '{}' : response.body;
    final data = jsonDecode(body);

    if (response.statusCode != 200) {
      throw Exception(
        _extractMessage(data, fallback: 'Khong tai duoc danh sach goi'),
      );
    }

    final listData = JsonListParser.extractList(data);

    return listData
        .whereType<Map<String, dynamic>>()
        .map(PackagePlanModel.fromJson)
        .where((item) => item.id > 0 && item.title.isNotEmpty)
        .toList();
  }

  Future<ReaderEntitlementsModel> getMyEntitlements(String token) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/Package/my-entitlements'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final body = response.body.isEmpty ? '{}' : response.body;
    final data = jsonDecode(body);

    if (response.statusCode != 200) {
      throw Exception(
        _extractMessage(data, fallback: 'Khong tai duoc quyen VIP hien tai'),
      );
    }

    final payload = _extractDataMap(data);
    return ReaderEntitlementsModel.fromJson(payload);
  }

  Future<ReaderPurchaseModel> purchasePackage({
    required String token,
    required int packageId,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/Package/purchase/$packageId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final body = response.body.isEmpty ? '{}' : response.body;
    final data = jsonDecode(body);

    if (response.statusCode != 200) {
      throw Exception(_extractMessage(data, fallback: 'Mua goi that bai'));
    }

    final wrapper = _extractDataMap(data);
    final purchaseRaw = wrapper['purchase'];

    if (purchaseRaw is! Map<String, dynamic>) {
      throw Exception('Phan hoi mua goi khong hop le');
    }

    return ReaderPurchaseModel.fromJson(purchaseRaw);
  }

  Map<String, dynamic> _extractDataMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final payload = data['data'];
      if (payload is Map<String, dynamic>) {
        return payload;
      }

      return data;
    }

    return const {};
  }

  String _extractMessage(dynamic data, {required String fallback}) {
    if (data is Map<String, dynamic>) {
      final value = data['message'];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }
}
