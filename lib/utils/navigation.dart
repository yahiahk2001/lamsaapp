import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/customer/auth/login_screen.dart';
import '../screens/customer/auth/welcome_screen.dart';
import '../screens/customer/home/home_screen.dart';
import '../screens/customer/product/product_details_screen.dart';
import '../screens/customer/cart/cart_screen.dart';
import '../screens/customer/location/location_screen.dart';
import '../screens/customer/order/order_confirmation_screen.dart';
import '../screens/customer/orders/orders_screen.dart' as customer;
import '../screens/customer/profile/profile_screen.dart';
import '../screens/customer/support/support_screen.dart';
import '../screens/customer/about_us_screen.dart';
import '../screens/customer/developer_screen.dart';


class AppNavigation {
  // Customer Routes
  static const String login = '/login';
  static const String welcome = '/welcome';
  static const String home = '/home';
  static const String productDetails = '/product-details';
  static const String cart = '/cart';
  static const String location = '/location';
  static const String orderConfirmation = '/order-confirmation';
  static const String orders = '/orders';
  static const String profile = '/profile';
  static const String support = '/support';
  static const String aboutUs = '/about-us';
  static const String developer = '/developer';

  

  // Helper methods for navigation
  static void navigateToHome(BuildContext context, {int initialTabIndex = 0}) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      home,
      (route) => false,
      arguments: {'initialTabIndex': initialTabIndex},
    );
  }

  static void navigateToCart(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CartContent()),
    );
  }

  static void navigateToOrders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => customer.OrdersContent()),
    );
  }

  static void navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen()),
    );
  }

  static void navigateToSupport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SupportScreen()),
    );
  }

  static void navigateToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      login,
      (route) => false,
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (_) => LoginScreen(),
        );
      case welcome:
        final args = settings.arguments as Map<String, dynamic>?;
        final supabaseUser = args?['supabaseUser'] as User?;
        final googleUserName = args?['googleUserName'] as String?;
        final googleUserEmail = args?['googleUserEmail'] as String?;
        
        if (supabaseUser == null) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(
                child: Text('خطأ: لم يتم تحديد المستخدم'),
              ),
            ),
          );
        }
        
        return MaterialPageRoute(
          builder: (_) => WelcomeScreen(
            supabaseUser: supabaseUser,
            googleUserName: googleUserName,
            googleUserEmail: googleUserEmail,
          ),
        );
      case home:
        final args = settings.arguments as Map<String, dynamic>?;
        final initialTabIndex = args?['initialTabIndex'] as int? ?? 0;
        return MaterialPageRoute(
          builder: (_) => HomeScreen(initialTabIndex: initialTabIndex),
        );
      case productDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        final product = args?['product'];
        if (product == null) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(
                child: Text('خطأ: لم يتم تحديد المنتج'),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(product: product),
        );
      case cart:
        return MaterialPageRoute(
          builder: (_) => CartContent(),
        );
      case location:
        return MaterialPageRoute(
          builder: (_) => LocationScreen(),
        );
      case orderConfirmation:
        final args = settings.arguments as Map<String, dynamic>?;
        final latitude = args?['latitude'] as double?;
        final longitude = args?['longitude'] as double?;
        final address = args?['address'] as String?;
        if (latitude == null || longitude == null || address == null) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(
                child: Text('خطأ: لم يتم تحديد معلومات الموقع'),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(
            latitude: latitude,
            longitude: longitude,
            address: address,
          ),
        );
      
      
      case support:
        return MaterialPageRoute(
          builder: (_) => SupportScreen(),
        );
      
      case aboutUs:
        return MaterialPageRoute(
          builder: (_) => AboutUsScreen(),
        );
      
      case developer:
        return MaterialPageRoute(
          builder: (_) => DeveloperScreen(),
        );
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('الصفحة غير موجودة'),
            ),
          ),
        );
    }
  }
}
