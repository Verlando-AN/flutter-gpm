class TeknisiModel {
  final int id;
  final String name;
  final String email;
  final String username;
  final String phone;
  final String identityNo;
  final String address;
  final String joinDate;
  final String? lastLoginAt;
  final int roleId;

  TeknisiModel({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.phone,
    required this.identityNo,
    required this.address,
    required this.joinDate,
    required this.lastLoginAt,
    required this.roleId,
  });

  factory TeknisiModel.fromJson(Map<String, dynamic> json) {
    return TeknisiModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      phone: json['phone'] ?? '',
      identityNo: json['identity_no'] ?? '',
      address: json['address'] ?? '',
      joinDate: json['join_date'] ?? '',
      lastLoginAt: json['last_login_at'],
      roleId: json['role_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'phone': phone,
      'identity_no': identityNo,
      'address': address,
      'join_date': joinDate,
      'last_login_at': lastLoginAt,
      'role_id': roleId,
    };
  }
}