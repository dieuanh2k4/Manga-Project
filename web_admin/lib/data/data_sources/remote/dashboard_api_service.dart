import 'package:dio/dio.dart';
import 'package:web_admin/core/constants/constants.dart';
import 'package:web_admin/core/utils/auth_token_storage.dart';
import 'package:web_admin/data/models/dashboard_dto.dart';

class DashboardApiService {
  final Dio _dio;
  final AuthTokenStorage _authTokenStorage;

  DashboardApiService(this._dio, this._authTokenStorage);

  Future<Map<String, dynamic>> _buildAuthHeaders() async {
    final String? token = await _authTokenStorage.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      return <String, dynamic>{};
    }
    return <String, dynamic>{
      'Authorization': _authTokenStorage.formatBearerValue(token),
    };
  }

  Future<DashboardModel> getDashboardStats() async {
    final Map<String, dynamic> headers = await _buildAuthHeaders();

    final response = await _dio.get<dynamic>(
      '${newAPIBaseURL}Dashboard/get-stats',
      options: Options(headers: headers),
    );

    if (response.data == null) {
      throw Exception('Dữ liệu rỗng từ máy chủ');
    }

    final Map<String, dynamic> dataMap = Map<String, dynamic>.from(response.data as Map);
    return DashboardModel.fromJson(dataMap);
  }
}
