class TicketModel {
  final int id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String createdAt;
  final String? updatedAt;
  final String customerName;
  final String? category;
  final List<String> photos;

  TicketModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.updatedAt,
    required this.customerName,
    this.category,
    this.photos = const [],
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'normal',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'],
      customerName: json['customer_name'] ?? 'Unknown Customer',
      category: json['category'],
      photos: json['photos'] != null ? List<String>.from(json['photos']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'customer_name': customerName,
      'category': category,
      'photos': photos,
    };
  }
}
