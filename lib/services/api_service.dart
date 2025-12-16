import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/advertisement_model.dart';
import '../models/app_settings_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/supabase_config.dart';

class ApiService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  // دالة مساعدة لإنشاء anonymous client
  static SupabaseClient _getAnonymousClient() {
    return SupabaseClient(
      SupabaseConfig.url,
      SupabaseConfig.anonKey,
    );
  }
  
  // دالة مساعدة لمعالجة أخطاء JWT
  static bool _isJwtError(dynamic error) {
    final errorString = error.toString();
    return errorString.contains('JWT expired') || 
           errorString.contains('Unauthorized') ||
           errorString.contains('PGRST303');
  }


  static Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*')
          .eq('category_id', categoryId)
          .eq('is_active', true)
          .order('sort_order')
          .order('name');

      return (response as List)
          .map((data) => ProductModel.fromJson(data))
          .toList();
    } catch (e) {
      
      // إذا كان الخطأ بسبب JWT expired، نحاول استخدام anonymous access
      if (_isJwtError(e)) {
        try {
          final anonymousClient = _getAnonymousClient();
          
          final response = await anonymousClient
              .from('products')
              .select('*')
              .eq('category_id', categoryId)
              .eq('is_active', true)
              .order('sort_order')
              .order('name');

          return (response as List)
              .map((data) => ProductModel.fromJson(data))
              .toList();
        } catch (anonymousError) {
          throw Exception('فشل في جلب منتجات الفئة - يرجى التحقق من الاتصال بالإنترنت');
        }
      }
      
      throw Exception('فشل في جلب منتجات الفئة');
    }
  }

  static Future<List<ProductModel>> getActiveProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select('*')
          .eq('is_active', true)
          .order('sort_order')
          .order('name')
          .limit(10); // جلب أول 10 منتجات فقط

      return (response as List)
          .map((data) => ProductModel.fromJson(data))
          .toList();
    } catch (e) {
      
      // إذا كان الخطأ بسبب JWT expired، نحاول استخدام anonymous access
      if (_isJwtError(e)) {
        try {
          final anonymousClient = _getAnonymousClient();
          
          final response = await anonymousClient
              .from('products')
              .select('*')
              .eq('is_active', true)
              .order('sort_order')
              .order('name')
              .limit(10);

          return (response as List)
              .map((data) => ProductModel.fromJson(data))
              .toList();
        } catch (anonymousError) {
          return []; // إرجاع قائمة فارغة بدلاً من رمي خطأ
        }
      }
      
      return []; // إرجاع قائمة فارغة في حالة الخطأ
    }
  }



  static Future<List<CategoryModel>> getActiveCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select('*')
          .eq('is_active', true)
          .order('sort_order')
          .order('name');

      return (response as List)
          .map((data) => CategoryModel.fromJson(data))
          .toList();
    } catch (e) {
      
      // إذا كان الخطأ بسبب JWT expired، نحاول استخدام anonymous access
      if (_isJwtError(e)) {
        try {
          // استخدام anonymous client للوصول للبيانات العامة
          final anonymousClient = _getAnonymousClient();
          
          final response = await anonymousClient
              .from('categories')
              .select('*')
              .eq('is_active', true)
              .order('sort_order')
              .order('name');

          return (response as List)
              .map((data) => CategoryModel.fromJson(data))
              .toList();
        } catch (anonymousError) {
          throw Exception('فشل في جلب الفئات - يرجى التحقق من الاتصال بالإنترنت');
        }
      }
      
      throw Exception('فشل في جلب الفئات');
    }
  }


  static Future<List<AdvertisementModel>> getActiveAdvertisements() async {
    try {
      final response = await _supabase
          .from('advertisements')
          .select('*')
          .eq('is_active', true)
          .order('sort_order');

      return (response as List)
          .map((data) => AdvertisementModel.fromJson(data))
          .toList();
    } catch (e) {
      
      // إذا كان الخطأ بسبب JWT expired، نحاول استخدام anonymous access
      if (_isJwtError(e)) {
        try {
          final anonymousClient = _getAnonymousClient();
          
          final response = await anonymousClient
              .from('advertisements')
              .select('*')
              .eq('is_active', true)
              .order('sort_order');

          return (response as List)
              .map((data) => AdvertisementModel.fromJson(data))
              .toList();
        } catch (anonymousError) {
          return []; // إرجاع قائمة فارغة بدلاً من رمي خطأ
        }
      }
      
      return []; // إرجاع قائمة فارغة في حالة الخطأ
    }
  }

  // App Settings
  static Future<List<AppSettingsModel>> getAppSettings() async {
    try {
      final response = await _supabase
          .from('app_settings')
          .select('*');

      return (response as List)
          .map((data) => AppSettingsModel.fromJson(data))
          .toList();
    } catch (e) {
      
      // إذا كان الخطأ بسبب JWT expired، نحاول استخدام anonymous access
      if (_isJwtError(e)) {
        try {
          final anonymousClient = _getAnonymousClient();
          
          final response = await anonymousClient
              .from('app_settings')
              .select('*');

          return (response as List)
              .map((data) => AppSettingsModel.fromJson(data))
              .toList();
        } catch (anonymousError) {
          return []; // إرجاع قائمة فارغة بدلاً من رمي خطأ
        }
      }
      
      return []; // إرجاع قائمة فارغة في حالة الخطأ
    }
  }

}
