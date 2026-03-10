import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/splash_screen.dart';
import 'providers/home_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/notification_provider.dart';
import 'services/fcm_service.dart';
import 'services/cart_service.dart';
import 'utils/supabase_config.dart';
import 'utils/navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // إعداد معالج الإشعارات في الخلفية
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // تشغيل التطبيق فوراً حتى يتاح منفذ VM Service (يُحل تعليق المحاكي)
  runApp(MyApp());

  // تهيئة FCM والسلة بعد أول إطار حتى لا تُحجب دورة Flutter
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initServicesInBackground();
  });
}

/// تهيئة الخدمات في الخلفية بعد ظهور أول إطار
void _initServicesInBackground() async {
  try {
    await FCMService.initialize();
    print('FCM Service initialized successfully');
  } catch (e) {
    print('FCM Service initialization failed: $e');
  }
  try {
    await CartService.initializeCart();
    print('Cart Service initialized successfully');
  } catch (e) {
    print('Cart Service initialization failed: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // تحديث معرف المستخدم في NotificationProvider عند تغيير حالة المصادقة
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final notificationProvider = context.read<NotificationProvider>();
            final currentUserId = authProvider.currentUser?.id;
            
            // تحديث معرف المستخدم في NotificationProvider
            if (notificationProvider.currentUserId != currentUserId) {
              notificationProvider.updateCurrentUserId(currentUserId);
            }
            
            // تحديد مرجع NotificationProvider في FCMService
            FCMService.setNotificationProvider(notificationProvider);
          });
          
          return MaterialApp(
            title: 'متجر الحلويات',
            theme: ThemeData(
              primarySwatch: Colors.pink,
              fontFamily: 'IBMPlexSansArabic',
              scaffoldBackgroundColor: Colors.white,
            ),
            home: SplashScreen(),
            onGenerateRoute: AppNavigation.generateRoute,
            debugShowCheckedModeBanner: false,
            // تعيين اتجاه التطبيق من اليمين لليسار
            builder: (context, child) {
              return SafeArea(child: 
              Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              ));
            },
          );
        },
      ),
    );
  }
}
