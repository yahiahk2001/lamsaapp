class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'broadcast', 'order_status', 'system', etc.
  final String? targetUserId; // للعميل المحدد (اختياري)
  final String targetType; // 'admin' أو 'customer'
  final bool isRead;
  final Map<String, dynamic>? data; // بيانات إضافية (مثل order_id)
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.targetUserId,
    required this.targetType,
    required this.isRead,
    this.data,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      targetUserId: json['target_user_id'],
      targetType: json['target_type'] ?? 'customer',
      isRead: json['is_read'] ?? false,
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      createdAt: DateTime.parse(json['created_at']),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'target_user_id': targetUserId,
      'target_type': targetType,
      'is_read': isRead,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? targetUserId,
    String? targetType,
    bool? isRead,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      targetUserId: targetUserId ?? this.targetUserId,
      targetType: targetType ?? this.targetType,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  // دالة للحصول على أيقونة الإشعار حسب النوع
  String get iconName {
    switch (type) {
      case 'order_status':
        return 'shopping_cart';
      case 'broadcast':
        return 'campaign';
      case 'system':
        return 'settings';
      case 'promotion':
        return 'local_offer';
      default:
        return 'notifications';
    }
  }

  // دالة للحصول على لون الإشعار حسب النوع
  String get colorHex {
    switch (type) {
      case 'order_status':
        return '#10B981'; // أخضر
      case 'broadcast':
        return '#3B82F6'; // أزرق
      case 'system':
        return '#6B7280'; // رمادي
      case 'promotion':
        return '#8B5CF6'; // بنفسجي
      default:
        return '#6366F1'; // أزرق افتراضي
    }
  }

  // دالة للحصول على النص المختصر للوقت
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}

// نموذج إعدادات الإشعارات
class NotificationSettingsModel {
  final String id;
  final String userId;
  final String userType; // 'admin' أو 'customer'
  final String notificationType;
  final bool isEnabled;
  final DateTime createdAt;

  NotificationSettingsModel({
    required this.id,
    required this.userId,
    required this.userType,
    required this.notificationType,
    required this.isEnabled,
    required this.createdAt,
  });

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      id: json['id'],
      userId: json['user_id'],
      userType: json['user_type'],
      notificationType: json['notification_type'],
      isEnabled: json['is_enabled'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_type': userType,
      'notification_type': notificationType,
      'is_enabled': isEnabled,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationSettingsModel copyWith({
    String? id,
    String? userId,
    String? userType,
    String? notificationType,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return NotificationSettingsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      notificationType: notificationType ?? this.notificationType,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
