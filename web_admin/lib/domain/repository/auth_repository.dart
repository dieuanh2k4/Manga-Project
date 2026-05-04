import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/domain/entities/auth.dart';

abstract class AuthRepository {
  Future<DataState<AuthEntity>> login(String userName, String password);
}
