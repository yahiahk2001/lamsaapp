class AdvertisementModel {
  final String id;
  final String? title;
  final String imageUrl;
  final String? linkUrl;
  final bool isActive;
  final int sortOrder;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  AdvertisementModel({
    required this.id,
    this.title,
    required this.imageUrl,
    this.linkUrl,
    required this.isActive,
    required this.sortOrder,
    this.startDate,
    this.endDate,
    required this.createdAt,
  });

  factory AdvertisementModel.fromJson(Map<String, dynamic> json) {
    return AdvertisementModel(
      id: json['id'],
      title: json['title'],
      imageUrl: json['image_url'],
      linkUrl: json['link_url'],
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image_url': imageUrl,
      'link_url': linkUrl,
      'is_active': isActive,
      'sort_order': sortOrder,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // التحقق من أن الإعلان نشط في الوقت الحالي
  bool get isCurrentlyActive {
    if (!isActive) return false;
    
    final now = DateTime.now();
    
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    
    return true;
  }

  AdvertisementModel copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? linkUrl,
    bool? isActive,
    int? sortOrder,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
  }) {
    return AdvertisementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      linkUrl: linkUrl ?? this.linkUrl,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}





