import '../models/ticket_list_response.dart';
import '../models/ticket_model.dart';
import '../services/api_service.dart';

class TicketRepository {
  final ApiService _apiService = ApiService();

  Future<TicketListResponse> getTickets({
    String? search,
    String? status,
    String? priority,
    int page = 1,
    int perPage = 15,
  }) {
    return _apiService.fetchTickets(
      search: search,
      status: status,
      priority: priority,
      page: page,
      perPage: perPage,
    );
  }

  Future<TicketModel> getTicketDetail(int id) {
    return _apiService.fetchTicketById(id);
  }
}
