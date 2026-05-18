import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/ticket_model.dart';

class TicketRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<TicketModel>> getTickets() async {
    try {
      final response = await _apiClient.dio.get('/tickets');
      final List data = response.data['data'] ?? response.data;
      return data.map((json) => TicketModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load tickets');
    }
  }

  Future<TicketModel> getTicketDetail(int id) async {
    try {
      final response = await _apiClient.dio.get('/tickets/$id');
      return TicketModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load ticket detail');
    }
  }

  Future<void> updateTicketStatus(int id, String status) async {
    try {
      await _apiClient.dio.put('/tickets/$id', data: {'status': status});
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update ticket status');
    }
  }

  Future<void> addTicketNote(int id, String note) async {
    try {
      // Assuming endpoint for adding notes exist
      await _apiClient.dio.post('/tickets/$id/notes', data: {'note': note});
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to add note');
    }
  }
}
