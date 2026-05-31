import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'http://192.168.43.126:8000/api';

  static const String _tokenKey = 'auth_token';
  static const String _userRoleKey = 'user_role';
  static const String _userKey = 'auth_user';

  final Dio dio;

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  ApiClient()
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await _prefs;
          final token = prefs.getString(_tokenKey);

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          debugPrint('REQUEST => ${options.method} ${options.uri}');

          debugPrint('DATA => ${options.data}');

          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('RESPONSE[${response.statusCode}] => ${response.data}');

          handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint('ERROR => ${e.message}');
          debugPrint('ERROR DATA => ${e.response?.data}');

          handler.next(e);
        },
      ),
    );
  }

  Future<void> saveToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_tokenKey, token);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await _prefs;
    await prefs.setString(_userKey, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveRole(String role) async {
    final prefs = await _prefs;
    await prefs.setString(_userRoleKey, role);
  }

  Future<String?> getToken() async {
    final prefs = await _prefs;
    return prefs.getString(_tokenKey);
  }

  Future<String?> getRole() async {
    final prefs = await _prefs;
    return prefs.getString(_userRoleKey);
  }

  Future<void> clearAuthData() async {
    final prefs = await _prefs;

    await prefs.remove(_tokenKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userKey);
  }
}
