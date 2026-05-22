class CustomerModel {
  final int id;
  final String name;
  final String email;
  final String address;
  final String phone;
  final String whatsapp;
  final String status;

  CustomerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.address,
    required this.phone,
    required this.whatsapp,
    required this.status,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['customer_name'] ?? 'Unknown Customer',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone']?.toString() ?? '',
      whatsapp:
          json['whatsapp']?.toString() ??
          json['contact_whatsapp']?.toString() ??
          '',
      status: json['status'] ?? 'Aktif',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'address': address,
      'phone': phone,
      'whatsapp': whatsapp,
      'status': status,
    };
  }
}
