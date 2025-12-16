import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_settings_model.dart';

class AppSettingsService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // جلب جميع إعدادات التطبيق
  static Future<List<AppSettingsModel>> getAllSettings() async {
    try {
      final response = await _supabase
          .from('app_settings')
          .select('*')
          .order('setting_key');

      return (response as List)
          .map((json) => AppSettingsModel.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // جلب إعداد محدد
  static Future<String?> getSetting(String settingKey) async {
    try {
      final response = await _supabase
          .from('app_settings')
          .select('setting_value')
          .eq('setting_key', settingKey)
          .single();

      return response['setting_value'];
    } catch (e) {
      return null;
    }
  }

  // تحديث إعداد محدد
  static Future<bool> updateSetting(String settingKey, String value) async {
    try {
      await _supabase
          .from('app_settings')
          .upsert({
            'setting_key': settingKey,
            'setting_value': value,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'setting_key');

      return true;
    } catch (e) {
      return false;
    }
  }

  // جلب العرض الترويجي
  static Future<String?> getPromotionalOffer() async {
    return await getSetting('promotional_offer');
  }

  // جلب رسوم التوصيل
  static Future<double?> getDeliveryFee() async {
    final fee = await getSetting('delivery_fee');
    return fee != null ? double.tryParse(fee) : null;
  }

  // جلب رقم الواتساب
  static Future<String?> getWhatsappNumber() async {
    return await getSetting('whatsapp_number');
  }

  // جلب رابط الفيسبوك
  static Future<String?> getFacebookUrl() async {
    return await getSetting('facebook_url');
  }

  // جلب رابط الإنستغرام
  static Future<String?> getInstagramUrl() async {
    return await getSetting('instagram_url');
  }
}









