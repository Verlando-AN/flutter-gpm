import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/ticket_provider.dart';
import '../../models/ticket_model.dart';
import '../../widgets/ticket_shimmer.dart';

class TicketListScreen extends ConsumerStatefulWidget {
  const TicketListScreen({super.key});

  @override
  ConsumerState<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends ConsumerState<TicketListScreen> {
  String selectedFilter = 'Semua';
  final List<String> filters = ['Semua', 'Pending', 'Proses', 'Selesai'];

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(ticketsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tiket Keluhan'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(ticketsProvider);
          try {
            await ref.read(ticketsProvider.future);
          } catch (_) {}
        },
        child: Column(
          children: [
            _buildSearchSection(),
            _buildFilterChips(),
            Expanded(
              child: ticketsAsync.when(
                data: (tickets) {
                  final filteredTickets = selectedFilter == 'Semua' 
                    ? tickets 
                    : tickets.where((t) => t.status.toLowerCase() == selectedFilter.toLowerCase()).toList();
                  
                  if (filteredTickets.isEmpty) {
                    return ListView( // Wrap in ListView to allow pull to refresh even when empty
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('Tidak ada tiket ditemukan')),
                      ]
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: filteredTickets.length,
                    itemBuilder: (context, index) {
                      return _buildTicketCard(filteredTickets[index]);
                    },
                  );
                },
                loading: () => const TicketListShimmer(),
                error: (err, stack) => ListView( // Wrap in ListView to allow pull to refresh on error
                  children: [
                    const SizedBox(height: 100),
                    Center(child: Text('Error: $err')),
                  ]
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari tiket atau pelanggan...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          fillColor: AppColors.surfaceDark,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final isSelected = selectedFilter == filters[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(filters[index]),
              selected: isSelected,
              onSelected: (val) => setState(() => selectedFilter = filters[index]),
              backgroundColor: AppColors.surfaceDark,
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTicketCard(TicketModel ticket) {
    Color statusColor = Colors.orange;
    if (ticket.status.toLowerCase() == 'pending') statusColor = Colors.red;
    if (ticket.status.toLowerCase() == 'selesai') statusColor = Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ticket.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                ticket.createdAt,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ticket.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Pelanggan: ${ticket.customerName}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Klik detail untuk lokasi',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () => context.push('/teknisi/tickets/${ticket.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Detail'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
