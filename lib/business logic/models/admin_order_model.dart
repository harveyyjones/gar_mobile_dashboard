import 'package:cloud_firestore/cloud_firestore.dart';

class OrderStatistics {
  final int total;
  final Map<String, int> statusCounts;
  final double totalRevenue;

  OrderStatistics({
    required this.total,
    required this.statusCounts,
    required this.totalRevenue,
  });

  int getStatusCount(String status) {
    return statusCounts[status] ?? 0;
  }
}

class AdminOrder {
  final String id;
  final String status;
  final DateTime createdAt;
  final List<OrderItem> items;
  final double total;
  final CustomerInfo customerInfo;
  final DeliveryAddress deliveryAddress;
  final List<StatusHistory> statusHistory;

  AdminOrder({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.items,
    required this.total,
    required this.customerInfo,
    required this.deliveryAddress,
    required this.statusHistory,
  });

  factory AdminOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AdminOrder(
      id: doc.id,
      status: data['status'] ?? 'pending',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item))
              .toList() ??
          [],
      total: (data['total'] ?? 0.0).toDouble(),
      customerInfo: CustomerInfo.fromMap(data['user_data'] ?? {}),
      deliveryAddress: DeliveryAddress.fromMap(data['delivery_address'] ?? {}),
      statusHistory: (data['statusHistory'] as List<dynamic>?)
              ?.map((status) => StatusHistory.fromMap(status))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'user_data': customerInfo.toMap(),
      'delivery_address': deliveryAddress.toMap(),
      'statusHistory': statusHistory.map((status) => status.toMap()).toList(),
    };
  }
}

class OrderItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String currency;
  final String image;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.currency,
    required this.image,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['product_id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 0,
      currency: map['currency'] ?? '',
      image: map['image'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'currency': currency,
      'image': image,
    };
  }
}

class CustomerInfo {
  final String name;
  final String email;
  final String phone;
  final String companyName;

  CustomerInfo({
    required this.name,
    required this.email,
    required this.phone,
    required this.companyName,
  });

  factory CustomerInfo.fromMap(Map<String, dynamic> map) {
    return CustomerInfo(
      name: map['contact_name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      companyName: map['company_name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contact_name': name,
      'email': email,
      'phone': phone,
      'company_name': companyName,
    };
  }
}

class DeliveryAddress {
  final String name;
  final String address;
  final String city;
  final String country;
  final String zip;
  final String phone;

  DeliveryAddress({
    required this.name,
    required this.address,
    required this.city,
    required this.country,
    required this.zip,
    required this.phone,
  });

  factory DeliveryAddress.fromMap(Map<String, dynamic> map) {
    return DeliveryAddress(
      name: map['name'] ?? '',
      address: map['adress'] ?? '',
      city: map['city'] ?? '',
      country: map['country'] ?? '',
      zip: map['zip'] ?? '',
      phone: map['phone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'adress': address,
      'city': city,
      'country': country,
      'zip': zip,
      'phone': phone,
    };
  }
}

class StatusHistory {
  final String status;
  final DateTime timestamp;
  final String note;

  StatusHistory({
    required this.status,
    required this.timestamp,
    required this.note,
  });

  factory StatusHistory.fromMap(Map<String, dynamic> map) {
    return StatusHistory(
      status: map['status'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: map['note'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'note': note,
    };
  }
}
