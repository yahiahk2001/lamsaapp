class CategoryModel {
  final String id;
  final String name;
  final String? imageUrl;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
  });

  // Constructor for creating new categories (without ID)
  CategoryModel.create({
    required this.name,
    this.imageUrl,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
  }) : id = ''; // Empty ID for new categories

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image_url'],
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'is_active': isActive,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
