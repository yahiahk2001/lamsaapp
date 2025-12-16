import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Supabase Project URL
  static String get url => dotenv.env['SUPABASE_URL'] ?? '';
  
  // Supabase Anonymous Key
  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  // Storage Buckets
  static String get productImagesBucket => dotenv.env['PRODUCT_IMAGES_BUCKET'] ?? 'product-images';
  static String get categoryImagesBucket => dotenv.env['CATEGORY_IMAGES_BUCKET'] ?? 'category-images';
  static String get advertisementImagesBucket => dotenv.env['ADVERTISEMENT_IMAGES_BUCKET'] ?? 'advertisement-images';
  static String get appAssetsBucket => dotenv.env['APP_ASSETS_BUCKET'] ?? 'app-assets';
  
  // Database Tables
  static String get usersTable => dotenv.env['USERS_TABLE'] ?? 'users';
  static String get categoriesTable => dotenv.env['CATEGORIES_TABLE'] ?? 'categories';
  static String get productsTable => dotenv.env['PRODUCTS_TABLE'] ?? 'products';
  static String get advertisementsTable => dotenv.env['ADVERTISEMENTS_TABLE'] ?? 'advertisements';
  static String get ordersTable => dotenv.env['ORDERS_TABLE'] ?? 'orders';
  static String get orderItemsTable => dotenv.env['ORDER_ITEMS_TABLE'] ?? 'order_items';
  static String get cartItemsTable => dotenv.env['CART_ITEMS_TABLE'] ?? 'cart_items';
  static String get appSettingsTable => dotenv.env['APP_SETTINGS_TABLE'] ?? 'app_settings';
  
  // App Settings Keys
  static String get whatsappNumberKey => dotenv.env['WHATSAPP_NUMBER_KEY'] ?? 'whatsapp_number';
  static String get facebookUrlKey => dotenv.env['FACEBOOK_URL_KEY'] ?? 'facebook_url';
  static String get instagramUrlKey => dotenv.env['INSTAGRAM_URL_KEY'] ?? 'instagram_url';
  static String get appLogoUrlKey => dotenv.env['APP_LOGO_URL_KEY'] ?? 'app_logo_url';
  static String get deliveryFeeKey => dotenv.env['DELIVERY_FEE_KEY'] ?? 'delivery_fee';
  
  // Order Status Values
  static String get orderStatusProcessing => dotenv.env['ORDER_STATUS_PROCESSING'] ?? 'processing';
  static String get orderStatusDelivering => dotenv.env['ORDER_STATUS_DELIVERING'] ?? 'delivering';
  static String get orderStatusDelivered => dotenv.env['ORDER_STATUS_DELIVERED'] ?? 'delivered';
  static String get orderStatusCancelled => dotenv.env['ORDER_STATUS_CANCELLED'] ?? 'cancelled';
  
  // Default Values
  static double get defaultDeliveryFee => double.tryParse(dotenv.env['DEFAULT_DELIVERY_FEE'] ?? '2000.0') ?? 2000.0; // دينار عراقي
  static int get defaultProductLimit => int.tryParse(dotenv.env['DEFAULT_PRODUCT_LIMIT'] ?? '10') ?? 10;
  static int get maxImageSize => int.tryParse(dotenv.env['MAX_IMAGE_SIZE'] ?? '5242880') ?? 5 * 1024 * 1024; // 5MB
  
  // Error Messages
  static const String networkError = 'حدث خطأ في الاتصال بالشبكة';
  static const String serverError = 'حدث خطأ في الخادم';
  static const String authError = 'حدث خطأ في المصادقة';
  static const String unknownError = 'حدث خطأ غير معروف';
  
  // Success Messages
  static const String orderCreatedSuccess = 'تم إنشاء الطلب بنجاح';
  static const String productAddedToCart = 'تم إضافة المنتج إلى السلة';
  static const String profileUpdated = 'تم تحديث الملف الشخصي';
  
  // Validation Messages
  static const String requiredField = 'هذا الحقل مطلوب';
  static const String invalidEmail = 'البريد الإلكتروني غير صحيح';
  static const String invalidPhone = 'رقم الهاتف غير صحيح';
  static const String passwordTooShort = 'كلمة المرور قصيرة جداً';
  
  // UI Text
  static const String appName = 'متجر الحلويات';
  static const String welcomeMessage = 'مرحباً بك في متجر الحلويات! 🎂';
  static const String discoverMessage = 'اكتشف أشهى الحلويات والمعجنات';
  static const String categoriesTitle = 'الفئات';
  static const String popularProductsTitle = 'المنتجات الشائعة';
  static const String advertisementsTitle = 'العروض والإعلانات';
  static const String addToCartButton = 'أضف للسلة';
  static const String loadingMessage = 'جاري تحميل البيانات...';
  static const String retryButton = 'إعادة المحاولة';
  static const String noDataMessage = 'لا توجد بيانات متاحة';
  
  // Currency
  static const String currency = 'دينار';
  static const String currencySymbol = 'د.ع';
  
  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';
  
  // Image Placeholders
  static const String productImagePlaceholder = 'assets/images/product_placeholder.png';
  static const String categoryImagePlaceholder = 'assets/images/category_placeholder.png';
  static const String advertisementImagePlaceholder = 'assets/images/ad_placeholder.png';
  static const String userAvatarPlaceholder = 'assets/images/avatar_placeholder.png';
  
  // API Endpoints (if using custom API)
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'https://your-api-url.com/api';
  static String get productsEndpoint => dotenv.env['PRODUCTS_ENDPOINT'] ?? '/products';
  static String get categoriesEndpoint => dotenv.env['CATEGORIES_ENDPOINT'] ?? '/categories';
  static String get ordersEndpoint => dotenv.env['ORDERS_ENDPOINT'] ?? '/orders';
  static String get usersEndpoint => dotenv.env['USERS_ENDPOINT'] ?? '/users';
  
  // Cache Settings
  static Duration get cacheDuration => Duration(hours: int.tryParse(dotenv.env['CACHE_DURATION_HOURS'] ?? '1') ?? 1);
  static int get maxCacheSize => int.tryParse(dotenv.env['MAX_CACHE_SIZE'] ?? '52428800') ?? 50 * 1024 * 1024; // 50MB
  
  // Pagination
  static int get defaultPageSize => int.tryParse(dotenv.env['DEFAULT_PAGE_SIZE'] ?? '20') ?? 20;
  static int get maxPageSize => int.tryParse(dotenv.env['MAX_PAGE_SIZE'] ?? '100') ?? 100;
  
  // Search
  static int get minSearchLength => int.tryParse(dotenv.env['MIN_SEARCH_LENGTH'] ?? '2') ?? 2;
  static int get maxSearchResults => int.tryParse(dotenv.env['MAX_SEARCH_RESULTS'] ?? '50') ?? 50;
  
  // File Upload
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];
  
  static const List<String> allowedFileExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  ];
}
