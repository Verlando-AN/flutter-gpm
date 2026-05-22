import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/activity_log_model.dart';

class ActivityLogRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<ActivityLogModel>> getLogs({String? name, String? date}) async {
    try {
      final response = await _apiClient.dio.get(
        '/activity-logs',
        queryParameters: {
          if (name != null && name.isNotEmpty) 'name': name,
          if (date != null && date.isNotEmpty) 'date': date,
        },
      );

      print('LOG RESPONSE => ${response.data}');

      final data = response.data;

      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Gagal mengambil activity log');
      }

      final List logs = data['data']['data'] ?? [];

      return logs
          .map<ActivityLogModel>((json) => ActivityLogModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      print('GET LOG ERROR => ${e.response?.data}');

      throw Exception(
        e.response?.data['message'] ?? 'Gagal mengambil activity log',
      );
    } catch (e) {
      print('GET LOG ERROR => $e');
      rethrow;
    }
  }
}
