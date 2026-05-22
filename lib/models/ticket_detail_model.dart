class TicketDetailResponse {
  final bool success;
  final String message;
  final TicketData data;

  TicketDetailResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory TicketDetailResponse.fromJson(Map<String, dynamic> json) {
    return TicketDetailResponse(
      success: json['success'],
      message: json['message'],
      data: TicketData.fromJson(json['data']),
    );
  }
}

class TicketData {
  final Ticket ticket;
  final Subscription? subscription;

  TicketData({required this.ticket, this.subscription});

  factory TicketData.fromJson(Map<String, dynamic> json) {
    return TicketData(
      ticket: Ticket.fromJson(json['ticket']),
      subscription: json['subscription'] != null
          ? Subscription.fromJson(json['subscription'])
          : null,
    );
  }
}

class Ticket {
  final int id;
  final String ticketNumber;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String issueType;
  final String? noLayanan;

  final Customer? customer;
  final Creator? creator;

  final List<Assignment> assignments;

  Ticket({
    required this.id,
    required this.ticketNumber,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.issueType,
    this.noLayanan,
    this.customer,
    this.creator,
    required this.assignments,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      ticketNumber: json['ticket_number'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      priority: json['priority'] ?? '',
      issueType: json['issue_type'] ?? '',
      noLayanan: json['no_layanan'],
      customer: json['customer'] != null
          ? Customer.fromJson(json['customer'])
          : null,
      creator: json['creator'] != null
          ? Creator.fromJson(json['creator'])
          : null,
      assignments: (json['assignments'] as List<dynamic>? ?? [])
          .map((e) => Assignment.fromJson(e))
          .toList(),
    );
  }
}

class Customer {
  final int id;
  final String name;
  final String phone;
  final String address;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
    );
  }
}

class Creator {
  final int id;
  final String name;
  final String email;

  Creator({required this.id, required this.name, required this.email});

  factory Creator.fromJson(Map<String, dynamic> json) {
    return Creator(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class Assignment {
  final int id;
  final String status;
  final String? notes;
  final AssignmentUser? user;

  Assignment({required this.id, required this.status, this.notes, this.user});

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'],
      status: json['status'] ?? '',
      notes: json['notes'],
      user: json['user'] != null ? AssignmentUser.fromJson(json['user']) : null,
    );
  }
}

class AssignmentUser {
  final int id;
  final String name;
  final String phone;

  AssignmentUser({required this.id, required this.name, required this.phone});

  factory AssignmentUser.fromJson(Map<String, dynamic> json) {
    return AssignmentUser(
      id: json['id'],
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class Subscription {
  final int id;
  final String noLayanan;
  final String status;
  final String category;

  final Package? package;
  final Router? router;
  final Area? area;
  final Mitra? mitra;

  Subscription({
    required this.id,
    required this.noLayanan,
    required this.status,
    required this.category,
    this.package,
    this.router,
    this.area,
    this.mitra,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      noLayanan: json['no_layanan'] ?? '',
      status: json['status'] ?? '',
      category: json['category'] ?? '',
      package: json['package'] != null
          ? Package.fromJson(json['package'])
          : null,
      router: json['router'] != null ? Router.fromJson(json['router']) : null,
      area: json['area'] != null ? Area.fromJson(json['area']) : null,
      mitra: json['mitra'] != null ? Mitra.fromJson(json['mitra']) : null,
    );
  }
}

class Package {
  final String name;
  final String rateLimit;
  final String price;

  Package({required this.name, required this.rateLimit, required this.price});

  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      name: json['name'] ?? '',
      rateLimit: json['rate_limit'] ?? '',
      price: json['price'] ?? '',
    );
  }
}

class Router {
  final String namaRouter;
  final String ipAddress;

  Router({required this.namaRouter, required this.ipAddress});

  factory Router.fromJson(Map<String, dynamic> json) {
    return Router(
      namaRouter: json['nama_router'] ?? '',
      ipAddress: json['ip_address'] ?? '',
    );
  }
}

class Area {
  final String name;
  final String city;
  final String province;

  Area({required this.name, required this.city, required this.province});

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      province: json['province'] ?? '',
    );
  }
}

class Mitra {
  final String name;
  final String phone;

  Mitra({required this.name, required this.phone});

  factory Mitra.fromJson(Map<String, dynamic> json) {
    return Mitra(name: json['name'] ?? '', phone: json['phone'] ?? '');
  }
}
