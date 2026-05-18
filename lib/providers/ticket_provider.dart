import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/ticket_repository.dart';
import '../models/ticket_model.dart';

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepository();
});

final ticketsProvider = FutureProvider<List<TicketModel>>((ref) async {
  return ref.watch(ticketRepositoryProvider).getTickets();
});

final ticketDetailProvider = FutureProvider.family<TicketModel, int>((ref, id) async {
  return ref.watch(ticketRepositoryProvider).getTicketDetail(id);
});
