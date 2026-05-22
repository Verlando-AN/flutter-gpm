import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ticket_model.dart';
import '../repositories/ticket_repository.dart';

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepository();
});

final ticketsProvider = FutureProvider<List<TicketModel>>((ref) async {
  final response = await ref
      .watch(ticketRepositoryProvider)
      .getTickets(page: 1, perPage: 100);

  return response.tickets;
});

final ticketListProvider =
    StateNotifierProvider<TicketListController, TicketListState>((ref) {
      return TicketListController(ref);
    });

final ticketDetailProvider = FutureProvider.family<TicketModel, int>((
  ref,
  id,
) async {
  return ref.watch(ticketRepositoryProvider).getTicketDetail(id);
});

@immutable
class TicketListState {
  final List<TicketModel> tickets;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool hasMore;
  final int page;
  final String search;
  final String status;
  final String priority;
  final String? error;

  const TicketListState({
    this.tickets = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.hasMore = true,
    this.page = 1,
    this.search = '',
    this.status = 'Semua',
    this.priority = 'Semua',
    this.error,
  });

  TicketListState copyWith({
    List<TicketModel>? tickets,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? hasMore,
    int? page,
    String? search,
    String? status,
    String? priority,
    String? error,
  }) {
    return TicketListState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      search: search ?? this.search,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      error: error,
    );
  }
}

class TicketListController extends StateNotifier<TicketListState> {
  final Ref _ref;

  TicketListController(this._ref) : super(const TicketListState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      page: 1,
      tickets: [],
      hasMore: true,
    );

    await _loadPage(page: 1, append: false);
  }

  Future<void> refresh() async {
    state = state.copyWith(
      isRefreshing: true,
      error: null,
      page: 1,
      hasMore: true,
    );

    await _loadPage(page: 1, append: false);
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }

    await _loadPage(page: state.page + 1, append: true);
  }

  Future<void> updateSearch(String value) async {
    state = state.copyWith(
      search: value,
      page: 1,
      tickets: [],
      hasMore: true,
      error: null,
    );

    await _loadPage(page: 1, append: false);
  }

  Future<void> updateStatus(String value) async {
    state = state.copyWith(
      status: value,
      page: 1,
      tickets: [],
      hasMore: true,
      error: null,
    );

    await _loadPage(page: 1, append: false);
  }

  Future<void> updatePriority(String value) async {
    state = state.copyWith(
      priority: value,
      page: 1,
      tickets: [],
      hasMore: true,
      error: null,
    );

    await _loadPage(page: 1, append: false);
  }

  Future<void> _loadPage({required int page, required bool append}) async {
    try {
      state = state.copyWith(
        isLoading: !append,
        isLoadingMore: append,
        error: null,
      );

      final search = state.search.trim().isEmpty ? null : state.search.trim();

      final status = state.status.toLowerCase() == 'semua'
          ? null
          : state.status;

      final priority = state.priority.toLowerCase() == 'semua'
          ? null
          : state.priority;

      debugPrint('==========================');
      debugPrint('LOAD TICKETS');
      debugPrint('PAGE => $page');
      debugPrint('SEARCH => $search');
      debugPrint('STATUS => $status');
      debugPrint('PRIORITY => $priority');
      debugPrint('==========================');

      final response = await _ref
          .read(ticketRepositoryProvider)
          .getTickets(
            search: search,
            status: status,
            priority: priority,
            page: page,
            perPage: 15,
          );

      debugPrint('TOTAL RESPONSE => ${response.tickets.length}');

      final tickets = append
          ? [...state.tickets, ...response.tickets]
          : response.tickets;

      debugPrint('TOTAL STATE => ${tickets.length}');

      state = state.copyWith(
        tickets: tickets,
        page: response.meta.currentPage,
        hasMore: response.meta.currentPage < response.meta.lastPage,
        isLoading: false,
        isLoadingMore: false,
        isRefreshing: false,
        error: null,
      );
    } catch (error, stackTrace) {
      debugPrint('ERROR LOAD TICKETS => $error');

      debugPrintStack(stackTrace: stackTrace);

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        isRefreshing: false,
        error: error.toString(),
      );
    }
  }
}
