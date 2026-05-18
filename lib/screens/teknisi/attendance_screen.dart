import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../core/constants/app_colors.dart';
import '../../repositories/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) => AttendanceRepository());

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  Position? _currentPosition;
  bool _isLoading = false;

  Future<void> _submitAttendance(String type) async {
    if (_currentPosition == null) {
      await _getCurrentLocation();
    }
    if (_currentPosition == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(attendanceRepositoryProvider).submitAttendance(
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        type: type,
      );
      Fluttertoast.showToast(msg: "Absensi $type berhasil dikirim!");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);
    } catch (e) {
      print(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presensi Kehadiran')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildLocationCard(),
            const SizedBox(height: 32),
            _buildCheckInSection(),
            const SizedBox(height: 32),
            _buildAttendanceHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.location_on, color: AppColors.primary, size: 48),
          const SizedBox(height: 16),
          const Text('Lokasi Anda Saat Ini', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          _isLoading
              ? const CircularProgressIndicator()
              : Text(
                  _currentPosition != null
                      ? 'Lat: ${_currentPosition!.latitude}, Lng: ${_currentPosition!.longitude}'
                      : 'Mencari lokasi...',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
        ],
      ),
    );
  }

  Widget _buildCheckInSection() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Check In',
            Icons.login,
            Colors.green,
            () => _submitAttendance('check_in'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            'Check Out',
            Icons.logout,
            Colors.red,
            () => _submitAttendance('check_out'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Riwayat Hari Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(15)),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hadir (Check-in)', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('13 Mei 2026, 08:02 WIB', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
        ),
      ],
    );
  }
}
