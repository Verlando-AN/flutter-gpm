import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';

// ─── Data model sederhana untuk ODP ──────────────────────────────────────────

enum OdpStatus { aktif, gangguan, penuh }

class OdpPoint {
  final String kode;
  final String lokasi;
  final LatLng position;
  final int portTerisi;
  final int portTotal;
  final OdpStatus status;

  const OdpPoint({
    required this.kode,
    required this.lokasi,
    required this.position,
    required this.portTerisi,
    required this.portTotal,
    required this.status,
  });

  double get occupancyRate => portTerisi / portTotal;
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class OdpMapScreen extends StatefulWidget {
  const OdpMapScreen({super.key});

  @override
  State<OdpMapScreen> createState() => _OdpMapScreenState();
}

class _OdpMapScreenState extends State<OdpMapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final LatLng _center = const LatLng(-6.200000, 106.816666);
  final TextEditingController _searchController = TextEditingController();

  OdpPoint? _selectedOdp;
  bool _showDetail = false;
  String _filterStatus = 'Semua';
  bool _isSearchFocused = false;

  // Sample ODP data
  final List<OdpPoint> _odpList = const [
    OdpPoint(
      kode: 'ODP-JKT-FAC/001',
      lokasi: 'Jl. Sudirman No. 12, Jakarta Pusat',
      position: LatLng(-6.200000, 106.816666),
      portTerisi: 8,
      portTotal: 16,
      status: OdpStatus.aktif,
    ),
    OdpPoint(
      kode: 'ODP-JKT-FAC/002',
      lokasi: 'Jl. Thamrin No. 5, Jakarta Pusat',
      position: LatLng(-6.195000, 106.822000),
      portTerisi: 14,
      portTotal: 16,
      status: OdpStatus.penuh,
    ),
    OdpPoint(
      kode: 'ODP-JKT-FAC/003',
      lokasi: 'Jl. Kebon Sirih No. 8, Jakarta Pusat',
      position: LatLng(-6.207000, 106.826000),
      portTerisi: 3,
      portTotal: 8,
      status: OdpStatus.gangguan,
    ),
    OdpPoint(
      kode: 'ODP-JKT-FAC/004',
      lokasi: 'Jl. Wahid Hasyim No. 21',
      position: LatLng(-6.192000, 106.813000),
      portTerisi: 5,
      portTotal: 16,
      status: OdpStatus.aktif,
    ),
  ];

  List<OdpPoint> get _filteredOdp {
    return _odpList.where((o) {
      final matchFilter =
          _filterStatus == 'Semua' ||
          (_filterStatus == 'Aktif' && o.status == OdpStatus.aktif) ||
          (_filterStatus == 'Gangguan' && o.status == OdpStatus.gangguan) ||
          (_filterStatus == 'Penuh' && o.status == OdpStatus.penuh);
      final matchSearch =
          _searchController.text.isEmpty ||
          o.kode.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          o.lokasi.toLowerCase().contains(_searchController.text.toLowerCase());
      return matchFilter && matchSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _statusColor(OdpStatus status) {
    switch (status) {
      case OdpStatus.aktif:
        return const Color(0xFF10B981);
      case OdpStatus.gangguan:
        return const Color(0xFFF59E0B);
      case OdpStatus.penuh:
        return const Color(0xFFEF4444);
    }
  }

  String _statusLabel(OdpStatus status) {
    switch (status) {
      case OdpStatus.aktif:
        return 'Aktif';
      case OdpStatus.gangguan:
        return 'Gangguan';
      case OdpStatus.penuh:
        return 'Penuh';
    }
  }

  IconData _statusIcon(OdpStatus status) {
    switch (status) {
      case OdpStatus.aktif:
        return Icons.check_circle_rounded;
      case OdpStatus.gangguan:
        return Icons.warning_rounded;
      case OdpStatus.penuh:
        return Icons.block_rounded;
    }
  }

  void _selectOdp(OdpPoint odp) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedOdp = odp;
      _showDetail = true;
    });
    _mapController.move(odp.position, 15.5);
  }

  void _closeDetail() {
    setState(() => _showDetail = false);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _selectedOdp = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Stack(
          children: [
            // ── Map ──────────────────────────────────────────────────────────
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 14.0,
                onTap: (_, __) {
                  FocusScope.of(context).unfocus();
                  _closeDetail();
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.isp_app',
                ),
                MarkerLayer(
                  markers: _filteredOdp.map((odp) {
                    final isSelected = _selectedOdp?.kode == odp.kode;
                    final color = _statusColor(odp.status);
                    return Marker(
                      point: odp.position,
                      width: isSelected ? 64 : 52,
                      height: isSelected ? 64 : 52,
                      child: GestureDetector(
                        onTap: () => _selectOdp(odp),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected ? color : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color,
                              width: isSelected ? 0 : 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(
                                  isSelected ? 0.45 : 0.2,
                                ),
                                blurRadius: isSelected ? 20 : 10,
                                spreadRadius: isSelected ? 4 : 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.router_rounded,
                            color: isSelected ? Colors.white : color,
                            size: isSelected ? 28 : 22,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            // ── Top controls ─────────────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 10),
                  _buildFilterChips(),
                ],
              ),
            ),

            // ── Legend ───────────────────────────────────────────────────────
            if (!_showDetail) _buildLegend(),

            // ── Stats summary ─────────────────────────────────────────────────
            if (!_showDetail) _buildStatsBar(),

            // ── Bottom detail sheet ──────────────────────────────────────────
            AnimatedPositioned(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              bottom: _showDetail ? 0 : -400,
              left: 0,
              right: 0,
              child: _selectedOdp != null
                  ? _buildDetailSheet(_selectedOdp!)
                  : const SizedBox.shrink(),
            ),

            // ── FABs ─────────────────────────────────────────────────────────
            Positioned(
              right: 16,
              bottom: _showDetail ? 360 : 120,
              child: AnimatedSlide(
                offset: Offset.zero,
                duration: const Duration(milliseconds: 200),
                child: Column(
                  children: [
                    _buildFab(
                      icon: Icons.add,
                      onTap: () => _mapController.move(
                        _center,
                        _mapController.camera.zoom + 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFab(
                      icon: Icons.remove,
                      onTap: () => _mapController.move(
                        _center,
                        _mapController.camera.zoom - 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFab(
                      icon: Icons.my_location_rounded,
                      color: AppColors.primary,
                      iconColor: Colors.white,
                      onTap: () => _mapController.move(_center, 14.0),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TOP BAR ────────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          // Back button
          _buildSurface(
            width: 46,
            height: 46,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              color: AppColors.textPrimary,
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 10),

          // Search
          Expanded(
            child: _buildSurface(
              height: 46,
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      onTap: () => setState(() => _isSearchFocused = true),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari kode ODP...',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Total count badge
          _buildSurface(
            width: 46,
            height: 46,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_filteredOdp.length}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      height: 1,
                    ),
                  ),
                  Text(
                    'ODP',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── FILTER CHIPS ────────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    const filters = ['Semua', 'Aktif', 'Gangguan', 'Penuh'];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final label = filters[i];
          final isSelected = _filterStatus == label;
          Color chipColor;
          switch (label) {
            case 'Aktif':
              chipColor = const Color(0xFF10B981);
              break;
            case 'Gangguan':
              chipColor = const Color(0xFFF59E0B);
              break;
            case 'Penuh':
              chipColor = const Color(0xFFEF4444);
              break;
            default:
              chipColor = AppColors.primary;
          }
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _filterStatus = label);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? chipColor : Colors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isSelected ? chipColor : Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: chipColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── LEGEND ──────────────────────────────────────────────────────────────────

  Widget _buildLegend() {
    return Positioned(
      left: 16,
      bottom: 120,
      child: _buildSurface(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Keterangan',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            _legendItem(const Color(0xFF10B981), 'Aktif'),
            const SizedBox(height: 5),
            _legendItem(const Color(0xFFF59E0B), 'Gangguan'),
            const SizedBox(height: 5),
            _legendItem(const Color(0xFFEF4444), 'Penuh'),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ─── STATS BAR ───────────────────────────────────────────────────────────────

  Widget _buildStatsBar() {
    final aktif = _odpList.where((o) => o.status == OdpStatus.aktif).length;
    final gangguan = _odpList
        .where((o) => o.status == OdpStatus.gangguan)
        .length;
    final penuh = _odpList.where((o) => o.status == OdpStatus.penuh).length;

    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: _buildSurface(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem('$aktif', 'Aktif', const Color(0xFF10B981)),
            _divider(),
            _statItem('$gangguan', 'Gangguan', const Color(0xFFF59E0B)),
            _divider(),
            _statItem('$penuh', 'Penuh', const Color(0xFFEF4444)),
            _divider(),
            _statItem('${_odpList.length}', 'Total', AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
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
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 28, color: AppColors.border);
  }

  // ─── DETAIL SHEET ────────────────────────────────────────────────────────────

  Widget _buildDetailSheet(OdpPoint odp) {
    final color = _statusColor(odp.status);
    final occupancy = (odp.occupancyRate * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.router_rounded, color: color, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            odp.kode,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.place_rounded,
                                size: 12,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  odp.lokasi,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon(odp.status), color: color, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            _statusLabel(odp.status).toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Port usage
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Penggunaan Port',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${odp.portTerisi}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                          TextSpan(
                            text: ' / ${odp.portTotal} port',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: odp.occupancyRate,
                    backgroundColor: color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$occupancy% kapasitas terpakai',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                // Port grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 8,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  children: List.generate(odp.portTotal, (i) {
                    final isFilled = i < odp.portTerisi;
                    return Container(
                      decoration: BoxDecoration(
                        color: isFilled
                            ? color.withOpacity(0.15)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isFilled
                              ? color.withOpacity(0.4)
                              : Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        isFilled ? Icons.circle : Icons.circle_outlined,
                        color: isFilled ? color : Colors.grey.withOpacity(0.4),
                        size: 10,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildPrimaryButton(
                        icon: Icons.navigation_rounded,
                        label: 'Navigasi',
                        onTap: () {},
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSecondaryButton(
                        icon: Icons.info_outline_rounded,
                        label: 'Detail ODP',
                        onTap: () {},
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── REUSABLE WIDGETS ────────────────────────────────────────────────────────

  Widget _buildSurface({
    double? width,
    double? height,
    EdgeInsets? padding,
    Widget? child,
  }) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildFab({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
    Color iconColor = const Color(0xFF374151),
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color == Colors.white
                  ? Colors.black.withOpacity(0.1)
                  : AppColors.primary.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
