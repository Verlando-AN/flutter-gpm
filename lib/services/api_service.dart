import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/pagination_meta.dart';
import '../models/ticket_list_response.dart';
import '../models/ticket_model.dart';

class ApiService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> _safeGet(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _client.dio.get(path, queryParameters: query);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return Map<String, dynamic>.from(response.data);
        }

        return {'data': response.data};
      }

      throw Exception('Server error. Status: ${response.statusCode}');
    } on DioException catch (e) {
      final responseData = e.response?.data;

      String message = 'Gagal memuat data';

      if (responseData is Map<String, dynamic>) {
        message =
            responseData['message']?.toString() ??
            responseData['error']?.toString() ??
            message;
      } else if (e.message != null) {
        message = e.message!;
      }

      throw Exception(message);
    }
  }

  Future<TicketListResponse> fetchTickets({
    String? search,
    String? status,
    String? priority,
    int page = 1,
    int perPage = 15,
  }) async {
    final query = <String, dynamic>{'page': page, 'per_page': perPage};

    if (search != null && search.isNotEmpty) {
      query['search'] = search;
    }

    if (status != null &&
        status.isNotEmpty &&
        status.toLowerCase() != 'semua') {
      query['status'] = status;
    }

    if (priority != null &&
        priority.isNotEmpty &&
        priority.toLowerCase() != 'semua') {
      query['priority'] = priority;
    }

    print('REQUEST QUERY => $query');

    final json = await _safeGet('/tickets', query: query);

    print('RAW RESPONSE => $json');

    final responseData = json['data'] as Map<String, dynamic>? ?? {};

    final List<dynamic> ticketJson =
        responseData['data'] as List<dynamic>? ?? [];

    print('TOTAL JSON TICKETS => ${ticketJson.length}');

    final tickets = ticketJson
        .map((item) => TicketModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    final meta = PaginationMeta(
      currentPage: responseData['current_page'] ?? 1,
      lastPage: responseData['last_page'] ?? 1,
      total: responseData['total'] ?? tickets.length,
      perPage: responseData['per_page'] ?? perPage,
    );

    return TicketListResponse(tickets: tickets, meta: meta);
  }

  Future<TicketModel> fetchTicketById(int id) async {
    final json = await _safeGet('/tickets/$id');

    final data = json['data'] as Map<String, dynamic>? ?? {};

    return TicketModel.fromJson(data);
  }
}
