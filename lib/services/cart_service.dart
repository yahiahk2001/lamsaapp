import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';

class CartService {
  static final List<CartItem> _items = [];
  static final SupabaseClient _supabase = Supabase.instance.client;
  static String? _orderNotes; // ملاحظات الطلب العامة

  static List<CartItem> get items => List.unmodifiable(_items);
  static String? get orderNotes => _orderNotes;

  static double get totalAmount {
    return _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  static int get totalItems {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  static Future<void> addItem(ProductModel product, {int quantity = 1, String? notes, bool isCarton = false}) async {
    final existingIndex = _items.indexWhere((item) => item.productId == product.id && item.isCarton == isCarton);
    
    if (existingIndex != -1) {
      _items[existingIndex].quantity += quantity;
      if (notes != null) {
        _items[existingIndex].notes = notes;
      }
    } else {
      _items.add(CartItem(
        productId: product.id,
        productName: product.name,
        price: product.price,
        cartonPrice: product.cartonPrice,
        quantity: quantity,
        notes: notes,
        imageUrl: product.mainImage,
        isCarton: isCarton,
      ));
    }
  }

  // إضافة منتج مع سعر محدد (للطلبات بالكارتون)
  static Future<void> addItemWithCustomPrice(ProductModel product, {int quantity = 1, String? notes, double? customPrice, bool isCarton = false}) async {
    final existingIndex = _items.indexWhere((item) => item.productId == product.id && item.isCarton == isCarton);
    
    if (existingIndex != -1) {
      _items[existingIndex].quantity += quantity;
      if (notes != null) {
        _items[existingIndex].notes = notes;
      }
    } else {
      _items.add(CartItem(
        productId: product.id,
        productName: product.name,
        price: customPrice ?? product.price,
        cartonPrice: product.cartonPrice,
        quantity: quantity,
        notes: notes,
        imageUrl: product.mainImage,
        isCarton: isCarton,
      ));
    }

    // مزامنة مع قاعدة البيانات إن وجد مستخدم مسجل
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      final now = DateTime.now().toIso8601String();
      final item = _items.firstWhere((i) => i.productId == product.id);
      try {
        await _supabase
            .from('cart_items')
            .upsert({
              'user_id': userId,
              'product_id': product.id,
              'quantity': item.quantity,
              'notes': item.notes,
              'created_at': now,
              'updated_at': now,
            }, onConflict: 'user_id,product_id');
      } catch (e) {
        // السلوك المحلي يظل صحيحًا حتى لو فشل الحفظ السحابي
        // يمكن إضافة تسجيل لاحقًا
      }
    }
  }

  static Future<void> removeItem(String productId) async {
    _items.removeWhere((item) => item.productId == productId);

    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      try {
        await _supabase
            .from('cart_items')
            .delete()
            .eq('user_id', userId)
            .eq('product_id', productId);
      } catch (e) {
        // تجاهل الخطأ السحابي للحفاظ على تجربة المستخدم
      }
    }
  }

  static Future<void> updateQuantity(String productId, int quantity) async {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      try {
        if (quantity <= 0) {
          await _supabase
              .from('cart_items')
              .delete()
              .eq('user_id', userId)
              .eq('product_id', productId);
        } else {
          await _supabase
              .from('cart_items')
              .update({
                'quantity': quantity,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('user_id', userId)
              .eq('product_id', productId);
        }
      } catch (e) {
        // تجاهل الخطأ السحابي
      }
    }
  }

  static Future<void> updateNotes(String productId, String? notes) async {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      _items[index].notes = notes;
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      try {
        await _supabase
            .from('cart_items')
            .update({
              'notes': notes,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('product_id', productId);
      } catch (e) {
        // تجاهل الخطأ السحابي
      }
    }
  }

  static Future<void> clear() async {
    _items.clear();
    _orderNotes = null; // مسح ملاحظات الطلب العامة أيضاً

    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      try {
        await _supabase
            .from('cart_items')
            .delete()
            .eq('user_id', userId);
      } catch (e) {
        // تجاهل الخطأ السحابي
      }
    }
  }

  // إدارة ملاحظات الطلب العامة
  static void setOrderNotes(String? notes) {
    _orderNotes = notes;
  }

  static void addToOrderNotes(String notes) {
    if (_orderNotes == null || _orderNotes!.isEmpty) {
      _orderNotes = notes;
    } else {
      _orderNotes = '$_orderNotes\n$notes';
    }
  }

  static bool get isEmpty => _items.isEmpty;
  static int get itemCount => _items.length;

  // التحقق من وجود منتج في السلة
  static bool containsProduct(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  // الحصول على كمية منتج معين في السلة
  static int getProductQuantity(String productId) {
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

  // الحصول على ملاحظات منتج معين في السلة
  static String? getProductNotes(String productId) {
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

  // تحويل عناصر السلة إلى عناصر طلب
  static List<OrderItemModel> toOrderItems(String orderId) {
    return _items.map((item) => OrderItemModel(
      id: '', // سيتم إنشاؤه من قاعدة البيانات
      orderId: orderId,
      productId: item.productId,
      productName: item.productName,
      productPrice: item.price,
      quantity: item.quantity,
      notes: item.notes,
      subtotal: item.price * item.quantity,
      createdAt: DateTime.now(),
    )).toList();
  }

  // تحويل عناصر السلة إلى نماذج عناصر السلة
  static List<CartItemModel> toCartItemModels(String userId) {
    return _items.map((item) => CartItemModel(
      id: '', // سيتم إنشاؤه من قاعدة البيانات
      userId: userId,
      productId: item.productId,
      quantity: item.quantity,
      notes: item.notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    )).toList();
  }

  // تحميل عناصر السلة من قاعدة البيانات (للمستقبل)
  static Future<void> loadCartItems(String userId) async {
    try {
      final response = await _supabase
          .from('cart_items')
          .select('product_id, quantity, notes, is_carton, products(name, price, carton_price, image_url_1, image_url_2, image_url_3)')
          .eq('user_id', userId)
          .order('created_at');

      _items.clear();
      for (final row in response as List) {
        final product = row['products'] as Map<String, dynamic>?;
        final name = product != null ? (product['name'] as String) : '';
        final price = product != null
            ? ((product['price'] is int) ? (product['price'] as int).toDouble() : product['price'] as double)
            : 0.0;
        final cartonPrice = product != null && product['carton_price'] != null
            ? ((product['carton_price'] is int) ? (product['carton_price'] as int).toDouble() : product['carton_price'] as double)
            : null;
        final imageUrl = product != null
            ? (product['image_url_1'] ?? product['image_url_2'] ?? product['image_url_3']) as String?
            : null;

        _items.add(CartItem(
          productId: row['product_id'] as String,
          productName: name,
          price: price,
          cartonPrice: cartonPrice,
          quantity: row['quantity'] as int,
          notes: row['notes'] as String?,
          imageUrl: imageUrl,
          isCarton: row['is_carton'] as bool? ?? false,
        ));
      }
    } catch (e) {
      // فشل التحميل من السحابة لا يمنع الاستمرار محليًا
    }
  }

  // حفظ عناصر السلة إلى قاعدة البيانات (للمستقبل)
  static Future<void> saveCartItems(String userId) async {
    try {
      if (_items.isEmpty) {
        await _supabase.from('cart_items').delete().eq('user_id', userId);
        return;
      }

      final now = DateTime.now().toIso8601String();
      final rows = _items.map((item) => {
            'user_id': userId,
            'product_id': item.productId,
            'quantity': item.quantity,
            'notes': item.notes,
            'is_carton': item.isCarton,
            'created_at': now,
            'updated_at': now,
          }).toList();

      await _supabase.from('cart_items').upsert(rows, onConflict: 'user_id,product_id');
    } catch (e) {
      // تجاهل الأخطاء السحابية هنا
    }
  }
}

class CartItem {
  final String productId;
  final String productName;
  final double price;
  final double? cartonPrice;
  int quantity;
  String? notes;
  final String? imageUrl;
  final bool isCarton; // هل العنصر طلب كارتون أم قطعة

  CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    this.cartonPrice,
    required this.quantity,
    this.notes,
    this.imageUrl,
    this.isCarton = false,
  });

  double get subtotal => price * quantity;

  CartItem copyWith({
    String? productId,
    String? productName,
    double? price,
    double? cartonPrice,
    int? quantity,
    String? notes,
    String? imageUrl,
    bool? isCarton,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      cartonPrice: cartonPrice ?? this.cartonPrice,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      isCarton: isCarton ?? this.isCarton,
    );
  }
}
