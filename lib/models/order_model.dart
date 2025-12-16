class OrderModel {
  final String id;
  final String? userId;
  final String customerName;
  final String customerPhone;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? deliveryAddress;
  final String? notes;
  final String status; // 'processing', 'delivering', 'delivered', 'cancelled'
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.id,
    this.userId,
    required this.customerName,
    required this.customerPhone,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.deliveryAddress,
    this.notes,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      userId: json['user_id'],
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      deliveryLatitude: json['delivery_latitude']?.toDouble(),
      deliveryLongitude: json['delivery_longitude']?.toDouble(),
      deliveryAddress: json['delivery_address'],
      notes: json['notes'],
      status: json['status'],
      totalAmount: (json['total_amount'] is int) ? json['total_amount'].toDouble() : json['total_amount'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'user_id': (userId?.isEmpty ?? true) ? null : userId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'delivery_latitude': deliveryLatitude,
      'delivery_longitude': deliveryLongitude,
      'delivery_address': deliveryAddress,
      'notes': notes,
      'status': status,
      'total_amount': totalAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    
    // Only include id if it's not empty (for new orders, let database auto-generate)
    if (id.isNotEmpty) {
      data['id'] = id;
    }
    
    return data;
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    String? customerName,
    String? customerPhone,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? deliveryAddress,
    String? notes,
    String? status,
    double? totalAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final double productPrice;
  final int quantity;
  final String? notes;
  final double subtotal;
  final DateTime createdAt;
  final bool isCarton; // هل العنصر طلب كارتون أم قطعة

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.quantity,
    this.notes,
    required this.subtotal,
    required this.createdAt,
    this.isCarton = false,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      orderId: json['order_id'],
      productId: json['product_id'],
      productName: json['product_name'],
      productPrice: (json['product_price'] is int) ? json['product_price'].toDouble() : json['product_price'],
      quantity: json['quantity'],
      notes: json['notes'],
      subtotal: (json['subtotal'] is int) ? json['subtotal'].toDouble() : json['subtotal'],
      createdAt: DateTime.parse(json['created_at']),
      isCarton: json['is_carton'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'product_price': productPrice,
      'quantity': quantity,
      'notes': notes,
      'subtotal': subtotal,
      'created_at': createdAt.toIso8601String(),
      'is_carton': isCarton,
    };
  }

  OrderItemModel copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? productName,
    double? productPrice,
    int? quantity,
    String? notes,
    double? subtotal,
    DateTime? createdAt,
    bool? isCarton,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      subtotal: subtotal ?? this.subtotal,
      createdAt: createdAt ?? this.createdAt,
      isCarton: isCarton ?? this.isCarton,
    );
  }
}
