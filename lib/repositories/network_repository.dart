import 'package:dio/dio.dart';
import '../core/network/api_client.dart';

class NetworkRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getOdpLocations() async {
    try {
      final response = await _apiClient.dio.get('/network/olt'); // Using OLT as placeholder for ODP source if ODP specific is missing
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal mengambil data ODP');
    }
  }

  Future<List<dynamic>> getCustomerLocations() async {
    try {
      final response = await _apiClient.dio.get('/customers');
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal mengambil data pelanggan');
    }
  }
}
