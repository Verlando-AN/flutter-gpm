import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/constants/app_colors.dart';
import '../../repositories/attendance_repository.dart';
import '../../repositories/auth_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepository(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

// ─── Dummy history model ──────────────────────────────────────────────────────
class AttendanceRecord {
  final String type;
  final String time;
  final String date;
  final bool isSuccess;

  const AttendanceRecord({
    required this.type,
    required this.time,
    required this.date,
    required this.isSuccess,
  });
}

// ─── Color palette ────────────────────────────────────────────────────────────
class _Palette {
  static const emerald = Color(0xFF059669);
  static const emeraldLight = Color(0xFF10B981);
  static const emeraldSoft = Color(0xFFD1FAE5);
  static const rose = Color(0xFFE11D48);
  static const roseSoft = Color(0xFFFFE4E6);
  static const amber = Color(0xFFD97706);
  static const amberSoft = Color(0xFFFEF3C7);
  static const ink = Color(0xFF0F172A);
  static const inkMedium = Color(0xFF334155);
  static const inkLight = Color(0xFF64748B);
  static const canvas = Color(0xFFF8FAFC);
  static const white = Colors.white;
  static const cardBorder = Color(0xFFE2E8F0);
  static const card = Colors.white;
}

// ─── Screen ──────────────────────────────────────────────────────────────────
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen>
    with TickerProviderStateMixin {
  Position? _currentPosition;
  bool _isLocating = false;
  bool _isSubmitting = false;
  String? _locationError;

  bool _isReportLoading = false;
  String? _reportError;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  final Map<int, String> _monthLabels = const {
    1: 'Januari',
    2: 'Februari',
    3: 'Maret',
    4: 'April',
    5: 'Mei',
    6: 'Juni',
    7: 'Juli',
    8: 'Agustus',
    9: 'September',
    10: 'Oktober',
    11: 'November',
    12: 'Desember',
  };
  List<int> _availableYears = [];
  Map<String, dynamic>? _reportStats;
  List<dynamic> _reportDays = [];

  bool _isTodayLoading = false;
  String? _todayState;
  String? _todayShiftLabel;
  Map<String, dynamic>? _todayRecord;

  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;

  final List<AttendanceRecord> _history = const [
    AttendanceRecord(
      type: 'Check In',
      time: '08:02',
      date: 'Hari ini',
      isSuccess: true,
    ),
    AttendanceRecord(
      type: 'Check In',
      time: '08:15',
      date: 'Kemarin',
      isSuccess: true,
    ),
    AttendanceRecord(
      type: 'Check Out',
      time: '17:05',
      date: 'Kemarin',
      isSuccess: true,
    ),
    AttendanceRecord(
      type: 'Check In',
      time: '09:32',
      date: '16 Mei 2026',
      isSuccess: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _getCurrentLocation();
    _loadAttendanceReport();
    _loadTodayAttendance();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locationError = 'Layanan lokasi tidak aktif');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _locationError = 'Izin lokasi ditolak');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _locationError = 'Izin lokasi diblokir');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _currentPosition = position);
    } catch (e) {
      setState(() => _locationError = 'Gagal mendapatkan lokasi');
    } finally {
      setState(() => _isLocating = false);
    }
  }

  Future<void> _submitAttendance(String type) async {
    if (_currentPosition == null) {
      await _getCurrentLocation();
      if (_currentPosition == null) return;
    }
    HapticFeedback.heavyImpact();
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(attendanceRepositoryProvider)
          .submitAttendance(
            lat: _currentPosition!.latitude,
            lng: _currentPosition!.longitude,
            type: type,
          );
      if (mounted) {
        _showSuccessSnackbar(type == 'check_in' ? 'Check In' : 'Check Out');
        _loadTodayAttendance();
        _loadAttendanceReport();
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('$e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _loadTodayAttendance() async {
    setState(() {
      _isTodayLoading = true;
      _todayState = null;
      _todayShiftLabel = null;
      _todayRecord = null;
    });
    try {
      final user = await ref.read(authRepositoryProvider).getStoredUser();
      final userId = user != null && user['id'] is int
          ? user['id'] as int
          : null;
      final data = await ref
          .read(attendanceRepositoryProvider)
          .fetchTodayAttendance(userId: userId);
      setState(() {
        _todayState = data['state']?.toString();
        _todayShiftLabel = data['shift_label']?.toString();
        _todayRecord = data['today_record'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['today_record'] as Map)
            : null;
      });
    } catch (_) {
      if (mounted) {
        _todayState = null;
        _todayShiftLabel = null;
        _todayRecord = null;
      }
    } finally {
      if (mounted) setState(() => _isTodayLoading = false);
    }
  }

  Future<void> _loadAttendanceReport() async {
    setState(() {
      _isReportLoading = true;
      _reportError = null;
    });
    try {
      final user = await ref.read(authRepositoryProvider).getStoredUser();
      final userId = user != null && user['id'] is int
          ? user['id'] as int
          : null;
      final data = await ref
          .read(attendanceRepositoryProvider)
          .fetchAttendanceReport(
            userId: userId,
            month: _selectedMonth,
            year: _selectedYear,
          );
      setState(() {
        _reportStats = data['stats'] as Map<String, dynamic>?;
        _reportDays = List<dynamic>.from(data['days'] ?? []);
        final years =
            List<dynamic>.from(data['years'] ?? [])
                .map(
                  (item) =>
                      int.tryParse(item.toString()) ?? DateTime.now().year,
                )
                .toSet()
                .toList()
              ..sort();
        if (!years.contains(_selectedYear)) {
          years.add(_selectedYear);
          years.sort();
        }
        _availableYears = years;
      });
    } catch (e) {
      if (mounted) setState(() => _reportError = e.toString());
    } finally {
      if (mounted) setState(() => _isReportLoading = false);
    }
  }

  void _showSuccessSnackbar(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: _Palette.emeraldLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 15,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$action berhasil dicatat!',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _Palette.ink,
              ),
            ),
          ],
        ),
        backgroundColor: _Palette.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        elevation: 4,
      ),
    );
  }

  void _showErrorSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _Palette.rose.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: _Palette.rose,
                size: 15,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Gagal: $msg',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: _Palette.ink,
                ),
                maxLines: 2,
              ),
            ),
          ],
        ),
        backgroundColor: _Palette.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        elevation: 4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _Palette.canvas,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).padding.top + 4),
              ),

              // ── Hero Header ──
              SliverToBoxAdapter(child: _buildHeroHeader(context)),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Location Card ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildLocationCard(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Action Buttons ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildActionButtons(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Today Summary ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildTodaySummary(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Report Filter ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildReportFilterSection(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // ── Report Stats ──
              if (_reportError != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildErrorBanner(_reportError!),
                  ),
                ),
              if (_reportStats != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildReportSummaryCard(),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Section Label ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSectionLabel('Riwayat Absensi'),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // ── History List ──
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      if (_isReportLoading) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: _Palette.emerald,
                              strokeWidth: 2.5,
                            ),
                          ),
                        );
                      }
                      if (_reportDays.isNotEmpty)
                        return _buildReportHistoryItem(_reportDays[i]);
                      return _buildHistoryItem(_history[i], i);
                    },
                    childCount: _isReportLoading
                        ? 1
                        : _reportDays.isNotEmpty
                        ? _reportDays.length
                        : _history.length,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 40,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HERO HEADER ───────────────────────────────────────────────────────────

  Widget _buildHeroHeader(BuildContext context) {
    final now = DateTime.now();
    final days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final dayName = days[now.weekday - 1];
    final dateStr = '$dayName, ${now.day} ${months[now.month - 1]} ${now.year}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: EdgeInsets.zero,
      child: Stack(
        children: [
          // Gradient Background
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F2027),
                  Color(0xFF203A43),
                  Color(0xFF2C5364),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: back + status badge
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _Palette.emeraldLight.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: _Palette.emeraldLight.withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: _Palette.emeraldLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Aktif',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _Palette.emeraldLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Title
                const Text(
                  'Presensi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Catat kehadiran harian Anda',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 28),

                // Big clock
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'WIB',
                        style: TextStyle(
                          color: _Palette.emeraldLight,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.white38,
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Decorative circles
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _Palette.emeraldLight.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            right: 30,
            top: 30,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── LOCATION CARD ─────────────────────────────────────────────────────────

  Widget _buildLocationCard() {
    final hasLocation = _currentPosition != null;
    final color = hasLocation
        ? _Palette.emerald
        : (_locationError != null ? _Palette.rose : AppColors.primary);
    final softColor = hasLocation
        ? _Palette.emeraldSoft
        : (_locationError != null ? _Palette.roseSoft : AppColors.primarySoft);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasLocation ? _Palette.emeraldSoft : _Palette.cardBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) => Transform.scale(
              scale: _isLocating ? _pulseAnim.value : 1.0,
              child: child,
            ),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: softColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isLocating
                    ? Icons.gps_not_fixed_rounded
                    : hasLocation
                    ? Icons.gps_fixed_rounded
                    : Icons.location_off_rounded,
                color: color,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLocating
                      ? 'Mendeteksi lokasi…'
                      : hasLocation
                      ? 'Lokasi terdeteksi'
                      : _locationError ?? 'Lokasi tidak tersedia',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _isLocating
                        ? _Palette.inkMedium
                        : hasLocation
                        ? _Palette.emerald
                        : _Palette.rose,
                  ),
                ),
                const SizedBox(height: 4),
                if (_isLocating)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      backgroundColor: softColor,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 3,
                    ),
                  )
                else if (hasLocation)
                  Text(
                    '${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: _Palette.inkLight,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  const Text(
                    'Ketuk untuk coba lagi',
                    style: TextStyle(fontSize: 11, color: _Palette.inkLight),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isLocating ? null : _getCurrentLocation,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: softColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.refresh_rounded, color: color, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ACTION BUTTONS ────────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    final isCheckedIn = _todayState == 'checked_in';
    final isCheckedOut = _todayState == 'checked_out';
    final isDisabled = _isSubmitting || _isLocating;

    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'Check In',
            sublabel: 'Mulai kerja',
            icon: Icons.login_rounded,
            color: _Palette.emerald,
            softColor: _Palette.emeraldSoft,
            type: 'check_in',
            isDisabled: isDisabled || isCheckedIn || isCheckedOut,
            isDone: isCheckedIn || isCheckedOut,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildActionButton(
            label: 'Check Out',
            sublabel: 'Selesai kerja',
            icon: Icons.logout_rounded,
            color: _Palette.rose,
            softColor: _Palette.roseSoft,
            type: 'check_out',
            isDisabled: isDisabled || !isCheckedIn || isCheckedOut,
            isDone: isCheckedOut,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required String sublabel,
    required IconData icon,
    required Color color,
    required Color softColor,
    required String type,
    required bool isDisabled,
    required bool isDone,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : () => _submitAttendance(type),
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 250),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: isDone ? softColor : _Palette.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDone ? color.withOpacity(0.35) : _Palette.cardBorder,
              width: isDone ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDone
                    ? color.withOpacity(0.1)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: isDone ? color.withOpacity(0.15) : softColor,
                  shape: BoxShape.circle,
                ),
                child: _isSubmitting
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          color: color,
                          strokeWidth: 2.5,
                        ),
                      )
                    : isDone
                    ? Icon(Icons.check_circle_rounded, color: color, size: 28)
                    : Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                sublabel,
                style: TextStyle(
                  color: color.withOpacity(0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── TODAY SUMMARY ─────────────────────────────────────────────────────────

  Widget _buildTodaySummary() {
    final checkInTime = _todayRecord?['check_in_time']?.toString() ?? '--:--';
    final checkOutTime = _todayRecord?['check_out_time']?.toString() ?? '--:--';
    final duration = _calculateDurationLabel();
    final shiftLabel = _todayShiftLabel ?? 'Belum ada shift';

    return Container(
      decoration: BoxDecoration(
        color: _Palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.today_rounded,
                    color: Color(0xFF3B82F6),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Ringkasan Hari Ini',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _Palette.ink,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    shiftLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3 stat tiles
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryTile(
                    label: 'Check In',
                    value: checkInTime,
                    icon: Icons.login_rounded,
                    color: _Palette.emerald,
                    softColor: _Palette.emeraldSoft,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryTile(
                    label: 'Check Out',
                    value: checkOutTime,
                    icon: Icons.logout_rounded,
                    color: _Palette.rose,
                    softColor: _Palette.roseSoft,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSummaryTile(
                    label: 'Durasi',
                    value: duration,
                    unit: 'jam',
                    icon: Icons.timer_outlined,
                    color: const Color(0xFF7C3AED),
                    softColor: const Color(0xFFEDE9FE),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile({
    required String label,
    required String value,
    String? unit,
    required IconData icon,
    required Color color,
    required Color softColor,
  }) {
    final isEmpty = value == '--:--' || value == '0';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isEmpty ? const Color(0xFFF8FAFC) : softColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEmpty ? _Palette.cardBorder : color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: isEmpty ? _Palette.inkLight : color, size: 18),
          const SizedBox(height: 8),
          Text(
            unit != null ? '$value $unit' : value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: isEmpty ? _Palette.inkLight : _Palette.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: _Palette.inkLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── REPORT FILTER ─────────────────────────────────────────────────────────

  Widget _buildReportFilterSection() {
    final years = _availableYears.isNotEmpty
        ? _availableYears
        : [DateTime.now().year];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _Palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _Palette.amberSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.filter_list_rounded,
                  color: _Palette.amber,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Filter Laporan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _Palette.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildDropdownBox(
                  child: DropdownButton<int>(
                    value: _selectedMonth,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    style: const TextStyle(
                      color: _Palette.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    items: _monthLabels.entries
                        .map(
                          (e) => DropdownMenuItem<int>(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _selectedMonth = v);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDropdownBox(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    style: const TextStyle(
                      color: _Palette.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    items: years
                        .map(
                          (y) => DropdownMenuItem<int>(
                            value: y,
                            child: Text(y.toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _selectedYear = v);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isReportLoading ? null : _loadAttendanceReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Palette.ink,
                    disabledBackgroundColor: _Palette.inkLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: _isReportLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Terapkan',
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
        ],
      ),
    );
  }

  Widget _buildDropdownBox({required Widget child}) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _Palette.canvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Palette.cardBorder),
      ),
      child: child,
    );
  }

  // ─── REPORT SUMMARY ────────────────────────────────────────────────────────

  Widget _buildReportSummaryCard() {
    if (_reportStats == null) return const SizedBox.shrink();
    final hadir = _reportStats?['hadir']?.toString() ?? '0';
    final izin = _reportStats?['izin']?.toString() ?? '0';
    final alpa = _reportStats?['alpa']?.toString() ?? '0';
    final percent = _reportStats?['persentase']?.toString() ?? '0';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _Palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _Palette.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistik Bulanan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _Palette.ink,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  'Hadir',
                  hadir,
                  _Palette.emerald,
                  _Palette.emeraldSoft,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatChip(
                  'Izin',
                  izin,
                  _Palette.amber,
                  _Palette.amberSoft,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatChip(
                  'Alpa',
                  alpa,
                  _Palette.rose,
                  _Palette.roseSoft,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatChip(
                  'Hadir %',
                  '$percent%',
                  const Color(0xFF7C3AED),
                  const Color(0xFFEDE9FE),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color, Color soft) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _Palette.inkLight,
            ),
          ),
        ],
      ),
    );
  }

  // ─── ERROR BANNER ──────────────────────────────────────────────────────────

  Widget _buildErrorBanner(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _Palette.roseSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Palette.rose.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: _Palette.rose,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                fontSize: 12,
                color: _Palette.rose,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECTION LABEL ─────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _Palette.ink,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _Palette.ink,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ─── REPORT HISTORY ITEM ───────────────────────────────────────────────────

  Widget _buildReportHistoryItem(Map<String, dynamic> day) {
    final attendance = day['attendance'] as Map<String, dynamic>?;
    final isPresent = attendance != null;
    final isAlpa = day['is_alpa'] == true;
    final statusLabel = isPresent
        ? (attendance['status']?.toString() ?? 'Hadir')
        : isAlpa
        ? 'Alpa'
        : day['is_future'] == true
        ? 'Mendatang'
        : day['is_before_join'] == true
        ? 'Sebelum bergabung'
        : 'Tidak hadir';
    final timeLabel = isPresent
        ? (attendance['check_out_time'] != null
              ? 'CI ${attendance['check_in_time'] ?? '-'} · CO ${attendance['check_out_time'] ?? '-'}'
              : 'CI ${attendance['check_in_time'] ?? '-'}')
        : '--:--';
    final dateLabel = _formatReportDayDate(day['date']?.toString());

    final statusColor = isPresent
        ? _Palette.emerald
        : isAlpa
        ? _Palette.rose
        : _Palette.inkLight;
    final statusSoft = isPresent
        ? _Palette.emeraldSoft
        : isAlpa
        ? _Palette.roseSoft
        : const Color(0xFFF1F5F9);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _Palette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _Palette.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: statusSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                isPresent
                    ? Icons.check_circle_outline_rounded
                    : isAlpa
                    ? Icons.cancel_outlined
                    : Icons.radio_button_unchecked_rounded,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${day['day_name'] ?? ''}, $dateLabel',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: _Palette.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _Palette.inkMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (day['shift_label'] != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      day['shift_label'].toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: _Palette.inkLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusSoft,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatReportDayDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    try {
      final parsed = DateTime.parse(rawDate);
      return '${parsed.day} ${_monthLabels[parsed.month] ?? ''}';
    } catch (_) {
      return rawDate;
    }
  }

  String _calculateDurationLabel() {
    final checkIn = _todayRecord?['check_in_time']?.toString();
    final checkOut = _todayRecord?['check_out_time']?.toString();
    if (checkIn == null ||
        checkOut == null ||
        checkIn.isEmpty ||
        checkOut.isEmpty)
      return '0';
    try {
      final inParts = checkIn.split(':').map(int.parse).toList();
      final outParts = checkOut.split(':').map(int.parse).toList();
      final diff =
          Duration(
            hours: outParts[0],
            minutes: outParts[1],
            seconds: outParts.length > 2 ? outParts[2] : 0,
          ) -
          Duration(
            hours: inParts[0],
            minutes: inParts[1],
            seconds: inParts.length > 2 ? inParts[2] : 0,
          );
      if (diff.isNegative) return '0';
      return diff.inHours.toString();
    } catch (_) {
      return '0';
    }
  }

  // ─── HISTORY ITEM (dummy fallback) ─────────────────────────────────────────

  Widget _buildHistoryItem(AttendanceRecord record, int index) {
    final isCheckIn = record.type == 'Check In';
    final color = isCheckIn ? _Palette.emerald : _Palette.rose;
    final soft = isCheckIn ? _Palette.emeraldSoft : _Palette.roseSoft;
    final icon = isCheckIn ? Icons.login_rounded : Icons.logout_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _Palette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _Palette.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.type,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: _Palette.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    record.date,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _Palette.inkLight,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  record.time,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _Palette.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: record.isSuccess
                        ? _Palette.emeraldSoft
                        : _Palette.roseSoft,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    record.isSuccess ? 'Berhasil' : 'Gagal',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: record.isSuccess
                          ? _Palette.emerald
                          : _Palette.rose,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
