import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة إدارة حالة تسجيل الدخول كضيف
class GuestService {
  static const String _guestModeKey = 'is_guest_mode';
  static const String _guestCartKey = 'guest_cart_items';
  
  /// التحقق من تسجيل الدخول كضيف
  static Future<bool> isGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_guestModeKey) ?? false;
    } catch (e) {
      return false;
    }
  }
  
  /// تفعيل وضع الضيف
  static Future<void> enableGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_guestModeKey, true);
    } catch (e) {
      throw Exception('فشل في تفعيل وضع الضيف');
    }
  }
  
  /// إلغاء وضع الضيف
  static Future<void> disableGuestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_guestModeKey, false);
      // لا نحذف السلة هنا - سيتم نقلها عند تسجيل الدخول
    } catch (e) {
      throw Exception('فشل في إلغاء وضع الضيف');
    }
  }
  
  /// عرض رسالة تنبيه للضيف
  static String getGuestModeWarning() {
    return 'يجب عليك تسجيل الدخول للوصول إلى هذه الميزة';
  }
  
  /// حفظ سلة الضيف محلياً
  static Future<void> saveGuestCart(List<Map<String, dynamic>> cartItems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = jsonEncode(cartItems);
      await prefs.setString(_guestCartKey, cartJson);
    } catch (e) {
      // تجاهل الخطأ - السلة ستبقى في الذاكرة
    }
  }
  
  /// تحميل سلة الضيف من التخزين المحلي
  static Future<List<Map<String, dynamic>>> loadGuestCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_guestCartKey);
      if (cartJson != null && cartJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(cartJson);
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  
  /// مسح سلة الضيف
  static Future<void> clearGuestCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_guestCartKey);
    } catch (e) {
      // تجاهل الخطأ
    }
  }
}
