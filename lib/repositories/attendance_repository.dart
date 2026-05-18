import 'package:dio/dio.dart';
import '../core/network/api_client.dart';

class AttendanceRepository {
  final ApiClient _apiClient = ApiClient();

  Future<void> submitAttendance({
    required double lat,
    required double lng,
    required String type, // 'check_in' or 'check_out'
  }) async {
    try {
      await _apiClient.dio.post('/attendance', data: {
        'latitude': lat,
        'longitude': lng,
        'type': type,
      });
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal mengirim absensi');
    }
  }
}
