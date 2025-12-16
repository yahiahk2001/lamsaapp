import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
// import '../models/cart_item_model.dart';
import '../services/cart_service.dart';

class OrderService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // حفظ طلب جديد في قاعدة البيانات
  static Future<String> saveOrder(OrderModel order) async {
    return await _saveOrderInternal(order);
  }
  
  // الدالة الداخلية لحفظ الطلب
  static Future<String> _saveOrderInternal(OrderModel order) async {
    try {
      // ضمان صحة user_id لتجنب خرق المفتاح الأجنبي
      final Map<String, dynamic> orderData = Map<String, dynamic>.from(order.toJson());
      
      if (order.userId != null && order.userId!.isNotEmpty) {
        try {
          final existing = await _supabase
              .from('users')
              .select('id')
              .eq('id', order.userId!)
              .limit(1);

          final List existingList = existing as List;
          final bool userExists = existingList.isNotEmpty;
          if (!userExists) {
            final authUser = Supabase.instance.client.auth.currentUser;
            final email = authUser?.email;
            if (email != null && email.isNotEmpty) {
              await _supabase.from('users').insert({
                'id': order.userId,
                'email': email,
                'name': order.customerName,
                'phone_number': order.customerPhone,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              });
            } else {
              // لا يوجد بريد لإدراج المستخدم، أزل الربط لتجنب خرق المفتاح الأجنبي
              orderData['user_id'] = null;
            }
          }
        } catch (e) {
          // في حال فشل التحقق/الإدراج، أزل الربط لتجنب خرق المفتاح الأجنبي
          orderData['user_id'] = null;
        }
      }

      // إدخال الطلب الرئيسي
      final orderResponse = await _supabase
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      final orderId = orderResponse['id'] as String;

      // إدخال عناصر الطلب
      final orderItems = CartService.items.map((item) => {
        'order_id': orderId,
        'product_id': item.productId,
        'product_name': item.productName,
        'product_price': item.price,
        'quantity': item.quantity,
        'notes': item.notes,
        'subtotal': item.subtotal,
        'is_carton': item.isCarton,
      }).toList();

      if (orderItems.isNotEmpty) {
        await _supabase
            .from('order_items')
            .insert(orderItems);
      }

      // ملاحظة: الإشعارات يتم إرسالها من لوحة التحكم فقط في النظام الجديد

      return orderId;

    } catch (e) {
      
      // إذا كان الخطأ متعلق بـ target_type في notifications، فهذا يعني أن هناك trigger في قاعدة البيانات
      // يحاول إنشاء إشعار بالنظام القديم
      if (e.toString().contains('target_type') && e.toString().contains('notifications')) {
        
        try {
          // محاولة بديلة - حفظ الطلب فقط بدون الاعتماد على triggers
          
          // إعادة تحضير البيانات
          final Map<String, dynamic> orderData = Map<String, dynamic>.from(order.toJson());
          
          // إزالة user_id مؤقتاً لتجنب أي مشاكل
          orderData['user_id'] = null;
          
          // إدراج الطلب مباشرة
          final orderResponse = await _supabase
              .from('orders')
              .insert(orderData)
              .select()
              .single();

          final orderId = orderResponse['id'] as String;

          // إدراج عناصر الطلب
          final orderItems = CartService.items.map((item) => {
            'order_id': orderId,
            'product_id': item.productId,
            'product_name': item.productName,
            'product_price': item.price,
            'quantity': item.quantity,
            'notes': item.notes,
            'subtotal': item.subtotal,
            'is_carton': item.isCarton,
          }).toList();

          if (orderItems.isNotEmpty) {
            await _supabase
                .from('order_items')
                .insert(orderItems);
          }

          return orderId;
          
        } catch (retryError) {
          throw Exception('فشل في حفظ الطلب حتى في المحاولة البديلة. يرجى تحديث triggers قاعدة البيانات.');
        }
      }
      
      throw Exception('فشل في حفظ الطلب: $e');
    }
  }

  // الحصول على طلبات المستخدم
  static Future<List<OrderModel>> getUserOrders(String userId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response.map((json) => OrderModel.fromJson(json)).toList();

    } catch (e) {
      throw Exception('فشل في جلب الطلبات: $e');
    }
  }

  // الحصول على تفاصيل طلب معين
  static Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      // جلب الطلب الرئيسي
      final orderResponse = await _supabase
          .from('orders')
          .select('*')
          .eq('id', orderId)
          .single();

      // جلب عناصر الطلب
      final itemsResponse = await _supabase
          .from('order_items')
          .select('*')
          .eq('order_id', orderId);

      return {
        'order': OrderModel.fromJson(orderResponse),
        // عناصر الطلب لها بنية مختلفة عن عناصر السلة
        'items': itemsResponse.map((json) => OrderItemModel.fromJson(json)).toList(),
      };

    } catch (e) {
      throw Exception('فشل في جلب تفاصيل الطلب: $e');
    }
  }

  // تحديث حالة الطلب
  static Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      // الحصول على بيانات الطلب الحالية
      final currentOrder = await _supabase
          .from('orders')
          .select('*')
          .eq('id', orderId)
          .single();

      final oldStatus = currentOrder['status'] as String;

      // تحديث حالة الطلب
      await _supabase
          .from('orders')
          .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', orderId);

      // ملاحظة: إشعارات تحديث حالة الطلب يتم إرسالها من لوحة التحكم فقط
      if (oldStatus != status) {
      }

    } catch (e) {
      throw Exception('فشل في تحديث حالة الطلب: $e');
    }
  }

  // حذف طلب (للمستخدم)
  static Future<void> deleteOrder(String orderId) async {
    try {
      // حذف عناصر الطلب أولاً
      await _supabase
          .from('order_items')
          .delete()
          .eq('order_id', orderId);

      // حذف الطلب الرئيسي
      await _supabase
          .from('orders')
          .delete()
          .eq('id', orderId);


    } catch (e) {
      throw Exception('فشل في حذف الطلب: $e');
    }
  }
}
