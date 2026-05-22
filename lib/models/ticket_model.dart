import 'customer_model.dart';

class TicketModel {
  final int id;
  final String ticketNumber;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String? category;
  final String createdAt;
  final String? updatedAt;
  final String contactWhatsapp;
  final CustomerModel customer;
  final List<String> photos;

  TicketModel({
    required this.id,
    required this.ticketNumber,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.category,
    required this.createdAt,
    this.updatedAt,
    required this.contactWhatsapp,
    required this.customer,
    this.photos = const [],
  });

  String get customerName => customer.name;

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    final customerData =
        json['customer'] as Map<String, dynamic>? ??
        json['customer_data'] as Map<String, dynamic>? ??
        {
          'name': json['customer_name'] ?? 'Unknown Customer',
          'phone': json['contact_whatsapp'] ?? '',
        };

    final customer = CustomerModel.fromJson(customerData);

    final contactWhatsapp =
        (json['contact_whatsapp'] ?? '').toString().isNotEmpty
        ? json['contact_whatsapp'].toString()
        : (customer.whatsapp.isNotEmpty ? customer.whatsapp : customer.phone);

    return TicketModel(
      id: int.tryParse(json['id'].toString()) ?? 0,

      ticketNumber:
          json['ticket_number']?.toString() ??
          json['ticket_no']?.toString() ??
          '#${json['id'] ?? 0}',

      title: json['title']?.toString() ?? '',

      description: json['description']?.toString() ?? '',

      status: json['status']?.toString() ?? 'open',

      priority: json['priority']?.toString() ?? 'medium',

      category: json['category']?.toString(),

      createdAt:
          json['created_at']?.toString() ?? json['createdAt']?.toString() ?? '',

      updatedAt: json['updated_at']?.toString(),

      contactWhatsapp: contactWhatsapp,

      customer: customer,

      photos: json['photos'] is List
          ? List<String>.from((json['photos'] as List).map((e) => e.toString()))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_number': ticketNumber,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'category': category,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'contact_whatsapp': contactWhatsapp,
      'customer': customer.toJson(),
      'photos': photos,
    };
  }
}
