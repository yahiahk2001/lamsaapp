import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.length;
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  String? get orderNotes => CartService.orderNotes;

  CartProvider() {
    // تحميل السلة عند إنشاء Provider
    loadCart();
  }

  // تحميل السلة من الخدمة
  void loadCart() {
    _items = List.from(CartService.items);
    notifyListeners();
  }

  // إضافة منتج للسلة
  Future<void> addItem(ProductModel product, {int quantity = 1, String? notes, bool isCarton = false}) async {
    _setLoading(true);
    _clearError();

    try {
      await CartService.addItem(product, quantity: quantity, notes: notes, isCarton: isCarton);
      _items = List.from(CartService.items);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('حدث خطأ أثناء إضافة المنتج للسلة');
      _setLoading(false);
    }
  }

  // إضافة منتج مع سعر محدد
  Future<void> addItemWithCustomPrice(ProductModel product, {int quantity = 1, String? notes, bool isCarton = false}) async {
    _setLoading(true);
    _clearError();

    try {
      await CartService.addItemWithCustomPrice(product, quantity: quantity, notes: notes, customPrice: product.price, isCarton: isCarton);
      _items = List.from(CartService.items);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('حدث خطأ أثناء إضافة المنتج للسلة');
      _setLoading(false);
    }
  }

  // إزالة منتج من السلة
  Future<void> removeItem(String productId) async {
    _setLoading(true);
    _clearError();

    try {
      await CartService.removeItem(productId);
      _items = List.from(CartService.items);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('حدث خطأ أثناء إزالة المنتج من السلة');
      _setLoading(false);
    }
  }

  // تحديث كمية منتج
  Future<void> updateQuantity(String productId, int quantity) async {
    _setLoading(true);
    _clearError();

    try {
      await CartService.updateQuantity(productId, quantity);
      _items = List.from(CartService.items);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('حدث خطأ أثناء تحديث الكمية');
      _setLoading(false);
    }
  }

  // تحديث ملاحظات منتج
  Future<void> updateNotes(String productId, String? notes) async {
    _setLoading(true);
    _clearError();

    try {
      await CartService.updateNotes(productId, notes);
      _items = List.from(CartService.items);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('حدث خطأ أثناء تحديث الملاحظات');
      _setLoading(false);
    }
  }

  // تفريغ السلة
  Future<void> clear() async {
    _setLoading(true);
    _clearError();

    try {
      await CartService.clear();
      _items = List.from(CartService.items);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('حدث خطأ أثناء تفريغ السلة');
      _setLoading(false);
    }
  }

  // التحقق من وجود منتج في السلة
  bool containsProduct(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  // الحصول على كمية منتج معين
  int getProductQuantity(String productId) {
    final item = _items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(
        productId: productId,
        productName: '',
        price: 0,
        quantity: 0,
      ),
    );
    return item.quantity;
  }

  // الحصول على ملاحظات منتج معين
  String? getProductNotes(String productId) {
    final item = _items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(
        productId: productId,
        productName: '',
        price: 0,
        quantity: 0,
      ),
    );
    return item.notes;
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void _setError(String error) {
    _error = error;
  }

  void _clearError() {
    _error = null;
  }

  // تحديث السلة من الخدمة (للاستخدام عند العودة من صفحات أخرى)
  void refresh() {
    _items = List.from(CartService.items);
    notifyListeners();
  }

  // إدارة ملاحظات الطلب العامة
  void setOrderNotes(String? notes) {
    CartService.setOrderNotes(notes);
    notifyListeners();
  }

  void addToOrderNotes(String notes) {
    CartService.addToOrderNotes(notes);
    notifyListeners();
  }
}
