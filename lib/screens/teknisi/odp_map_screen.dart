import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/fiber_odp_model.dart';
import '../../repositories/fiber_odp_repository.dart';

class OdpMapScreen extends StatefulWidget {
  const OdpMapScreen({super.key});

  @override
  State<OdpMapScreen> createState() => _OdpMapScreenState();
}

class _OdpMapScreenState extends State<OdpMapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FiberOdpRepository _repository = FiberOdpRepository();

  List<FiberOdpModel> _odpList = [];
  List<FiberOdpModel> _filteredOdp = [];
  FiberOdpModel? _selectedOdp;

  bool _isLoading = true;
  bool _showDetail = false;

  static const _defaultCenter = LatLng(-6.200000, 106.816666);

  // Ganti dengan API KEY MapTiler Anda
  static const String _maptilerKey = '70hLFM9hwitlCf8oL7IY';

  // Warna status port
  static const _colorFull = Color(0xFFA32D2D);
  static const _colorWarn = Color(0xFF854F0B);
  static const _colorOk = Color(0xFF3B6D11);

  static const _bgFull = Color(0xFFFCEBEB);
  static const _bgWarn = Color(0xFFFAEEDA);
  static const _bgOk = Color(0xFFEAF3DE);

  @override
  void initState() {
    super.initState();
    _loadOdp();
    _searchController.addListener(_filterData);
  }

  Future<void> _loadOdp() async {
    try {
      setState(() => _isLoading = true);

      final data = await _repository.getOdps();

      setState(() {
        _odpList = data;
        _filteredOdp = data;
      });

      if (data.isNotEmpty) {
        final first = data.first;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(LatLng(first.latitude, first.longitude), 13);
        });
      }
    } catch (e) {
      debugPrint('GET ODP ERROR => $e');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterData() {
    final keyword = _searchController.text.toLowerCase();

    setState(() {
      _filteredOdp = _odpList.where((e) {
        return e.name.toLowerCase().contains(keyword) ||
            e.merkPerangkat.toLowerCase().contains(keyword) ||
            e.lokasiTerpasang.toLowerCase().contains(keyword);
      }).toList();
    });
  }

  void _selectOdp(FiberOdpModel odp) {
    HapticFeedback.selectionClick();

    setState(() {
      _selectedOdp = odp;
      _showDetail = true;
    });

    _mapController.move(LatLng(odp.latitude, odp.longitude), 16);
  }

  void _closeDetail() {
    setState(() => _showDetail = false);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _selectedOdp = null);
      }
    });
  }

  Color _getPortColor(int used, int total) {
    if (total == 0) return _colorOk;

    final pct = used / total;

    if (pct >= 0.9) return _colorFull;
    if (pct >= 0.6) return _colorWarn;

    return _colorOk;
  }

  Color _getPortBg(int used, int total) {
    if (total == 0) return _bgOk;

    final pct = used / total;

    if (pct >= 0.9) return _bgFull;
    if (pct >= 0.6) return _bgWarn;

    return _bgOk;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _defaultCenter,
                initialZoom: 5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onTap: (_, __) {
                  FocusScope.of(context).unfocus();
                  _closeDetail();
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=$_maptilerKey',
                  userAgentPackageName: 'com.example.isp_app',
                  maxZoom: 19,
                  tileDisplay: const TileDisplay.fadeIn(),
                ),

                RichAttributionWidget(
                  alignment: AttributionAlignment.bottomRight,
                  attributions: const [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                    TextSourceAttribution('© MapTiler'),
                  ],
                ),

                MarkerLayer(
                  markers: _filteredOdp.map((odp) {
                    final color = _getPortColor(0, odp.jumlahPortOdp);

                    final isSelected = _selectedOdp?.id == odp.id;

                    return Marker(
                      point: LatLng(odp.latitude, odp.longitude),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => _selectOdp(odp),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? color : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 2.2),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.15),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.router_rounded,
                            color: isSelected ? Colors.white : color,
                            size: 20,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            // TOP BAR
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    _TopBarButton(
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Color(0xFF1A1A2E),
                      ),
                      onTap: () => Navigator.pop(context),
                    ),

                    const SizedBox(width: 10),

                    Expanded(child: _SearchBar(controller: _searchController)),

                    const SizedBox(width: 10),

                    _TopBarButton(
                      child: Text(
                        '${_filteredOdp.length}',
                        style: const TextStyle(
                          color: Color(0xFF185FA5),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // LEGEND
            const SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(top: 72, right: 16),
                  child: _Legend(),
                ),
              ),
            ),

            if (_isLoading) const Center(child: CircularProgressIndicator()),

            if (_selectedOdp != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                left: 0,
                right: 0,
                bottom: _showDetail ? 0 : -500,
                child: _buildDetailSheet(_selectedOdp!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSheet(FiberOdpModel odp) {
    final color = _getPortColor(0, odp.jumlahPortOdp);

    final bg = _getPortBg(0, odp.jumlahPortOdp);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(Icons.router_rounded, color: color, size: 28),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          odp.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          odp.lokasiTerpasang,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  GestureDetector(
                    onTap: _closeDetail,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: _InfoTile(
                      icon: Icons.memory_rounded,
                      label: 'Merk',
                      value: odp.merkPerangkat,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _InfoTile(
                      icon: Icons.hub_rounded,
                      label: 'Jumlah port',
                      value: '${odp.jumlahPortOdp}',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _InfoTile(
                      icon: Icons.cable_rounded,
                      label: 'Port ODC',
                      value: '${odp.noPortOdc}',
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _InfoTile(
                      icon: Icons.device_hub_rounded,
                      label: 'Fiber ODC ID',
                      value: '${odp.fiberodcId}',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.navigation_rounded),
                  label: const Text(
                    'Navigasi',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF185FA5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//────────────────────────────────────────────

class _TopBarButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _TopBarButton({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;

  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 20, color: Color(0xFF9CA3AF)),

          const SizedBox(width: 8),

          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Cari ODP...',
                hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    const rows = [
      (Color(0xFF3B6D11), 'Normal'),
      (Color(0xFF854F0B), '60–90%'),
      (Color(0xFFA32D2D), 'Penuh'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows
            .map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: r.$1, width: 2),
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      r.$2,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF185FA5)),

          const SizedBox(height: 10),

          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),

          const SizedBox(height: 3),

          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
