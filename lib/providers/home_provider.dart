import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/advertisement_model.dart';
import '../models/app_settings_model.dart';
import '../services/supabase_service.dart';
import '../utils/error_handler.dart';

class HomeProvider extends ChangeNotifier {
  // البيانات
  List<CategoryModel> _categories = [];
  List<ProductModel> _popularProducts = [];
  List<AdvertisementModel> _advertisements = [];
  AppSettingsModel? _appSettings;
  
  // متغيرات التحميل الكسول للمنتجات
  List<ProductModel> _allProducts = [];
  bool _isLoadingMoreProducts = false;
  bool _hasMoreProducts = true;
  int _currentPage = 0;
  static const int _productsPerPage = 10;
  DateTime? _lastLoadMoreCall;
  
  // حالة التحميل
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<CategoryModel> get categories => _categories;
  List<ProductModel> get popularProducts => _popularProducts;
  List<AdvertisementModel> get advertisements => _advertisements;
  AppSettingsModel? get appSettings => _appSettings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Getters للتحميل الكسول
  List<ProductModel> get allProducts => _allProducts;
  bool get isLoadingMoreProducts => _isLoadingMoreProducts;
  bool get hasMoreProducts => _hasMoreProducts;
  int get currentPage => _currentPage;
  
  // فحص الاتصال بالإنترنت
  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.any((result) => result != ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  // تحميل البيانات الأساسية أولاً ثم باقي البيانات تدريجياً
  Future<void> loadHomeData() async {
    _setLoading(true);
    _clearError();
    
    // فحص الاتصال أولاً
    bool isConnected = await _checkConnectivity();
    if (!isConnected) {
      _setError('لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.');
      _setLoading(false);
      return;
    }
    
    try {
      // المرحلة الأولى: تحميل الفئات والإعدادات الأساسية فقط لعرض الواجهة سريعاً
      await _loadEssentialData();
      _setLoading(false); // إخفاء مؤشر التحميل لعرض المحتوى المتاح
      
      // المرحلة الثانية: تحميل باقي البيانات في الخلفية
      _loadSecondaryDataInBackground();
      
    } catch (e) {
      String errorMessage = _getErrorMessage(e);
      _setError(errorMessage);
      _setLoading(false);
      
      // التحقق من خطأ JWT وتوجيه المستخدم إذا لزم الأمر
      if (ErrorHandler.isJwtError(e)) {
        // سيتم التعامل مع التوجيه في الشاشة التي تستخدم هذا Provider
      }
    }
  }

  // تحميل البيانات الأساسية للعرض السريع
  Future<void> _loadEssentialData() async {
    try {
      // تحميل الفئات والإعدادات فقط للعرض السريع
      await Future.wait([
        _loadCategories(),
        _loadAppSettings(),
      ]);
    } catch (e) {
      rethrow;
    }
  }

  // تحميل باقي البيانات في الخلفية دون انتظار
  void _loadSecondaryDataInBackground() {
    
    // تشغيل في الخلفية دون انتظار
    Future.microtask(() async {
      try {
        await _loadAdvertisements();
        
        await _loadInitialProducts();
        
        await _loadPopularProducts();
        
      // ignore: empty_catches
      } catch (e) {
      }
    });
  }

  // دالة مساعدة لتحديد رسالة الخطأ
  String _getErrorMessage(dynamic e) {
    if (e.toString().contains('SocketException') || 
        e.toString().contains('NetworkException') ||
        e.toString().contains('timeout') ||
        e.toString().contains('connection') ||
        e.toString().contains('Failed host lookup') ||
        e.toString().contains('No address associated with hostname')) {
      return 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
    } else if (e.toString().contains('JWT') || e.toString().contains('Unauthorized')) {
      return 'انتهت صلاحية الجلسة. يرجى إعادة تسجيل الدخول.';
    } else {
      return 'حدث خطأ في تحميل البيانات. يرجى المحاولة مرة أخرى.';
    }
  }
  
  // تحميل المنتجات الأولية
  Future<void> _loadInitialProducts() async {
    try {
      // أولاً نحصل على العدد الإجمالي للمنتجات
      final totalProductsCount = await SupabaseService.getActiveProductsCount();
      
      
      _currentPage = 0;
      _allProducts = await SupabaseService.getProductsWithPagination(
        page: _currentPage,
        limit: _productsPerPage,
      );
      
      
      // التحقق من وجود المزيد من المنتجات
      _hasMoreProducts = _allProducts.length >= _productsPerPage && _allProducts.length < totalProductsCount;
      
      
      // تحذير: لا نستخدم fallback الذي يجلب جميع المنتجات
      if (_allProducts.isEmpty) {
        _hasMoreProducts = false;
      }
      
      notifyListeners();
    } catch (e) {
      // في حالة الخطأ، نتأكد من إيقاف التحميل الكسول
      _hasMoreProducts = false;
      notifyListeners();
    }
  }
  
  // تحميل المزيد من المنتجات (التحميل الكسول)
  Future<void> loadMoreProducts() async {
    
    // debouncing - تجنب الاستدعاءات المتكررة في غضون ثانيتين
    final now = DateTime.now();
    if (_lastLoadMoreCall != null && now.difference(_lastLoadMoreCall!).inSeconds < 2) {
      return;
    }
    _lastLoadMoreCall = now;
    
    if (_isLoadingMoreProducts) {
      return;
    }
    
    if (!_hasMoreProducts) {
      return;
    }
    
    _setLoadingMoreProducts(true);
    
    try {
      final nextPage = _currentPage + 1;
      
      final newProducts = await SupabaseService.getProductsWithPagination(
        page: nextPage,
        limit: _productsPerPage,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          return <ProductModel>[];
        },
      );
      
      
      if (newProducts.isNotEmpty) {
        _allProducts.addAll(newProducts);
        _currentPage = nextPage;
        
        // تحسين منطق hasMoreProducts
        _hasMoreProducts = newProducts.length == _productsPerPage;
        
      } else {
        _hasMoreProducts = false;
      }
      
      notifyListeners();
      
      // إعادة تعيين debouncing عند نجاح التحميل
      _lastLoadMoreCall = null;
      
    } catch (e) {
      
      // في حالة الخطأ، نتوقف عن التحميل الكسول
      _hasMoreProducts = false;
      notifyListeners();
    } finally {
      _setLoadingMoreProducts(false);
    }
  }
  
  // تحميل الفئات
  Future<void> _loadCategories() async {
    try {
      _categories = await SupabaseService.getCategories();
      notifyListeners();
    } catch (e) {
      throw Exception('حدث خطأ في تحميل الفئات');
    }
  }
  
  // تحميل المنتجات الشائعة
  Future<void> _loadPopularProducts() async {
    try {
      _popularProducts = await SupabaseService.getPopularProducts(limit: 10);
      notifyListeners();
    } catch (e) {
      // لا نرمي خطأ في البيانات الثانوية
    }
  }
  
  // تحميل الإعلانات
  Future<void> _loadAdvertisements() async {
    try {
      _advertisements = await SupabaseService.getActiveAdvertisements();
      notifyListeners();
    } catch (e) {
      // لا نرمي خطأ في البيانات الثانوية
    }
  }
  
  // تحميل إعدادات التطبيق
  Future<void> _loadAppSettings() async {
    try {
      final settings = await SupabaseService.getAppSettings();
      if (settings.isNotEmpty) {
        _appSettings = settings.first;
        // تحديث الإعدادات في الكلاس المساعد
        AppSettings.updateFromModels(settings);
      }
      notifyListeners();
    } catch (e) {
      throw Exception('حدث خطأ في تحميل إعدادات التطبيق');
    }
  }
  
  // إعادة تحميل البيانات
  Future<void> refreshData() async {
    try {
      // فحص الاتصال أولاً
      bool isConnected = await _checkConnectivity();
      if (!isConnected) {
        _setError('لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.');
        return;
      }
      
      // إعادة تعيين متغيرات التحميل الكسول
      _currentPage = 0;
      _hasMoreProducts = true;
      _allProducts.clear();
      
      await loadHomeData();
    } catch (e) {
      // لا نحتاج لمعالجة الخطأ هنا لأنه يتم معالجته في loadHomeData
    }
  }
  
  // البحث في المنتجات
  Future<List<ProductModel>> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      return _popularProducts;
    }
    
    try {
      return await SupabaseService.searchProducts(query);
    } catch (e) {
      return [];
    }
  }
  
  // الحصول على منتجات فئة معينة
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    try {
      return await SupabaseService.getProductsByCategory(categoryId);
    } catch (e) {
      return [];
    }
  }
  

  
  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setLoadingMoreProducts(bool loading) {
    _isLoadingMoreProducts = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
  }
  
  // مسح البيانات
  void clearData() {
    _categories = [];
    _popularProducts = [];
    _advertisements = [];
    _appSettings = null;
    _allProducts = [];
    _currentPage = 0;
    _hasMoreProducts = true;
    _error = null;
    notifyListeners();
  }
}
