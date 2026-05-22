import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isp_app/models/ticket_detail_model.dart';
import 'package:isp_app/repositories/auth_repository.dart';
import 'package:isp_app/services/ticket_service.dart';

// TeknisiBottomNav DIHAPUS dari halaman detail — halaman detail adalah
// sub-halaman (push), bukan tab utama, sehingga tidak perlu bottom nav.

class TicketDetailPage extends StatefulWidget {
  final int ticketId;
  const TicketDetailPage({super.key, required this.ticketId});

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  late Future<TicketDetailResponse> _future;

  static const _blue50 = Color(0xFFE6F1FB);
  static const _blue800 = Color(0xFF0C447C);
  static const _blue600 = Color(0xFF185FA5);
  static const _green50 = Color(0xFFEAF3DE);
  static const _green800 = Color(0xFF27500A);
  static const _green600 = Color(0xFF3B6D11);
  static const _amber50 = Color(0xFFFAEEDA);
  static const _amber800 = Color(0xFF633806);
  static const _amber600 = Color(0xFF854F0B);
  static const _purple50 = Color(0xFFEEEDFE);
  static const _purple600 = Color(0xFF534AB7);
  static const _gray50 = Color(0xFFF1EFE8);
  static const _gray600 = Color(0xFF5F5E5A);
  static const _red50 = Color(0xFFFCEBEB);
  static const _red800 = Color(0xFF791F1F);

  @override
  void initState() {
    super.initState();
    _future = TicketService.getTicketDetail(ticketId: widget.ticketId);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = TicketService.getTicketDetail(ticketId: widget.ticketId);
    });
  }

  String _fmt(DateTime dt) => DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);

  ({Color bg, Color text}) _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return (bg: _blue50, text: _blue800);
      case 'assigned':
      case 'in_progress':
        return (bg: _amber50, text: _amber800);
      case 'completed':
      case 'closed':
        return (bg: _green50, text: _green800);
      default:
        return (bg: _gray50, text: _gray600);
    }
  }

  ({Color bg, Color text}) _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'critical':
        return (bg: _red50, text: _red800);
      case 'medium':
        return (bg: _amber50, text: _amber800);
      default:
        return (bg: _gray50, text: _gray600);
    }
  }

  // ── Assign dialog ─────────────────────────────────────────────────────────
  Future<void> _showAssignDialog(int ticketId) async {
    if (!mounted) return;

    final authRepository = AuthRepository();
    final userData = await authRepository.getUser();
    if (!mounted) return;

    final int userId = userData?['id'] ?? 0;

    // Simpan startedAt di variabel lokal yang bisa diubah dari callback sheet
    DateTime? startedAt;
    final notesController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Gunakan useRootNavigator: true agar sheet tidak terikat
      // pada Navigator sub-tree yang mungkin tidak punya GoRouter
      useRootNavigator: true,
      builder: (_) => _AssignSheet(
        userId: userId,
        notesController: notesController,
        initialStartedAt: startedAt,
        onStartedAtChanged: (dt) => startedAt = dt,
        onSubmit: (sheetContext) async {
          if (startedAt == null) {
            ScaffoldMessenger.of(sheetContext).showSnackBar(
              const SnackBar(content: Text('Silakan pilih waktu pengerjaan')),
            );
            return;
          }
          // Tutup sheet sebelum async agar context tidak stale
          Navigator.of(sheetContext, rootNavigator: true).pop();

          try {
            await TicketService.assignTicket(
              ticketId: ticketId,
              userId: userId,
              status: 'assigned',
              notes: notesController.text,
              acceptedAt: _fmt(DateTime.now()),
              startedAt: _fmt(startedAt!),
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ticket berhasil di-assign')),
            );
            await _refresh();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(e.toString())));
          }
        },
      ),
    );

    notesController.dispose();
  }

  // ── Complete dialog ───────────────────────────────────────────────────────
  Future<void> _showCompleteDialog(int ticketId) async {
    if (!mounted) return;

    final notesController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => _CompleteSheet(
        notesController: notesController,
        onSubmit: (sheetContext) async {
          Navigator.of(sheetContext, rootNavigator: true).pop();

          try {
            await TicketService.completeTicket(
              ticketId: ticketId,
              notes: notesController.text,
              completedAt: _fmt(DateTime.now()),
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ticket berhasil diselesaikan')),
            );
            await _refresh();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(e.toString())));
          }
        },
      ),
    );

    notesController.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      // ❌ bottomNavigationBar: const TeknisiBottomNav() — DIHAPUS
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // Gunakan Navigator.pop agar tidak menyentuh GoRouter sama sekali
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Color(0xFF1A1A2E),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Ticket',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFEEEEEE)),
        ),
      ),
      body: FutureBuilder<TicketDetailResponse>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Data tidak ditemukan'));
          }

          final data = snapshot.data!.data;
          final ticket = data.ticket;
          final sub = data.subscription;
          final statusC = _statusColor(ticket.status);
          final priorityC = _priorityColor(ticket.priority);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // Hero
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.ticketNumber,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ticket.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _Badge(
                          label: ticket.status,
                          bg: statusC.bg,
                          fg: statusC.text,
                        ),
                        _Badge(
                          label: ticket.priority,
                          bg: priorityC.bg,
                          fg: priorityC.text,
                        ),
                        _Badge(
                          label: ticket.issueType,
                          bg: _gray50,
                          fg: _gray600,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              _SectionCard(
                icon: Icons.article_rounded,
                iconBg: _blue50,
                iconColor: _blue600,
                title: 'Deskripsi',
                child: Text(
                  ticket.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              _SectionCard(
                icon: Icons.confirmation_number_rounded,
                iconBg: _purple50,
                iconColor: _purple600,
                title: 'Informasi Ticket',
                child: Column(
                  children: [
                    _InfoRow('No Layanan', ticket.noLayanan ?? '-'),
                    _InfoRow('Status', ticket.status),
                    _InfoRow('Priority', ticket.priority),
                    _InfoRow('Issue', ticket.issueType),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              _SectionCard(
                icon: Icons.person_rounded,
                iconBg: _green50,
                iconColor: _green600,
                title: 'Customer',
                child: Column(
                  children: [
                    _InfoRow('Nama', ticket.customer?.name ?? '-'),
                    _InfoRow('Phone', ticket.customer?.phone ?? '-'),
                    _InfoRow('Alamat', ticket.customer?.address ?? '-'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              _SectionCard(
                icon: Icons.engineering_rounded,
                iconBg: _amber50,
                iconColor: _amber600,
                title: 'Teknisi',
                child: ticket.assignments.isEmpty
                    ? const Text(
                        'Belum ada assignment',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                      )
                    : Column(
                        children: ticket.assignments.map((e) {
                          final sc = _statusColor(e.status);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                _Initials(e.user?.name ?? '-'),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.user?.name ?? '-',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A2E),
                                        ),
                                      ),
                                      if ((e.notes ?? '').isNotEmpty)
                                        Text(
                                          e.notes!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                _Badge(label: e.status, bg: sc.bg, fg: sc.text),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),

              const SizedBox(height: 12),

              _SectionCard(
                icon: Icons.wifi_rounded,
                iconBg: _blue50,
                iconColor: _blue600,
                title: 'Subscription & Paket',
                child: Column(
                  children: [
                    _InfoRow('No Layanan', sub?.noLayanan ?? '-'),
                    _InfoRow('Status', sub?.status ?? '-'),
                    _InfoRow('Kategori', sub?.category ?? '-'),
                    _InfoRow('Paket', sub?.package?.name ?? '-'),
                    _InfoRow('Rate limit', sub?.package?.rateLimit ?? '-'),
                    _InfoRow('Harga', sub?.package?.price ?? '-'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              _SectionCard(
                icon: Icons.router_rounded,
                iconBg: _gray50,
                iconColor: _gray600,
                title: 'Router & Area',
                child: Column(
                  children: [
                    _InfoRow('Nama router', sub?.router?.namaRouter ?? '-'),
                    _InfoRow('IP address', sub?.router?.ipAddress ?? '-'),
                    _InfoRow('Area', sub?.area?.name ?? '-'),
                    _InfoRow('Kota', sub?.area?.city ?? '-'),
                    _InfoRow('Provinsi', sub?.area?.province ?? '-'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _ActionButton(
                icon: Icons.assignment_ind_rounded,
                label: 'Assign Ticket',
                color: _blue600,
                onTap: () => _showAssignDialog(ticket.id),
              ),
              const SizedBox(height: 10),
              _ActionButton(
                icon: Icons.check_circle_rounded,
                label: 'Selesaikan Ticket',
                color: _green600,
                onTap: () => _showCompleteDialog(ticket.id),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget pembantu (tidak berubah dari versi sebelumnya)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData? icon;
  final Color? iconBg;
  final Color? iconColor;
  final String? title;
  final Widget child;

  const _SectionCard({
    this.icon,
    this.iconBg,
    this.iconColor,
    this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null)
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: iconColor),
                  ),
                if (icon != null) const SizedBox(width: 10),
                Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Divider(height: 20, color: Color(0xFFF0F0F0)),
          ],
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
          const Text(
            ':  ',
            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A2E)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Badge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String name;
  const _Initials(this.name);

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE6F1FB),
      ),
      child: Center(
        child: Text(
          _initials,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0C447C),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF185FA5),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet — Assign
// Signature onSubmit diubah menjadi Function(BuildContext) agar sheet bisa
// menutup dirinya sendiri via rootNavigator tanpa bergantung GoRouter.
// ─────────────────────────────────────────────────────────────────────────────

class _AssignSheet extends StatefulWidget {
  final int userId;
  final TextEditingController notesController;
  final DateTime? initialStartedAt;
  final ValueChanged<DateTime> onStartedAtChanged;
  final void Function(BuildContext sheetContext) onSubmit;

  const _AssignSheet({
    required this.userId,
    required this.notesController,
    required this.initialStartedAt,
    required this.onStartedAtChanged,
    required this.onSubmit,
  });

  @override
  State<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends State<_AssignSheet> {
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = widget.initialStartedAt;
  }

  String _fmtDt(DateTime dt) => DateFormat('yyyy-MM-dd HH:mm').format(dt);

  Future<void> _pickDateTime() async {
    if (!mounted) return;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;
    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() => _startedAt = dt);
    widget.onStartedAtChanged(dt);
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetWrapper(
      title: 'Assign Ticket',
      submitLabel: 'Assign',
      submitColor: const Color(0xFF185FA5),
      onSubmit: () => widget.onSubmit(context),
      children: [
        _SheetField(
          label: 'Teknisi ID',
          child: Text(
            widget.userId.toString(),
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickDateTime,
          child: _SheetField(
            label: 'Waktu pengerjaan',
            trailing: const Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: Color(0xFF6B7280),
            ),
            child: Text(
              _startedAt != null
                  ? _fmtDt(_startedAt!)
                  : 'Pilih tanggal & waktu',
              style: TextStyle(
                fontSize: 14,
                color: _startedAt != null
                    ? const Color(0xFF1A1A2E)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SheetTextArea(controller: widget.notesController, label: 'Catatan'),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet — Complete
// ─────────────────────────────────────────────────────────────────────────────

class _CompleteSheet extends StatelessWidget {
  final TextEditingController notesController;
  final void Function(BuildContext sheetContext) onSubmit;

  const _CompleteSheet({required this.notesController, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return _BottomSheetWrapper(
      title: 'Selesaikan Ticket',
      submitLabel: 'Selesaikan',
      submitColor: const Color(0xFF3B6D11),
      onSubmit: () => onSubmit(context),
      children: [
        _SheetTextArea(
          controller: notesController,
          label: 'Catatan penyelesaian',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared bottom sheet wrapper
// Navigator.pop menggunakan rootNavigator: true agar tidak mengenai
// Navigator internal GoRouter yang ada di parent tree.
// ─────────────────────────────────────────────────────────────────────────────

class _BottomSheetWrapper extends StatelessWidget {
  final String title;
  final String submitLabel;
  final Color submitColor;
  final VoidCallback onSubmit;
  final List<Widget> children;

  const _BottomSheetWrapper({
    required this.title,
    required this.submitLabel,
    required this.submitColor,
    required this.onSubmit,
    required this.children,
  });

  void _close(BuildContext context) =>
      Navigator.of(context, rootNavigator: true).pop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _close(context),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _close(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: submitColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    submitLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final String label;
  final Widget child;
  final Widget? trailing;
  const _SheetField({required this.label, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 4),
                child,
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _SheetTextArea extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const _SheetTextArea({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 4,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF185FA5), width: 1.5),
        ),
      ),
    );
  }
}
