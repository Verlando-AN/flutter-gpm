import 'package:dio/dio.dart';

import '../core/network/api_client.dart';

class AttendanceRepository {
  final ApiClient _apiClient = ApiClient();

  Future<void> submitAttendance({
    required double lat,
    required double lng,
    required String type, // 'check_in' or 'check_out'
  }) async {
    final endpoint = type == 'check_in'
        ? '/teknisi/absensi/check-in'
        : '/teknisi/absensi/check-out';

    final data = type == 'check_in'
        ? {
            'status': 'hadir',
            'latitude': lat,
            'longitude': lng,
            'address': '',
            'note': '',
          }
        : {'latitude': lat, 'longitude': lng, 'address': ''};

    try {
      await _apiClient.dio.post(
        endpoint,
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString() ??
                'Gagal mengirim absensi')
          : 'Gagal mengirim absensi';
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> fetchAttendanceReport({
    int? userId,
    required int month,
    required int year,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/teknisi/laporan',
        queryParameters: {
          if (userId != null) 'user_id': userId,
          'month': month,
          'year': year,
        },
      );

      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData['success'] == true) {
        return Map<String, dynamic>.from(responseData['data'] ?? {});
      }

      throw Exception(
        responseData is Map<String, dynamic>
            ? responseData['message']?.toString() ?? 'Gagal mengambil laporan'
            : 'Gagal mengambil laporan',
      );
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString() ??
                'Gagal mengambil laporan')
          : 'Gagal mengambil laporan';
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> fetchTodayAttendance({int? userId}) async {
    try {
      final response = await _apiClient.dio.get(
        '/teknisi/absensi',
        queryParameters: {if (userId != null) 'user_id': userId},
      );

      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData['success'] == true) {
        return Map<String, dynamic>.from(responseData['data'] ?? {});
      }

      throw Exception(
        responseData is Map<String, dynamic>
            ? responseData['message']?.toString() ??
                  'Gagal mengambil status hari ini'
            : 'Gagal mengambil status hari ini',
      );
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString() ??
                'Gagal mengambil status hari ini')
          : 'Gagal mengambil status hari ini';
      throw Exception(message);
    }
  }
}
