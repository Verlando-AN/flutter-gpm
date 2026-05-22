class ActivityLogModel {
  final int id;
  final int userId;
  final String name;
  final String ipAddress;
  final String activity;
  final String createdAt;

  ActivityLogModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.ipAddress,
    required this.activity,
    required this.createdAt,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      ipAddress: json['ip_address'] ?? '',
      activity: json['activity'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}
