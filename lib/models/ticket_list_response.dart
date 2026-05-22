import 'pagination_meta.dart';
import 'ticket_model.dart';

class TicketListResponse {
  final List<TicketModel> tickets;
  final PaginationMeta meta;

  TicketListResponse({required this.tickets, required this.meta});
}
