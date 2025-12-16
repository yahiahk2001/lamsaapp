class ProductModel {
  final String id;
  final String? categoryId;
  final String name;
  final String? description;
  final double price;
  final double? cartonPrice; // سعر الكارتون (اختياري)
  final String? imageUrl1;
  final String? imageUrl2;
  final String? imageUrl3;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.cartonPrice,
    this.imageUrl1,
    this.imageUrl2,
    this.imageUrl3,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  // Constructor for creating new products (without ID)
  ProductModel.create({
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.cartonPrice,
    this.imageUrl1,
    this.imageUrl2,
    this.imageUrl3,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  }) : id = ''; // Empty ID for new products

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      categoryId: json['category_id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] is int) ? json['price'].toDouble() : json['price'],
      cartonPrice: json['carton_price'] != null 
          ? ((json['carton_price'] is int) ? json['carton_price'].toDouble() : json['carton_price'])
          : null,
      imageUrl1: json['image_url_1'],
      imageUrl2: json['image_url_2'],
      imageUrl3: json['image_url_3'],
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'carton_price': cartonPrice,
      'image_url_1': imageUrl1,
      'image_url_2': imageUrl2,
      'image_url_3': imageUrl3,
      'is_active': isActive,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Getter للحصول على جميع الصور كقائمة
  List<String> get images {
    final List<String> imageList = [];
    if (imageUrl1 != null && imageUrl1!.isNotEmpty) imageList.add(imageUrl1!);
    if (imageUrl2 != null && imageUrl2!.isNotEmpty) imageList.add(imageUrl2!);
    if (imageUrl3 != null && imageUrl3!.isNotEmpty) imageList.add(imageUrl3!);
    return imageList;
  }

  // Getter للحصول على الصورة الرئيسية
  String? get mainImage => imageUrl1 ?? imageUrl2 ?? imageUrl3;

  ProductModel copyWith({
    String? id,
    String? categoryId,
    String? name,
    String? description,
    double? price,
    double? cartonPrice,
    String? imageUrl1,
    String? imageUrl2,
    String? imageUrl3,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      cartonPrice: cartonPrice ?? this.cartonPrice,
      imageUrl1: imageUrl1 ?? this.imageUrl1,
      imageUrl2: imageUrl2 ?? this.imageUrl2,
      imageUrl3: imageUrl3 ?? this.imageUrl3,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
