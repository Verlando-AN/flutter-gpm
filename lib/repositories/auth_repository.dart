import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../models/customer_model.dart';
import '../models/teknisi_model.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password cannot be empty');
      }

      final response = await _apiClient.dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode != 200) {
        throw Exception('Login failed with status code ${response.statusCode}');
      }

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] != true) {
        throw Exception(
          'Login failed: ${responseData['message'] ?? 'Unknown error'}',
        );
      }

      final token = responseData['access_token'];
      final userObj = responseData['user'];

      final int roleId = userObj['role_id'] ?? 0;

      String role = 'customer';

      if (roleId == 2) {
        role = 'teknisi';
      }

      if (token == null || token.toString().isEmpty) {
        throw Exception('No access token received from server');
      }

      final tokenString = token.toString();
      await _apiClient.saveToken(tokenString);
      print('LOGIN TOKEN SAVED => $tokenString');

      await _apiClient.saveRole(role);
      print('LOGIN ROLE SAVED => $role');

      if (role == 'teknisi') {
        final user = TeknisiModel.fromJson(userObj);
        await _apiClient.saveUser(user.toJson());
        print('LOGIN USER SAVED => ${user.name}');
        return {'role': role, 'user': user};
      } else {
        final user = CustomerModel.fromJson(userObj);
        await _apiClient.saveUser(user.toJson());
        print('LOGIN USER SAVED => ${user.name}');
        return {'role': role, 'user': user};
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
      final response = await _apiClient.dio.post('/logout');

      // Validate logout response
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          print('LOGOUT SUCCESS => ${data['message']}');
        }
      }
    } on DioException catch (e) {
      // Log error but still clear auth data
      print('LOGOUT API ERROR => ${e.message}');
      if (e.response != null) {
        print('LOGOUT ERROR DATA => ${e.response?.data}');
      }
    } catch (e) {
      print('LOGOUT ERROR => $e');
    } finally {
      // Always clear auth data regardless of API response
      await _apiClient.clearAuthData();
    }
  }

  Future<String?> getToken() async {
    return await _apiClient.getToken();
  }

  Future<String?> getRole() async {
    return await _apiClient.getRole();
  }

  Future<Map<String, dynamic>?> getStoredUser() async {
    return await _apiClient.getUser();
  }

  Future<Map<String, dynamic>?> getUser() async {
    return await getStoredUser();
  }
}
