import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/advertisement_model.dart';
import '../models/app_settings_model.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../utils/supabase_config.dart';
import '../utils/error_handler.dart';

class SupabaseService {
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
    return ErrorHandler.isJwtError(error);
  }


  // ==========================================
  // الفئات (Categories)
  // ==========================================
  
  static Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('sort_order')
          .order('name');
      
      return response.map((json) => CategoryModel.fromJson(json)).toList();
    } catch (e) {
      
      // إذا كان الخطأ بسبب JWT expired، نحاول استخدام anonymous access
      if (_isJwtError(e)) {
        try {
          final anonymousClient = _getAnonymousClient();
          final response = await anonymousClient
              .from('categories')
              .select()
              .eq('is_active', true)
              .order('sort_order')
              .order('name');
          
          return response.map((json) => CategoryModel.fromJson(json)).toList();
        } catch (anonymousError) {
          return [];
        }
      }
      
      return [];
    }
  }

  static Future<CategoryModel?> getCategory(String id) async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .eq('id', id)
          .single();
      
      return CategoryModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // ==========================================
  // المنتجات (Products)
  // ==========================================
  
  static Future<List<ProductModel>> getProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .order('sort_order')
          .order('name');
      
      final products = response.map((json) => ProductModel.fromJson(json)).toList();
      
      if (products.isNotEmpty) {
      } else {
      }
      
      return products;
    } catch (e) {
      
      // إذا كان الخطأ بسبب JWT expired، نحاول استخدام anonymous access
      if (_isJwtError(e)) {
        try {
          final anonymousClient = _getAnonymousClient();
          final response = await anonymousClient
              .from('products')
              .select()
              .eq('is_active', true)
              .order('created_at', ascending: false)
              .order('sort_order')
              .order('name');
          
          final products = response.map((json) => ProductModel.fromJson(json)).toList();
          
          // طباعة أسماء المنتجات للتأكد
          if (products.isNotEmpty) {
          } else {
          }
          
          return products;
        } catch (anonymousError) {
          return [];
        }
      }
      
      return [];
    }
  }

  static Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('category_id', categoryId)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .order('sort_order')
          .order('name');
      
      return response.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      
      // إذا كان الخطأ بسبب JWT expired، نحاول استخدام anonymous access
      if (_isJwtError(e)) {
        try {
          final anonymousClient = _getAnonymousClient();
          final response = await anonymousClient
              .from('products')
              .select()
              .eq('category_id', categoryId)
              .eq('is_active', true)
              .order('created_at', ascending: false)
              .order('sort_order')
              .order('name');
          
          return response.map((json) => ProductModel.fromJson(json)).toList();
        } catch (anonymousError) {
          return [];
        }
      }
      
      return [];
    }
  }

  static Future<ProductModel?> getProduct(String id) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('id', id)
          .single();
      
      return ProductModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  static Future<List<ProductModel>> getPopularProducts({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .order('sort_order')
          .limit(limit);
      
      return response.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      
      // إذا كان الخطأ بسبب JWT expired، نحاول استخدام anonymous access
      if (_isJwtError(e)) {
        try {
          final anonymousClient = _getAnonymousClient();
          final response = await anonymousClient
              .from('products')
              .select()
              .eq('is_active', true)
              .order('created_at', ascending: false)
              .order('sort_order')
              .limit(limit);
          
          return response.map((json) => ProductModel.fromJson(json)).toList();
        } catch (anonymousError) {
          return [];
        }
      }
      
      return [];
    }
  }

  // دالة للحصول على عدد المنتجات النشطة الإجمالي
  static Future<int> getActiveProductsCount() async {
    try {
      // استخدام طريقة بديلة للحصول على العدد
      final response = await _supabase
          .from('products')
          .select('id')
          .eq('is_active', true);
      
      return response.length;
    } catch (e) {
      return 0;
    }
  }

  // دالة التحميل الكسول للمنتجات مع الصفحات
  static Future<List<ProductModel>> getProductsWithPagination({
    required int page,
    required int limit,
  }) async {
    try {
      final offset = page * limit;
      
      
      final response = await _supabase
          .from('products')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .order('sort_order')
          .order('name')
          .range(offset, offset + limit - 1);
      
      final products = response.map((json) => ProductModel.fromJson(json)).toList();
      
      if (products.isNotEmpty) {
      } else {
      }
      
      return products;
    } catch (e) {
      
      // إذا كان الخطأ بسبب JWT expired، نحاول استخدام anonymous access
      if (_isJwtError(e)) {
        try {
          final anonymousClient = _getAnonymousClient();
          final offset = page * limit;
          final response = await anonymousClient
              .from('products')
              .select()
              .eq('is_active', true)
              .order('created_at', ascending: false)
              .order('sort_order')
              .order('name')
              .range(offset, offset + limit - 1);
          
          final products = response.map((json) => ProductModel.fromJson(json)).toList();
          
          if (products.isNotEmpty) {
          }
          
          return products;
        } catch (anonymousError) {
          return [];
        }
      }
      
      return [];
    }
  }

  // ==========================================
  // الإعلانات (Advertisements)
  // ==========================================
  
  static Future<List<AdvertisementModel>> getAdvertisements() async {
    try {
      final response = await _supabase
          .from('advertisements')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      
      return response.map((json) => AdvertisementModel.fromJson(json)).toList();
    } catch (e) {
      
      // إذا كان الخطأ بسبب JWT expired، نحاول استخدام anonymous access
      if (_isJwtError(e)) {
        try {
          final anonymousClient = _getAnonymousClient();
          final response = await anonymousClient
              .from('advertisements')
              .select()
              .eq('is_active', true)
              .order('sort_order');
          
          return response.map((json) => AdvertisementModel.fromJson(json)).toList();
        } catch (anonymousError) {
          return [];
        }
      }
      
      return [];
    }
  }

  static Future<List<AdvertisementModel>> getActiveAdvertisements() async {
    try {
      final now = DateTime.now().toIso8601String();
      
      final response = await _supabase
          .from('advertisements')
          .select()
          .eq('is_active', true)
          .or('start_date.is.null,start_date.lte.$now')
          .or('end_date.is.null,end_date.gte.$now')
          .order('sort_order');
      
      return response.map((json) => AdvertisementModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // ==========================================
  // إعدادات التطبيق (App Settings)
  // ==========================================
  
  static Future<List<AppSettingsModel>> getAppSettings() async {
    try {
      final response = await _supabase
          .from('app_settings')
          .select()
          .order('setting_key');
      
      return response.map((json) => AppSettingsModel.fromJson(json)).toList();
    } catch (e) {
      
      // إذا كان الخطأ بسبب JWT expired، نحاول استخدام anonymous access
      if (_isJwtError(e)) {
        try {
          final anonymousClient = _getAnonymousClient();
          final response = await anonymousClient
              .from('app_settings')
              .select()
              .order('setting_key');
          
          return response.map((json) => AppSettingsModel.fromJson(json)).toList();
        } catch (anonymousError) {
          return [];
        }
      }
      
      return [];
    }
  }

  static Future<AppSettingsModel?> getAppSetting(String key) async {
    try {
      final response = await _supabase
          .from('app_settings')
          .select()
          .eq('setting_key', key)
          .single();
      
      return AppSettingsModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getSettingValue(String key) async {
    try {
      final setting = await getAppSetting(key);
      return setting?.settingValue;
    } catch (e) {
      return null;
    }
  }

  // ==========================================
  // السلة (Cart)
  // ==========================================
  
  static Future<List<CartItemModel>> getCartItems(String userId) async {
    try {
      final response = await _supabase
          .from('cart_items')
          .select('*, products(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return response.map((json) => CartItemModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<CartItemModel?> addCartItem(CartItemModel cartItem) async {
    try {
      final response = await _supabase
          .from('cart_items')
          .upsert(cartItem.toJson())
          .select()
          .single();
      
      return CartItemModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> updateCartItem(CartItemModel cartItem) async {
    try {
      await _supabase
          .from('cart_items')
          .update(cartItem.toJson())
          .eq('id', cartItem.id);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> removeCartItem(String cartItemId) async {
    try {
      await _supabase
          .from('cart_items')
          .delete()
          .eq('id', cartItemId);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> clearCart(String userId) async {
    try {
      await _supabase
          .from('cart_items')
          .delete()
          .eq('user_id', userId);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // الطلبات (Orders)
  // ==========================================
  
  static Future<List<OrderModel>> getOrdersByUser(String userId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return response.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<OrderModel?> createOrder(OrderModel order) async {
    try {
      final response = await _supabase
          .from('orders')
          .insert(order.toJson())
          .select()
          .single();
      
      return OrderModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _supabase
          .from('orders')
          .update({'status': status})
          .eq('id', orderId);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // المستخدمين (Users)
  // ==========================================
  
  static Future<UserModel?> getUser(String id) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', id)
          .single();
      
      return UserModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  static Future<UserModel?> createUser(UserModel user) async {
    try {
      final response = await _supabase
          .from('users')
          .insert(user.toJson())
          .select()
          .single();
      
      return UserModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  static Future<UserModel?> updateUser(UserModel user) async {
    try {
      final response = await _supabase
          .from('users')
          .update(user.toJson())
          .eq('id', user.id)
          .select()
          .single();
      
      return UserModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // ==========================================
  // البحث (Search)
  // ==========================================
  
  static Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('is_active', true)
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false)
          .order('sort_order')
          .order('name');
      
      return response.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}
