import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/fcm_service.dart';
import '../services/user_service.dart';

class NotificationProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  
  // إعدادات الإشعارات
  // ignore: prefer_final_fields
  Map<String, bool> _settingsMap = {};
  
  // معرف المستخدم الحالي
  String? _currentUserId;
  
  // تاريخ تسجيل المستخدم
  DateTime? _userRegistrationDate;
  
  // Stream subscription
  StreamSubscription<List<NotificationModel>>? _notificationsSubscription;
  
  // FCM Token
  String? _fcmToken;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  Map<String, bool> get settingsMap => _settingsMap;
  String? get currentUserId => _currentUserId;
  String? get fcmToken => _fcmToken;

  // تهيئة Provider
  Future<void> initialize() async {
    _setLoading(true);
    _clearError();

    try {
      _currentUserId = Supabase.instance.client.auth.currentUser?.id;
      
      if (_currentUserId == null) {
        _setError('يجب تسجيل الدخول أولاً');
        return;
      }
      
      // الحصول على تاريخ تسجيل المستخدم
      await _loadUserRegistrationDate();
      
      // تهيئة الإشعارات المحلية
      await NotificationService.initializeLocalNotifications();
      
      // الحصول على FCM Token
      _fcmToken = FCMService.fcmToken;
      
      // تحميل الإعدادات
      await _loadNotificationSettings();
      
      // تحميل الإشعارات مباشرة
      await _loadNotificationsDirect();
      
      // بدء الاستماع للإشعارات
      _startListeningToNotifications();
      
    } catch (e) {
      _setError('خطأ في تهيئة الإشعارات: $e');
    } finally {
      _setLoading(false);
    }
  }

  // تحميل إعدادات الإشعارات
  Future<void> _loadNotificationSettings() async {
    if (_currentUserId == null) return;
    
    try {
      final settings = await NotificationService.getNotificationSettings(_currentUserId!);
      
      // تحويل إلى Map للوصول السريع
      _settingsMap.clear();
      for (var setting in settings) {
        _settingsMap[setting.notificationType] = setting.isEnabled;
      }
      
      // إضافة الإعدادات الافتراضية
      _addDefaultSettings();
      
      notifyListeners();
    // ignore: empty_catches
    } catch (e) {
    }
  }

  // إضافة الإعدادات الافتراضية
  void _addDefaultSettings() {
    final defaultTypes = ['order_confirmed', 'order_updated', 'order_delivered', 'promotion'];
    
    for (String type in defaultTypes) {
      if (!_settingsMap.containsKey(type)) {
        _settingsMap[type] = true; // مفعل افتراضياً
      }
    }
  }

  // تحميل تاريخ تسجيل المستخدم
  Future<void> _loadUserRegistrationDate() async {
    if (_currentUserId == null) return;
    
    try {
      final userData = await UserService.getCurrentUser();
      if (userData != null && userData['created_at'] != null) {
        _userRegistrationDate = DateTime.parse(userData['created_at']);
      }
    // ignore: empty_catches
    } catch (e) {
    }
  }

  // تحميل الإشعارات مباشرة
  Future<void> _loadNotificationsDirect() async {
    if (_currentUserId == null) return;
    
    try {
      final notifications = await NotificationService.getCustomerNotificationsDirectFiltered(
        _currentUserId!, 
        _userRegistrationDate
      );
      _notifications = notifications;
      _updateUnreadCount();
      notifyListeners();
    // ignore: empty_catches
    } catch (e) {
    }
  }

  // إرسال إشعارات في الستارة للإشعارات الجديدة
  void _sendSystemNotificationsForNewNotifications(List<NotificationModel> newNotifications) {
    if (_notifications.isEmpty) return; // أول تحميل - لا نرسل إشعارات

    // العثور على الإشعارات الجديدة
    final existingIds = _notifications.map((n) => n.id).toSet();
    final newNotificationsList = newNotifications.where((n) => !existingIds.contains(n.id)).toList();

    // إرسال إشعار في الستارة لكل إشعار جديد
    for (final notification in newNotificationsList) {
      if (isNotificationTypeEnabled(notification.type)) {
        _sendSystemNotification(notification);
      }
    }
  }

  // إرسال إشعار في الستارة
  void _sendSystemNotification(NotificationModel notification) {
    try {
      NotificationService.showLocalNotification(
        id: notification.id.hashCode,
        title: notification.title,
        body: notification.message,
        payload: notification.data?.toString(),
      );
    // ignore: empty_catches
    } catch (e) {
    }
  }

  // بدء الاستماع للإشعارات
  void _startListeningToNotifications() {
    if (_currentUserId == null) return;
    
    // إلغاء الاشتراك السابق
    _notificationsSubscription?.cancel();
    
    // الاستماع للإشعارات مع الفلترة
    _notificationsSubscription = NotificationService.getCustomerNotificationsFiltered(
      _currentUserId!, 
      _userRegistrationDate
    ).listen(
      (notifications) {
        // إرسال إشعار في الستارة للإشعارات الجديدة
        _sendSystemNotificationsForNewNotifications(notifications);
        
        _notifications = notifications;
        _updateUnreadCount();
        notifyListeners();
      },
      onError: (error) {
        _setError('خطأ في تحميل الإشعارات');
      },
    );
  }

  // تحديث عدد الإشعارات غير المقروءة
  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  // تعيين إشعار كمقروء
  Future<bool> markAsRead(String notificationId) async {
    try {
      final success = await NotificationService.markAsRead(notificationId);
      if (success) {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
          _updateUnreadCount();
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  // تعيين جميع الإشعارات كمقروءة
  Future<bool> markAllAsRead() async {
    if (_currentUserId == null) return false;
    
    try {
      final success = await NotificationService.markAllAsRead(_currentUserId!);
      if (success) {
        for (int i = 0; i < _notifications.length; i++) {
          if (!_notifications[i].isRead) {
            _notifications[i] = _notifications[i].copyWith(
              isRead: true,
              readAt: DateTime.now(),
            );
          }
        }
        _updateUnreadCount();
        notifyListeners();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  // حذف إشعار
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final success = await NotificationService.deleteNotification(notificationId);
      if (success) {
        _notifications.removeWhere((n) => n.id == notificationId);
        _updateUnreadCount();
        notifyListeners();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  // تحديث إعداد الإشعار
  Future<bool> updateNotificationSetting({
    required String notificationType,
    required bool isEnabled,
  }) async {
    if (_currentUserId == null) return false;
    
    try {
      final success = await NotificationService.updateNotificationSetting(
        userId: _currentUserId!,
        notificationType: notificationType,
        isEnabled: isEnabled,
      );
      
      if (success) {
        _settingsMap[notificationType] = isEnabled;
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }

  // التحقق من تفعيل نوع إشعار
  bool isNotificationTypeEnabled(String notificationType) {
    return _settingsMap[notificationType] ?? true;
  }

  // ملاحظة: في النظام الجديد، الإشعارات يتم إنشاؤها وإرسالها من لوحة التحكم فقط
  // تطبيق العميل يستقبل ويعرض الإشعارات فقط

  // تحديث البيانات
  Future<void> refreshNotifications() async {
    _setLoading(true);
    _clearError();

    try {
      await _loadNotificationSettings();
      await _loadNotificationsDirect();
    } catch (e) {
      _setError('خطأ في تحديث الإشعارات: $e');
    } finally {
      _setLoading(false);
    }
  }

  // تحديث الإشعارات عند وصول إشعار جديد من FCM
  Future<void> refreshNotificationsFromFCM() async {
    if (_currentUserId == null) return;
    
    try {
      await _loadNotificationsDirect();
    // ignore: empty_catches
    } catch (e) {
    }
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // تحديث معرف المستخدم
  void updateCurrentUserId(String? userId) {
    _currentUserId = userId;
    if (userId != null) {
      initialize();
    } else {
      _notifications.clear();
      _unreadCount = 0;
      _settingsMap.clear();
      notifyListeners();
    }
  }

  // تنظيف الموارد
  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }
}
