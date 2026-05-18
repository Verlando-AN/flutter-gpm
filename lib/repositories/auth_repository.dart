import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/customer_model.dart';
import '../models/teknisi_model.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final token = response.data['access_token'];
      final userObj = response.data['user'];

      final int roleId = userObj['role_id'] ?? 0;

      String role = 'customer';

      if (roleId == 2) {
        role = 'teknisi';
      }

      await _apiClient.secureStorage.write(
        key: 'auth_token',
        value: token,
      );

      await _apiClient.secureStorage.write(
        key: 'user_role',
        value: role,
      );

      if (role == 'teknisi') {
        final user = TeknisiModel.fromJson(userObj);

        return {
          'role': role,
          'user': user,
        };
      } else {
        final user = CustomerModel.fromJson(userObj);

        return {
          'role': role,
          'user': user,
        };
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;

        String errorMessage = 'Login failed';

        if (errorData is Map && errorData.containsKey('error')) {
          errorMessage = errorData['error'].toString();
        }

        throw Exception(errorMessage);
      } else {
        throw Exception('Network error. Please try again.');
      }
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/logout');
    } catch (e) {}

    await _apiClient.secureStorage.delete(key: 'auth_token');
    await _apiClient.secureStorage.delete(key: 'user_role');
  }

  Future<String?> getToken() async {
    return await _apiClient.secureStorage.read(key: 'auth_token');
  }

  Future<String?> getRole() async {
    return await _apiClient.secureStorage.read(key: 'user_role');
  }
}