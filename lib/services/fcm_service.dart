// ignore_for_file: empty_catches

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  static String? _fcmToken;
  static String? get fcmToken => _fcmToken;
  
  // مرجع إلى NotificationProvider لتحديث الإشعارات
  static dynamic _notificationProvider;
  
  // تحديد مرجع NotificationProvider
  static void setNotificationProvider(dynamic provider) {
    _notificationProvider = provider;
  }

  // تهيئة FCM
  static Future<void> initialize() async {
    try {
      // تهيئة Firebase
      await Firebase.initializeApp();
      print('Firebase initialized successfully');
      
      // طلب إذن الإشعارات
      await _requestPermission();
      
      // الحصول على FCM Token
      await _getFCMToken();
      
      // إعداد معالجات الإشعارات
      _setupMessageHandlers();
      
    } catch (e) {
      print('FCM initialization error: $e');
      // إعادة المحاولة بعد 5 ثوان
      await Future.delayed(Duration(seconds: 5));
      try {
        await _getFCMToken();
      } catch (retryError) {
        print('FCM retry failed: $retryError');
      }
    }
  }

  // طلب إذن الإشعارات
  static Future<void> _requestPermission() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      print('FCM Permission status: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('FCM permission granted');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('FCM provisional permission granted');
      } else {
        print('FCM permission denied');
      }
    } catch (e) {
      print('FCM permission error: $e');
    }
  }

  // الحصول على FCM Token
  static Future<void> _getFCMToken() async {
    try {
      // التحقق من الاتصال بالإنترنت أولاً
      final settings = await _messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _fcmToken = await _messaging.getToken();
        print('FCM Token obtained: ${_fcmToken?.substring(0, 20)}...');
        
        // حفظ Token في قاعدة البيانات
        await _saveFCMTokenToDatabase();
      } else {
        print('FCM authorization not granted');
      }
    } catch (e) {
      print('FCM Token error: $e');
      // إعادة المحاولة بعد 10 ثوان
      await Future.delayed(Duration(seconds: 10));
      try {
        _fcmToken = await _messaging.getToken();
        print('FCM Token retry successful: ${_fcmToken?.substring(0, 20)}...');
      } catch (retryError) {
        print('FCM Token retry failed: $retryError');
      }
    }
  }

  // حفظ FCM Token في قاعدة البيانات
  static Future<void> _saveFCMTokenToDatabase() async {
    if (_fcmToken == null) return;
    
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return;
      }

      // استخدام خدمة الإشعارات لتسجيل الـ token
      final success = await NotificationService.registerFCMToken(
        userId: userId,
        fcmToken: _fcmToken!,
        platform: 'android',
      );

      if (success) {
      } else {
      }
    } catch (e) {
    }
  }

  // إعداد معالجات الإشعارات
  static void _setupMessageHandlers() {
    // معالج الإشعارات في المقدمة
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // معالج الإشعارات عند النقر عليها
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    
    // معالج الإشعارات عند فتح التطبيق من إشعار
    _handleInitialMessage();
  }

  // معالج الإشعارات في المقدمة
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    
    // حفظ الإشعار في قاعدة البيانات
    await _saveNotificationToDatabase(message);
    
    // عرض إشعار محلي
    await _showLocalNotification(message);
  }

  // معالج الإشعارات عند النقر عليها
  static Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    
    // حفظ الإشعار في قاعدة البيانات
    await _saveNotificationToDatabase(message);
    
    // يمكن إضافة منطق للانتقال إلى صفحة معينة
    _handleNotificationNavigation(message);
  }

  // معالج الإشعارات عند فتح التطبيق من إشعار
  static Future<void> _handleInitialMessage() async {
    try {
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        await _saveNotificationToDatabase(initialMessage);
        _handleNotificationNavigation(initialMessage);
      }
    } catch (e) {
    }
  }

  // حفظ الإشعار في قاعدة البيانات (محدود للعميل)
  static Future<void> _saveNotificationToDatabase(RemoteMessage message) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      if (userId == null) {
        return;
      }

      // الإشعارات المرسلة من لوحة التحكم تحتوي على البيانات مسبقاً
      // لا نحتاج لحفظها مرة أخرى في قاعدة البيانات
      
      // تحديث NotificationProvider إذا كان متاحاً
      if (_notificationProvider != null) {
        try {
          await _notificationProvider.refreshNotificationsFromFCM();
        } catch (e) {
        }
      }
    } catch (e) {
    }
  }

  // عرض إشعار محلي
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      await NotificationService.showLocalNotification(
        id: message.hashCode,
        title: message.notification?.title ?? 'إشعار جديد',
        body: message.notification?.body ?? '',
        payload: message.data.toString(),
      );
    } catch (e) {
    }
  }

  // معالج التنقل عند النقر على الإشعار
  static void _handleNotificationNavigation(RemoteMessage message) {
    final data = message.data;
    
    if (data['type'] == 'order_updated' && data['order_id'] != null) {
    } else if (data['type'] == 'promotion') {
    }
  }

  // تحديث FCM Token
  static Future<void> refreshToken() async {
    try {
      await _getFCMToken();
    } catch (e) {
    }
  }


  // حذف FCM Token من قاعدة البيانات
  static Future<void> deleteFCMToken() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // استخدام خدمة الإشعارات لحذف الـ token
      final success = await NotificationService.removeFCMToken(
        userId: userId,
        fcmToken: _fcmToken,
      );

      if (success) {
      } else {
      }
    } catch (e) {
    }
  }

  // تحديث FCM Token عند تسجيل الدخول
  static Future<void> updateTokenForUser(String userId) async {
    if (_fcmToken == null) {
      await _getFCMToken();
    }
    
    if (_fcmToken != null) {
      final success = await NotificationService.registerFCMToken(
        userId: userId,
        fcmToken: _fcmToken!,
        platform: 'android',
      );
      
      if (success) {
      } else {
      }
    }
  }
}

// معالج الإشعارات في الخلفية (يجب أن يكون في مستوى أعلى)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  
  // معالجة الإشعار (بدون حفظ مضاعف)
}


