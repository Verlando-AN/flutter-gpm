import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../models/activity_log_model.dart';
import '../../models/teknisi_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../repositories/activity_log_repository.dart';
import '../../widgets/navigation/teknisi_bottom_nav.dart';

class DashboardTeknisiScreen extends ConsumerStatefulWidget {
  const DashboardTeknisiScreen({super.key});

  @override
  ConsumerState<DashboardTeknisiScreen> createState() =>
      _DashboardTeknisiScreenState();
}

class _DashboardTeknisiScreenState extends ConsumerState<DashboardTeknisiScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _staggerController;

  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;

  final List<Animation<double>> _staggerFades = [];
  final List<Animation<Offset>> _staggerSlides = [];
  final ActivityLogRepository _activityLogRepository = ActivityLogRepository();
  IconData _getActivityIcon(String activity) {
    final text = activity.toLowerCase();

    if (text.contains('login')) {
      return Icons.login_rounded;
    }

    if (text.contains('logout')) {
      return Icons.logout_rounded;
    }

    if (text.contains('ticket')) {
      return Icons.confirmation_number_rounded;
    }

    if (text.contains('absensi')) {
      return Icons.camera_front_rounded;
    }

    return Icons.history_rounded;
  }

  Color _getActivityColor(String activity) {
    final text = activity.toLowerCase();

    if (text.contains('login')) {
      return Colors.green;
    }

    if (text.contains('logout')) {
      return Colors.red;
    }

    if (text.contains('ticket')) {
      return AppColors.primary;
    }

    if (text.contains('absensi')) {
      return Colors.purple;
    }

    return Colors.blueGrey;
  }

  static const int _staggerCount = 5;

  @override
  void initState() {
    super.initState();

    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heroFade = CurvedAnimation(parent: _heroController, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(begin: const Offset(0, -0.04), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic),
        );

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    for (int i = 0; i < _staggerCount; i++) {
      final start = i * 0.12;
      final end = (start + 0.55).clamp(0.0, 1.0);
      final interval = Interval(start, end, curve: Curves.easeOutCubic);
      _staggerFades.add(
        CurvedAnimation(parent: _staggerController, curve: interval),
      );
      _staggerSlides.add(
        Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _staggerController, curve: interval)),
      );
    }

    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _staggerController.forward();
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Widget _stagger(int index, Widget child) {
    return FadeTransition(
      opacity: _staggerFades[index],
      child: SlideTransition(position: _staggerSlides[index], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final TeknisiModel? teknisi = authState.user is TeknisiModel
        ? authState.user as TeknisiModel
        : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FF),

        bottomNavigationBar: const TeknisiBottomNav(),

        body: RefreshIndicator(
          color: AppColors.primary,
          displacement: 80,
          strokeWidth: 2.5,
          onRefresh: () async {
            ref.invalidate(ticketsProvider);
            try {
              await ref.read(ticketsProvider.future);
            } catch (_) {}
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // ── Hero Header ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _heroFade,
                  child: SlideTransition(
                    position: _heroSlide,
                    child: _HeroHeader(teknisi: teknisi),
                  ),
                ),
              ),

              // ── Stats (overlaps hero) ────────────────────────────────
              SliverToBoxAdapter(
                child: _stagger(
                  0,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildStatsSection(ref),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // ── Menu label ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: _stagger(
                  1,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const _SectionLabel(title: 'Menu Utama'),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // ── Menu Grid ────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: _stagger(2, _buildMenuGrid(context)),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // ── Activity label ───────────────────────────────────────
              SliverToBoxAdapter(
                child: _stagger(
                  3,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const _SectionLabel(title: 'Aktivitas Terbaru'),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // ── Activity list ────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: _stagger(4, _buildActivityList()),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  // Padding disesuaikan karena nav bawah sudah dihapus
                  height: MediaQuery.of(context).padding.bottom + 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── STATS ─────────────────────────────────────────────────────────────────

  Widget _buildStatsSection(WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketsProvider);
    return ticketsAsync.when(
      data: (tickets) {
        final open = tickets
            .where((t) => t.status.toLowerCase() == 'open')
            .length;
        final assigned = tickets
            .where((t) => t.status.toLowerCase() == 'assigned')
            .length;
        final inProgress = tickets
            .where((t) => t.status.toLowerCase() == 'in_progress')
            .length;
        final resolved = tickets
            .where((t) => t.status.toLowerCase() == 'resolved')
            .length;
        final total = tickets.length;
        return _StatsContent(
          total: total,
          open: open,
          assigned: assigned,
          inProgress: inProgress,
          resolved: resolved,
        );
      },
      loading: () => const _StatsContent(
        total: null,
        open: null,
        assigned: null,
        inProgress: null,
        resolved: null,
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ── MENU GRID ──────────────────────────────────────────────────────────────

  Widget _buildMenuGrid(BuildContext context) {
    final menus = [
      _MenuData(
        title: 'Data Tiket',
        subtitle: 'Kelola semua tiket',
        icon: Icons.confirmation_number_rounded,
        color: AppColors.primary,
        gradientEnd: const Color(0xFF6366F1),
        route: '/teknisi/tickets',
      ),
      _MenuData(
        title: 'Map ODP',
        subtitle: 'Sebaran titik ODP',
        icon: Icons.map_rounded,
        color: const Color(0xFF0EA5E9),
        gradientEnd: const Color(0xFF38BDF8),
        route: '/teknisi/map-odp',
      ),
      _MenuData(
        title: 'Pelanggan',
        subtitle: 'Lokasi pelanggan',
        icon: Icons.person_pin_circle_rounded,
        color: const Color(0xFF10B981),
        gradientEnd: const Color(0xFF34D399),
        route: '/teknisi/map-customer',
      ),
      _MenuData(
        title: 'Absensi',
        subtitle: 'Check-in harian',
        icon: Icons.camera_front_rounded,
        color: const Color(0xFF8B5CF6),
        gradientEnd: const Color(0xFFA78BFA),
        route: '/teknisi/attendance',
      ),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.0,
      ),
      itemCount: menus.length,
      itemBuilder: (context, i) => _MenuCard(data: menus[i]),
    );
  }

  // ── ACTIVITY LIST ──────────────────────────────────────────────────────────

  Widget _buildActivityList() {
    return FutureBuilder<List<ActivityLogModel>>(
      future: _activityLogRepository.getLogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(child: Text('Belum ada aktivitas')),
          );
        }

        return Column(
          children: List.generate(logs.length, (i) {
            final log = logs[i];

            return Padding(
              padding: EdgeInsets.only(bottom: i < logs.length - 1 ? 10 : 0),
              child: _ActivityCard(
                data: _ActivityData(
                  icon: _getActivityIcon(log.activity),
                  color: _getActivityColor(log.activity),
                  title: log.activity,
                  subtitle: log.ipAddress,
                  time: log.createdAt,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// HERO HEADER
// ════════════════════════════════════════════════════════════════════════════════

class _HeroHeader extends ConsumerWidget {
  const _HeroHeader({required this.teknisi});
  final TeknisiModel? teknisi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final hour = now.hour;
    final String greeting;
    final String emoji;
    if (hour < 11) {
      greeting = 'Selamat Pagi';
      emoji = '☀️';
    } else if (hour < 15) {
      greeting = 'Selamat Siang';
      emoji = '🌤';
    } else if (hour < 19) {
      greeting = 'Selamat Sore';
      emoji = '🌇';
    } else {
      greeting = 'Selamat Malam';
      emoji = '🌙';
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Background gradient card ──────────────────────────────────
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20,
            left: 24,
            right: 24,
            bottom: 30,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, const Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting row
                    Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 6),
                        Text(
                          greeting,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Name
                    Text(
                      teknisi?.name ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    // Online badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4ADE80),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Online · Siap Bertugas',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Avatar column (Logout removed)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.engineering_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Decorative blobs ──────────────────────────────────────────
        Positioned(
          right: -25,
          top: 0,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: 60,
          top: -20,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          left: -25,
          bottom: 30,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// STATS
// ════════════════════════════════════════════════════════════════════════════════

class _StatsContent extends StatelessWidget {
  const _StatsContent({
    required this.total,
    required this.open,
    required this.assigned,
    required this.inProgress,
    required this.resolved,
  });

  final int? total, open, assigned, inProgress, resolved;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 15),
      child: Column(
        children: [
          // ── Featured card ──────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL TIKET',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            total != null ? '$total' : '—',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 46,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -2,
                              height: 1,
                            ),
                          ),
                          if (total != null) ...[
                            const SizedBox(width: 6),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 7),
                              child: Text(
                                'tiket',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Progress bar
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          LayoutBuilder(
                            builder: (ctx, box) {
                              final progress =
                                  (total != null &&
                                      total! > 0 &&
                                      resolved != null)
                                  ? resolved! / total!
                                  : 0.0;
                              return Container(
                                height: 8,
                                width: box.maxWidth * progress,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      const Color(0xFF6366F1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        resolved != null && total != null
                            ? '$resolved dari $total tiket selesai'
                            : 'Memuat data...',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    Icons.insert_chart_rounded,
                    color: AppColors.primary,
                    size: 34,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Mini stat cards ────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Pending',
                  value: open != null ? '$open' : '—',
                  icon: Icons.hourglass_top_rounded,
                  color: const Color(0xFFF59E0B),
                  bgColor: const Color(0xFFFFFBEB),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: 'Assigned',
                  value: assigned != null ? '$assigned' : '—',
                  icon: Icons.person_rounded,
                  color: const Color(0xFF6366F1),
                  bgColor: const Color(0xFFEEF2FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: 'Proses',
                  value: inProgress != null ? '$inProgress' : '—',
                  icon: Icons.autorenew_rounded,
                  color: const Color(0xFF0EA5E9),
                  bgColor: const Color(0xFFE0F2FE),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: 'Selesai',
                  value: resolved != null ? '$resolved' : '—',
                  icon: Icons.task_alt_rounded,
                  color: const Color(0xFF10B981),
                  bgColor: const Color(0xFFECFDF5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  final String label, value;
  final IconData icon;
  final Color color, bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF0FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// SECTION LABEL
// ════════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, const Color(0xFF6366F1)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// MENU CARD
// ════════════════════════════════════════════════════════════════════════════════

class _MenuData {
  const _MenuData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.gradientEnd,
    required this.route,
  });
  final String title, subtitle, route;
  final IconData icon;
  final Color color, gradientEnd;
}

class _MenuCard extends StatefulWidget {
  const _MenuCard({required this.data});
  final _MenuData data;

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) async {
        await _pressCtrl.reverse();
        if (context.mounted) {
          HapticFeedback.selectionClick();
          context.push(d.route);
        }
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: d.color.withOpacity(0.15), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: d.color.withOpacity(0.10),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gradient icon box
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [d.color, d.gradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: d.color.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(d.icon, color: Colors.white, size: 26),
                ),

                const Spacer(),

                Text(
                  d.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  d.subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 10),

                // Color bar + arrow
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [d.color.withOpacity(0.25), d.color],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, color: d.color, size: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// ACTIVITY CARD
// ════════════════════════════════════════════════════════════════════════════════

class _ActivityData {
  const _ActivityData({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });
  final IconData icon;
  final Color color;
  final String title, subtitle, time;
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.data});
  final _ActivityData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF0FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left accent stripe
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [data.color.withOpacity(0.5), data.color],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(width: 14),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              data.time,
              style: TextStyle(
                color: data.color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
