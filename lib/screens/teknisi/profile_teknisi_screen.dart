import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/teknisi_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/navigation/teknisi_bottom_nav.dart';

class ProfileTeknisiScreen extends ConsumerWidget {
  const ProfileTeknisiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final TeknisiModel? teknisi = authState.user is TeknisiModel
        ? authState.user as TeknisiModel
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      bottomNavigationBar: const TeknisiBottomNav(),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFEEEEEE), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(teknisi),
            const SizedBox(height: 28),
            _buildInfoCard(teknisi),
            const SizedBox(height: 24),
            _buildSectionLabel('Pengaturan'),
            const SizedBox(height: 8),
            _buildMenuCard(context, ref),
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
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE6F1FB),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 52,
                  color: Color(0xFF185FA5),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF185FA5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            teknisi?.name ?? 'Teknisi',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            teknisi?.email ?? 'teknisi@isp.net',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F1FB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Aktif',
              style: TextStyle(
                color: Color(0xFF185FA5),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(TeknisiModel? teknisi) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.phone_rounded,
            iconBg: const Color(0xFFE6F1FB),
            iconColor: const Color(0xFF185FA5),
            label: 'Nomor HP',
            value: teknisi?.phone ?? '-',
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 66),
          _buildInfoRow(
            icon: Icons.badge_rounded,
            iconBg: const Color(0xFFEAF3DE),
            iconColor: const Color(0xFF3B6D11),
            label: 'ID Identitas',
            value: teknisi?.identityNo ?? '-',
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0), indent: 66),
          _buildInfoRow(
            icon: Icons.calendar_today_rounded,
            iconBg: const Color(0xFFFAEEDA),
            iconColor: const Color(0xFF854F0B),
            label: 'Tanggal Bergabung',
            value: teknisi?.joinDate ?? '-',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF9CA3AF),
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
          ),
          child: Column(
            children: [
              _buildMenuItem(
                icon: Icons.edit_rounded,
                iconBg: const Color(0xFFE6F1FB),
                iconColor: const Color(0xFF185FA5),
                title: 'Edit Profil',
                onTap: () {},
              ),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              _buildMenuItem(
                icon: Icons.lock_reset_rounded,
                iconBg: const Color(0xFFEEEDFE),
                iconColor: const Color(0xFF534AB7),
                title: 'Ganti Password',
                onTap: () {},
              ),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              _buildMenuItem(
                icon: Icons.help_outline_rounded,
                iconBg: const Color(0xFFEAF3DE),
                iconColor: const Color(0xFF3B6D11),
                title: 'Pusat Bantuan',
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
          ),
          child: _buildMenuItem(
            icon: Icons.logout_rounded,
            iconBg: const Color(0xFFFCEBEB),
            iconColor: const Color(0xFFA32D2D),
            title: 'Logout',
            titleColor: const Color(0xFFA32D2D),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    Color titleColor = const Color(0xFF1A1A2E),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: titleColor == const Color(0xFF1A1A2E)
                  ? const Color(0xFFD1D5DB)
                  : titleColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
