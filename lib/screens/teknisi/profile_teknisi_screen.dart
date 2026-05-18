import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../models/teknisi_model.dart';

class ProfileTeknisiScreen extends ConsumerWidget {
  const ProfileTeknisiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final TeknisiModel? teknisi = authState.user is TeknisiModel ? authState.user as TeknisiModel : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildHeader(teknisi),
            const SizedBox(height: 32),
            _buildInfoCard(teknisi),
            const SizedBox(height: 24),
            _buildSettingsList(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(TeknisiModel? teknisi) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.surfaceDark,
                child: const Icon(Icons.person, size: 80, color: Colors.white),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(teknisi?.name ?? 'Teknisi', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(teknisi?.email ?? 'teknisi@isp.net', style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(TeknisiModel? teknisi) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _buildInfoRow(Icons.phone, 'Nomor HP', teknisi?.phone ?? '-'),
          const Divider(height: 32, color: Colors.white10),
          _buildInfoRow(Icons.badge, 'ID Identitas', teknisi?.identityNo ?? '-'),
          const Divider(height: 32, color: Colors.white10),
          _buildInfoRow(Icons.event, 'Tanggal Bergabung', teknisi?.joinDate ?? '-'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsList(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _buildSettingsItem(Icons.edit, 'Edit Profil', () {}),
        _buildSettingsItem(Icons.lock_reset, 'Ganti Password', () {}),
        _buildSettingsItem(Icons.help_outline, 'Pusat Bantuan', () {}),
        const SizedBox(height: 16),
        _buildSettingsItem(Icons.logout, 'Logout', () async {
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) context.go('/login');
        }, color: Colors.red),
      ],
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, VoidCallback onTap, {Color color = Colors.white}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
    );
  }
}
