// ignore_for_file: empty_catches

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // تهيئة الإشعارات المحلية
  static Future<void> initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      await _requestNotificationPermission();
    } catch (e) {
    }
  }

  // طلب إذن الإشعارات
  static Future<bool> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // معالج النقر على الإشعار
  static void _onNotificationTapped(NotificationResponse response) {
  }

  // ==========================================
  // الإشعارات الداخلية (Supabase Realtime)
  // ==========================================

  // الحصول على إشعارات العميل (broadcast + targeted)
  static Stream<List<NotificationModel>> getCustomerNotifications(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((json) => 
                (json['type'] == 'broadcast') || 
                (json['target_user_id'] == userId))
            .map((json) => NotificationModel.fromJson(json))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  // الحصول على إشعارات العميل مع فلترة التاريخ (broadcast + targeted)
  static Stream<List<NotificationModel>> getCustomerNotificationsFiltered(
      String userId, DateTime? userRegistrationDate) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((json) => 
                (json['type'] == 'broadcast') || 
                (json['target_user_id'] == userId))
            .map((json) => NotificationModel.fromJson(json))
            .where((notification) {
              // إذا لم يكن لدينا تاريخ التسجيل، نعرض جميع الإشعارات
              if (userRegistrationDate == null) return true;
              
              // فلترة الإشعارات: عرض الإشعارات التي تم إنشاؤها بعد تسجيل المستخدم أو في نفس اليوم
              return notification.createdAt.isAfter(userRegistrationDate) ||
                     _isSameDay(notification.createdAt, userRegistrationDate);
            })
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  // الحصول على إشعارات العميل مباشرة (broadcast + targeted)
  static Future<List<NotificationModel>> getCustomerNotificationsDirect(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .or('type.eq.broadcast,target_user_id.eq.$userId')
          .order('created_at', ascending: false);

      return response.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // الحصول على إشعارات العميل مباشرة مع فلترة التاريخ (broadcast + targeted)
  static Future<List<NotificationModel>> getCustomerNotificationsDirectFiltered(
      String userId, DateTime? userRegistrationDate) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .or('type.eq.broadcast,target_user_id.eq.$userId')
          .order('created_at', ascending: false);

      final notifications = response.map((json) => NotificationModel.fromJson(json)).toList();
      
      // فلترة الإشعارات حسب تاريخ التسجيل
      if (userRegistrationDate == null) {
        return notifications;
      }
      
      return notifications.where((notification) {
        // عرض الإشعارات التي تم إنشاؤها بعد تسجيل المستخدم أو في نفس اليوم
        return notification.createdAt.isAfter(userRegistrationDate) ||
               _isSameDay(notification.createdAt, userRegistrationDate);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // عد الإشعارات غير المقروءة (broadcast + targeted)
  static Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .or('type.eq.broadcast,target_user_id.eq.$userId')
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      return 0;
    }
  }

  // عد الإشعارات غير المقروءة مع فلترة التاريخ (broadcast + targeted)
  static Future<int> getUnreadCountFiltered(String userId, DateTime? userRegistrationDate) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('id, created_at')
          .or('type.eq.broadcast,target_user_id.eq.$userId')
          .eq('is_read', false);

      // فلترة الإشعارات حسب تاريخ التسجيل
      if (userRegistrationDate == null) {
        return response.length;
      }

      int count = 0;
      for (final notificationData in response) {
        final createdAt = DateTime.parse(notificationData['created_at']);
        if (createdAt.isAfter(userRegistrationDate) ||
            _isSameDay(createdAt, userRegistrationDate)) {
          count++;
        }
      }

      return count;
    } catch (e) {
      return 0;
    }
  }

  // تعيين الإشعار كمقروء
  static Future<bool> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // تعيين جميع الإشعارات كمقروءة (broadcast + targeted)
  static Future<bool> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .or('type.eq.broadcast,target_user_id.eq.$userId')
          .eq('is_read', false);
      return true;
    } catch (e) {
      return false;
    }
  }

  // حذف الإشعار
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // إنشاء الإشعارات (مبسط للعميل)
  // ==========================================

  // تم إزالة دالة createNotification - الإشعارات تُنشأ من لوحة التحكم فقط

  // ملاحظة: في النظام الجديد، الإشعارات يتم إنشاؤها وإرسالها من لوحة التحكم فقط
  // تطبيق العميل يستقبل ويعرض الإشعارات فقط


  // ==========================================
  // الإشعارات المحلية (Local Notifications)
  // ==========================================

  // عرض إشعار محلي
  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'customer_notifications',
        'إشعارات التطبيق',
        channelDescription: 'إشعارات طلباتك وتحديثات التطبيق',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id,
        title,
        body,
        platformDetails,
        payload: payload,
      );
      
    } catch (e) {
    }
  }

  // ==========================================
  // إعدادات الإشعارات (مبسطة)
  // ==========================================

  // الحصول على إعدادات الإشعارات
  static Future<List<NotificationSettingsModel>> getNotificationSettings(String userId) async {
    try {
      final response = await _supabase
          .from('notification_settings')
          .select()
          .eq('user_type', 'customer')
          .eq('user_id', userId)
          .order('notification_type');

      return response.map((json) => NotificationSettingsModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // تحديث إعداد الإشعار
  static Future<bool> updateNotificationSetting({
    required String userId,
    required String notificationType,
    required bool isEnabled,
  }) async {
    try {
      await _supabase
          .from('notification_settings')
          .upsert({
            'user_id': userId,
            'user_type': 'customer',
            'notification_type': notificationType,
            'is_enabled': isEnabled,
          });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // FCM Token Management
  // ==========================================

  // تسجيل FCM token للمستخدم
  static Future<bool> registerFCMToken({
    required String userId,
    required String fcmToken,
    String platform = 'android',
  }) async {
    try {
      await _supabase
          .from('user_fcm_tokens')
          .upsert({
            'user_id': userId,
            'fcm_token': fcmToken,
            'platform': platform,
            'updated_at': DateTime.now().toIso8601String(),
          });
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // حذف FCM token للمستخدم
  static Future<bool> removeFCMToken({
    required String userId,
    String? fcmToken,
  }) async {
    try {
      var query = _supabase
          .from('user_fcm_tokens')
          .delete()
          .eq('user_id', userId);
      
      if (fcmToken != null) {
        query = query.eq('fcm_token', fcmToken);
      }
      
      await query;
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // دوال مساعدة
  // ==========================================

  // التحقق من تطابق تاريخين في نفس اليوم
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
}
