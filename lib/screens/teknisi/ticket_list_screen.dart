import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../models/ticket_model.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/navigation/teknisi_bottom_nav.dart';
import '../../widgets/ticket_shimmer.dart';
import '../teknisi/ticket_detail_page.dart';

// ─── STATUS & PRIORITY CONFIG ────────────────────────────────────────────────

class _StatusConfig {
  final Color color;
  final Color softColor;
  final IconData icon;
  final String label;
  const _StatusConfig({
    required this.color,
    required this.softColor,
    required this.icon,
    required this.label,
  });
}

class _PriorityConfig {
  final Color color;
  final Color softColor;
  final IconData icon;
  final String label;
  const _PriorityConfig({
    required this.color,
    required this.softColor,
    required this.icon,
    required this.label,
  });
}

// ─── DETAIL ITEM ─────────────────────────────────────────────────────────────

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

// ─── SCREEN ───────────────────────────────────────────────────────────────────

class TicketListScreen extends ConsumerStatefulWidget {
  const TicketListScreen({super.key});

  @override
  ConsumerState<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends ConsumerState<TicketListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  String _selectedStatus = 'Semua';
  String _selectedPriority = 'Semua';

  final List<String> _statuses = [
    'open',
    'assigned',
    'in_progress',
    'resolved',
  ];
  final List<String> _priorities = ['Semua', 'low', 'medium', 'high'];

  // ─── CONFIG HELPERS ────────────────────────────────────────────────────────

  _StatusConfig _statusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return const _StatusConfig(
          color: Color(0xFFEF4444),
          softColor: Color(0xFFFEF2F2),
          icon: Icons.hourglass_top_rounded,
          label: 'assigned',
        );
      case 'in_progress':
        return const _StatusConfig(
          color: Color(0xFF0EA5E9),
          softColor: Color(0xFFF0F9FF),
          icon: Icons.autorenew_rounded,
          label: 'Proses',
        );
      case 'resolved':
        return const _StatusConfig(
          color: Color(0xFF10B981),
          softColor: Color(0xFFF0FDF9),
          icon: Icons.task_alt_rounded,
          label: 'Selesai',
        );
      default:
        return _StatusConfig(
          color: AppColors.primary,
          softColor: AppColors.primarySoft,
          icon: Icons.help_outline_rounded,
          label: status,
        );
    }
  }

  _PriorityConfig _priorityConfig(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const _PriorityConfig(
          color: Color(0xFFEF4444),
          softColor: Color(0xFFFEF2F2),
          icon: Icons.local_fire_department_rounded,
          label: 'High',
        );
      case 'medium':
        return const _PriorityConfig(
          color: Color(0xFFF59E0B),
          softColor: Color(0xFFFFFBEB),
          icon: Icons.remove_rounded,
          label: 'Medium',
        );
      case 'low':
        return const _PriorityConfig(
          color: Color(0xFF10B981),
          softColor: Color(0xFFF0FDF9),
          icon: Icons.keyboard_double_arrow_down_rounded,
          label: 'Low',
        );
      default:
        return _PriorityConfig(
          color: AppColors.textSecondary,
          softColor: AppColors.surface,
          icon: Icons.remove_rounded,
          label: priority,
        );
    }
  }

  // ─── LIFECYCLE ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref
          .read(ticketListProvider.notifier)
          .updateSearch(_searchController.text.trim());
    });
    setState(() {});
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 260) {
      ref.read(ticketListProvider.notifier).loadNextPage();
    }
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _selectedStatus = 'Semua';
      _selectedPriority = 'Semua';
    });
    ref.read(ticketListProvider.notifier).updateSearch('');
    ref.read(ticketListProvider.notifier).updateStatus('Semua');
    ref.read(ticketListProvider.notifier).updatePriority('Semua');
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ticketListProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        bottomNavigationBar: const TeknisiBottomNav(),
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
                onRefresh: () async {
                  await ref.read(ticketListProvider.notifier).refresh();
                },
                child: _buildBody(state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 12),

          // Title row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Daftar Tiket',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Cari, filter, dan lihat detail tiket',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildSearchField(),
          ),

          const SizedBox(height: 14),

          // Filter: Status
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 8),
            child: Text(
              'STATUS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary.withOpacity(0.6),
                letterSpacing: 0.9,
              ),
            ),
          ),
          SizedBox(
            height: 34,
            child: _buildFilterChips(_statuses, _selectedStatus, (v) {
              setState(() => _selectedStatus = v);
              ref.read(ticketListProvider.notifier).updateStatus(v);
            }, isStatus: true),
          ),

          const SizedBox(height: 12),

          // Filter: Prioritas
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 8),
            child: Text(
              'PRIORITAS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary.withOpacity(0.6),
                letterSpacing: 0.9,
              ),
            ),
          ),
          SizedBox(
            height: 34,
            child: _buildFilterChips(_priorities, _selectedPriority, (v) {
              setState(() => _selectedPriority = v);
              ref.read(ticketListProvider.notifier).updatePriority(v);
            }, isStatus: false),
          ),

          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.border.withOpacity(0.7)),
        ],
      ),
    );
  }

  // ─── SEARCH ────────────────────────────────────────────────────────────────

  Widget _buildSearchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary.withOpacity(0.6),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Cari tiket, pelanggan, ID...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                ref.read(ticketListProvider.notifier).updateSearch('');
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 14),
        ],
      ),
    );
  }

  // ─── FILTER CHIPS ──────────────────────────────────────────────────────────

  Widget _buildFilterChips(
    List<String> options,
    String selected,
    ValueChanged<String> onTap, {
    required bool isStatus,
  }) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: options.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final value = options[index];
        final isSelected = value == selected;
        final label = value[0].toUpperCase() + value.substring(1);

        // Chip color: for "Semua" use primary, otherwise use status/priority color
        Color chipColor = AppColors.primary;
        Color chipSoft = AppColors.primarySoft;
        if (value != 'Semua') {
          if (isStatus) {
            final sc = _statusConfig(value);
            chipColor = sc.color;
            chipSoft = sc.softColor;
          } else {
            final pc = _priorityConfig(value);
            chipColor = pc.color;
            chipSoft = pc.softColor;
          }
        }

        return GestureDetector(
          onTap: () => onTap(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? chipColor : AppColors.surface,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isSelected ? chipColor : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : (value == 'Semua' ? AppColors.textSecondary : chipColor),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── BODY ──────────────────────────────────────────────────────────────────

  Widget _buildBody(TicketListState state) {
    if (state.isLoading && state.tickets.isEmpty) {
      return const TicketListShimmer();
    }
    if (state.error != null && state.tickets.isEmpty) {
      return _buildError(state.error!);
    }
    if (state.tickets.isEmpty) {
      return _buildEmpty();
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
      itemCount: state.tickets.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.tickets.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }
        return _buildTicketCard(state.tickets[index]);
      },
    );
  }

  // ─── TICKET CARD ───────────────────────────────────────────────────────────

  Widget _buildTicketCard(TicketModel ticket) {
    final sc = _statusConfig(ticket.status);
    final pc = _priorityConfig(ticket.priority);
    final initial = ticket.customerName.isNotEmpty
        ? ticket.customerName.trim()[0].toUpperCase()
        : '?';

    return GestureDetector(
      onTap: () => _showTicketDetail(ticket),
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colored top bar
              Container(height: 3, color: sc.color),

              Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Ticket number + Status + Date
                    Row(
                      children: [
                        _cardBadge(
                          label: ticket.ticketNumber,
                          color: AppColors.primary,
                          softColor: AppColors.primarySoft,
                          icon: Icons.tag_rounded,
                        ),
                        const SizedBox(width: 6),
                        _cardBadge(
                          label: sc.label.toUpperCase(),
                          color: sc.color,
                          softColor: sc.softColor,
                          icon: sc.icon,
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Title
                    Text(
                      ticket.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 11),
                    Container(
                      height: 1,
                      color: AppColors.border.withOpacity(0.6),
                    ),
                    const SizedBox(height: 10),

                    // Row 2: Avatar + Customer info + Priority
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ticket.customerName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (ticket.contactWhatsapp.isNotEmpty)
                                Text(
                                  ticket.contactWhatsapp,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary.withOpacity(
                                      0.7,
                                    ),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Priority badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: pc.softColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(pc.icon, size: 11, color: pc.color),
                              const SizedBox(width: 4),
                              Text(
                                pc.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: pc.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardBadge({
    required String label,
    required Color color,
    required Color softColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ─── TICKET DETAIL MODAL ───────────────────────────────────────────────────

  void _showTicketDetail(TicketModel ticket) {
    final sc = _statusConfig(ticket.status);
    final pc = _priorityConfig(ticket.priority);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final bottomPad = MediaQuery.of(context).padding.bottom;
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF7F6F3),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: EdgeInsets.only(bottom: bottomPad + 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 6),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ),

                // Status header card
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: sc.softColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: sc.color.withOpacity(0.22)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: sc.color.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(sc.icon, color: sc.color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sc.label.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: sc.color,
                                  letterSpacing: 0.7,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ticket.ticketNumber,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: pc.softColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(pc.icon, size: 12, color: pc.color),
                              const SizedBox(width: 5),
                              Text(
                                pc.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: pc.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    ticket.title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4,
                      height: 1.3,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Pelanggan section
                _buildDetailSection('Informasi Pelanggan', [
                  _DetailItem(
                    icon: Icons.person_rounded,
                    label: 'Nama',
                    value: ticket.customerName,
                  ),
                  _DetailItem(
                    icon: Icons.chat_rounded,
                    label: 'WhatsApp',
                    value: ticket.contactWhatsapp.isNotEmpty
                        ? ticket.contactWhatsapp
                        : '-',
                  ),
                ]),

                const SizedBox(height: 10),

                // Tiket section
                _buildDetailSection('Info Tiket', [
                  _DetailItem(
                    icon: Icons.calendar_today_rounded,
                    label: 'Dibuat',
                    value: ticket.createdAt,
                  ),
                  _DetailItem(
                    icon: Icons.tag_rounded,
                    label: 'Nomor',
                    value: ticket.ticketNumber,
                  ),
                ]),

                // Description
                if (ticket.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.notes_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 7),
                              Text(
                                'Deskripsi',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          Text(
                            ticket.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TicketDetailPage(ticketId: ticket.id),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.open_in_new_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Lihat Detail Lengkap',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(String title, List<_DetailItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary.withOpacity(0.6),
                  letterSpacing: 0.7,
                ),
              ),
            ),
            Container(height: 1, color: AppColors.border.withOpacity(0.6)),
            ...items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        Icon(item.icon, size: 14, color: AppColors.primary),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 80,
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.value,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < items.length - 1)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.only(left: 14),
                      color: AppColors.border.withOpacity(0.5),
                    ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // ─── EMPTY ─────────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inbox_rounded,
                  color: AppColors.primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tidak ada tiket',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Coba ubah filter atau kata kunci pencarian',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 22),
              GestureDetector(
                onTap: _resetFilters,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Reset Filter',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── ERROR ─────────────────────────────────────────────────────────────────

  Widget _buildError(Object err) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: Color(0xFFEF4444),
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gagal memuat tiket',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tarik ke bawah untuk mencoba lagi',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
