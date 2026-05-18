import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/ticket_model.dart';
import '../../providers/ticket_provider.dart';

class TicketDetailScreen extends ConsumerWidget {
  final int ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(ticketDetailProvider(ticketId));

    return Scaffold(
      appBar: AppBar(title: Text('Tiket #$ticketId')),
      body: ticketAsync.when(
        data: (ticket) => _buildDetailContent(context, ref, ticket),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      bottomNavigationBar: _buildActionButtons(context, ref),
    );
  }

  Widget _buildDetailContent(BuildContext context, WidgetRef ref, TicketModel ticket) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusHeader(ticket),
          const SizedBox(height: 32),
          _buildSectionTitle('Informasi Pelanggan'),
          const SizedBox(height: 12),
          _buildInfoCard([
            _buildInfoRow(Icons.person, 'Nama', ticket.customerName),
            _buildInfoRow(Icons.category, 'Kategori', ticket.category ?? 'Umum'),
            _buildInfoRow(Icons.calendar_today, 'Dibuat Pada', ticket.createdAt),
          ]),
          const SizedBox(height: 32),
          _buildSectionTitle('Deskripsi Keluhan'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(15)),
            child: Text(ticket.description, style: const TextStyle(height: 1.5)),
          ),
          const SizedBox(height: 32),
          if (ticket.photos.isNotEmpty) ...[
            _buildSectionTitle('Lampiran Foto'),
            const SizedBox(height: 12),
            _buildPhotoGallery(ticket.photos),
            const SizedBox(height: 32),
          ],
          _buildSectionTitle('Catatan Pekerjaan'),
          const SizedBox(height: 12),
          _buildNoteSection(),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(TicketModel ticket) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.2), Colors.transparent]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.confirmation_number, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Status Saat Ini', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text(ticket.status.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5));
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(15)),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(List<String> photos) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        itemBuilder: (context, index) => Container(
          width: 120,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(image: NetworkImage(photos[index]), fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
    return TextField(
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Tambahkan catatan progres...',
        fillColor: AppColors.surfaceDark,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Update Status'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Simpan'),
            ),
          ),
        ],
      ),
    );
  }
}
