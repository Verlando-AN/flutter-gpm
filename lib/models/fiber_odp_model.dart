class FiberOdpModel {
  final int id;
  final String name;
  final String merkPerangkat;
  final int jumlahPortOdp;
  final int fiberodcId;
  final int noPortOdc;
  final double latitude;
  final double longitude;
  final String lokasiTerpasang;

  FiberOdpModel({
    required this.id,
    required this.name,
    required this.merkPerangkat,
    required this.jumlahPortOdp,
    required this.fiberodcId,
    required this.noPortOdc,
    required this.latitude,
    required this.longitude,
    required this.lokasiTerpasang,
  });

  factory FiberOdpModel.fromJson(Map<String, dynamic> json) {
    return FiberOdpModel(
      id: json['id'],
      name: json['name'] ?? '',
      merkPerangkat: json['merk_perangkat'] ?? '',
      jumlahPortOdp: json['jumlah_port_odp'] ?? 0,
      fiberodcId: json['fiberodc_id'] ?? 0,
      noPortOdc: json['no_port_odc'] ?? 0,
      latitude: double.tryParse(json['latitude'].toString()) ?? 0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0,
      lokasiTerpasang: json['lokasi_terpasang'] ?? '',
    );
  }
}
