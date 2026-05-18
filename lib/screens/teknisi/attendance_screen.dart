import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/constants/app_colors.dart';
import '../../repositories/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepository(),
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

// ─── Screen ──────────────────────────────────────────────────────────────────
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  Position? _currentPosition;
  bool _isLocating = false;
  bool _isSubmitting = false;
  String? _locationError;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Sample history
  final List<AttendanceRecord> _history = const [
    AttendanceRecord(
      type: 'Check In',
      time: '08:02 WIB',
      date: 'Hari ini',
      isSuccess: true,
    ),
    AttendanceRecord(
      type: 'Check In',
      time: '08:15 WIB',
      date: 'Kemarin',
      isSuccess: true,
    ),
    AttendanceRecord(
      type: 'Check Out',
      time: '17:05 WIB',
      date: 'Kemarin',
      isSuccess: true,
    ),
    AttendanceRecord(
      type: 'Check In',
      time: '09:32 WIB',
      date: '16 Mei 2026',
      isSuccess: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
        setState(() => _locationError = 'Izin lokasi diblokir permanen');
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
      }
    } catch (e) {
      if (mounted) _showErrorSnackbar('$e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessSnackbar(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$action berhasil dicatat!',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Color(0xFFEF4444),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Gagal: $msg',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 2,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.top + 8),
            ),

            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildHeader(context),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Time & date card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildDateTimeCard(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Location card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildLocationCard(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Check in / out buttons
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildActionButtons(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Today summary
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildTodaySummary(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // History label
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSectionLabel('Riwayat Absensi'),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // History list
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _buildHistoryItem(_history[i], i),
                  childCount: _history.length,
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.bottom + 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
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
              size: 18,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Presensi',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                  height: 1,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Catat kehadiran harian Anda',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Aktif',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── DATE TIME ─────────────────────────────────────────────────────────────

  Widget _buildDateTimeCard() {
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
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withBlue(220).withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  timeStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  // ─── LOCATION CARD ─────────────────────────────────────────────────────────

  Widget _buildLocationCard() {
    final hasLocation = _currentPosition != null;
    final color = hasLocation ? const Color(0xFF10B981) : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: hasLocation
              ? const Color(0xFF10B981).withOpacity(0.3)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pulsing location icon
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) => Transform.scale(
              scale: _isLocating ? _pulseAnim.value : 1.0,
              child: child,
            ),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isLocating
                    ? Icons.gps_not_fixed_rounded
                    : hasLocation
                    ? Icons.gps_fixed_rounded
                    : Icons.location_off_rounded,
                color: color,
                size: 26,
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
                      ? 'Mendeteksi lokasi...'
                      : hasLocation
                      ? 'Lokasi terdeteksi'
                      : _locationError ?? 'Lokasi tidak tersedia',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _isLocating || hasLocation
                        ? AppColors.textPrimary
                        : const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 4),
                if (_isLocating)
                  LinearProgressIndicator(
                    backgroundColor: AppColors.primarySoft,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 3,
                  )
                else if (hasLocation)
                  Text(
                    '${_currentPosition!.latitude.toStringAsFixed(6)}, '
                    '${_currentPosition!.longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Text(
                    'Tap untuk coba lagi',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
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
                color: color.withOpacity(0.1),
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
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'Check In',
            icon: Icons.login_rounded,
            color: const Color(0xFF10B981),
            type: 'check_in',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildActionButton(
            label: 'Check Out',
            icon: Icons.logout_rounded,
            color: const Color(0xFFEF4444),
            type: 'check_out',
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required String type,
  }) {
    final isDisabled = _isSubmitting || _isLocating;

    return GestureDetector(
      onTap: isDisabled ? null : () => _submitAttendance(type),
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withOpacity(0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
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
                    : Icon(icon, color: color, size: 28),
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
              const SizedBox(height: 4),
              Text(
                type == 'check_in' ? 'Mulai kerja' : 'Selesai kerja',
                style: TextStyle(
                  color: color.withOpacity(0.6),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.today_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ringkasan Hari Ini',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  label: 'Check In',
                  value: '08:02',
                  unit: 'WIB',
                  icon: Icons.login_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: AppColors.border,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _buildSummaryItem(
                  label: 'Check Out',
                  value: '--:--',
                  unit: 'WIB',
                  icon: Icons.logout_rounded,
                  color: const Color(0xFFEF4444),
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: AppColors.border,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _buildSummaryItem(
                  label: 'Durasi',
                  value: '0',
                  unit: 'jam',
                  icon: Icons.timer_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: value == '--:--' || value == '0'
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  // ─── HISTORY ───────────────────────────────────────────────────────────────

  Widget _buildHistoryItem(AttendanceRecord record, int index) {
    final isCheckIn = record.type == 'Check In';
    final color = isCheckIn ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final icon = isCheckIn ? Icons.login_rounded : Icons.logout_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 20),
            ),

            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.type,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    record.date,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Time + status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  record.time,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: record.isSuccess
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    record.isSuccess ? 'Berhasil' : 'Gagal',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: record.isSuccess
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
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
