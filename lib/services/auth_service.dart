import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.43.126:8000/api',
      headers: {'Accept': 'application/json'},
    ),
  );

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  Future<void> logout() async {
    try {
      final token = await storage.read(key: 'token');

      await dio.post(
        '/logout',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      print('LOGOUT ERROR => $e');
    } finally {
      await storage.delete(key: 'token');
      await storage.delete(key: 'user');
    }
  }
}
