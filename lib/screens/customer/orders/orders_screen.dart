// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lamsa/screens/customer/auth/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../../services/order_service.dart';
import '../../../services/user_service.dart';
import '../../../services/invoice_service.dart';
import '../../../models/order_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/colors.dart';
import '../../../widgets/common/connectivity_wrapper.dart';
import '../../../widgets/common/guest_guard.dart';

// محتوى صفحة الطلبات
class OrdersContent extends StatefulWidget {
  final VoidCallback? onNavigateToHome;
  
  const OrdersContent({super.key, this.onNavigateToHome});
  
  @override
  OrdersContentState createState() => OrdersContentState();
}

class OrdersContentState extends State<OrdersContent> {
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all'; // all | processing | delivering | delivered | cancelled

  @override
  void initState() {
    super.initState();
    _loadOrders();
    
    // التحقق من اكتمال بيانات المستخدم
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser != null) {
          final isProfileComplete = await UserService.isUserProfileComplete(currentUser.id);
          if (!isProfileComplete && mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
          }
        }
      } catch (e) {
        // إذا حدث خطأ (مثل فشل الشبكة)، نتجاهله ونسمح للمستخدم بالاستمرار
      }
    });
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        final orders = await OrderService.getUserOrders(currentUser.id);
        if (mounted) {
          setState(() {
            _orders = orders;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'يرجى تسجيل الدخول لعرض الطلبات';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'حدث خطأ في تحميل الطلبات';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityWrapper(
      child: GuestGuard(
        message: 'يجب عليك تسجيل الدخول لعرض طلباتك',
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.buttonColor,));
    }
    
    if (_error != null) {
      return _buildErrorWidget();
    }
    
    // دائماً نعرض الفلاتر، حتى لو كانت القائمة فارغة
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: _filteredOrders().isEmpty 
            ? _buildEmptyWidget() 
            : _buildOrdersList(),
        ),
      ],
    );
  }

  List<OrderModel> _filteredOrders() {
    if (_selectedFilter == 'all') return _orders;
    return _orders.where((o) => o.status == _selectedFilter).toList();
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadOrders,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    String title;
    String subtitle;
    IconData icon;
    
    // تحديد الرسالة حسب الفلتر المحدد
    switch (_selectedFilter) {
      case 'processing':
        title = 'لا توجد طلبات قيد المعالجة';
        subtitle = 'لا توجد طلبات في حالة المعالجة حالياً';
        icon = Icons.hourglass_empty;
        break;
      case 'delivering':
        title = 'لا توجد طلبات قيد التوصيل';
        subtitle = 'لا توجد طلبات في حالة التوصيل حالياً';
        icon = Icons.local_shipping_outlined;
        break;
      case 'delivered':
        title = 'لا توجد طلبات منجزة';
        subtitle = 'لم يتم إنجاز أي طلبات بعد';
        icon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        title = 'لا توجد طلبات ملغية';
        subtitle = 'لم يتم إلغاء أي طلبات';
        icon = Icons.cancel_outlined;
        break;
      default:
        title = 'لا توجد طلبات بعد';
        subtitle = 'ابدأ بالتسوق وإضافة الحلويات اللذيذة\nإلى سلتك واستمتع بأشهى المذاقات';
        icon = Icons.receipt_long;
    }
 
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.backgroundLight,
            AppColors.backgroundWhite,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryColor, AppColors.primaryLightColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              // إظهار زر "ابدأ التسوق" فقط إذا كان الفلتر "الكل" أو لا توجد طلبات على الإطلاق
              if (_selectedFilter == 'all' || _orders.isEmpty)
                                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.buttonColor, AppColors.buttonLightColor],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                  child: ElevatedButton(
                    onPressed: widget.onNavigateToHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cake,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'ابدأ التسوق',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _filteredOrders().length,
        itemBuilder: (context, index) {
          final order = _filteredOrders()[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    Widget chip(String key, String label, Color color) {
      final selected = _selectedFilter == key;
      return Padding(
        padding: const EdgeInsets.only(right: 8, left: 8, top: 12),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => setState(() => _selectedFilter = key),
                  selectedColor: color.withOpacity(0.15),
        labelStyle: TextStyle(color: selected ? color : AppColors.textPrimary, fontWeight: FontWeight.w600),
        shape: StadiumBorder(side: BorderSide(color: selected ? color : Colors.grey[300]!)),
        backgroundColor: AppColors.backgroundWhite,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          chip('all', 'الكل', Colors.grey),
          chip('processing', 'قيد المعالجة', Colors.orange),
          chip('delivering', 'قيد التوصيل', Colors.indigo),
          chip('delivered', 'تم التوصيل', Colors.green),
          chip('cancelled', 'ملغي', Colors.red),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس البطاقة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'طلب #${order.id.length >= 8 ? order.id.substring(0, 8) : order.id}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _copyOrderId(order.id),
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.copy,
                          size: 16,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                _buildStatusChip(order.status),
              ],
            ),
            
            SizedBox(height: 12),
            
            // تفاصيل الطلب
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Text(
                  _formatDate(order.createdAt),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.deliveryAddress ?? 'غير محدد',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // المبلغ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المجموع:',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${order.totalAmount.toStringAsFixed(0)} دينار',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // أزرار الإجراءات
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _generateInvoice(order),
                    icon: Icon(Icons.receipt_long, size: 16),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      side: BorderSide(color: AppColors.primaryColor),
                    ),
                    label: Text('عرض الفاتورة'),
                  ),
                ),
                SizedBox(width: 12),
                if (order.status == 'processing')
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancelOrder(order.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[600],
                        side: BorderSide(color: Colors.red[600]!),
                      ),
                      child: Text('إلغاء الطلب'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'processing':
        color = Colors.orange;
        text = 'قيد المعالجة';
        break;
      case 'confirmed':
        color = Colors.blue;
        text = 'مؤكد';
        break;
      case 'preparing':
        color = Colors.purple;
        text = 'قيد التحضير';
        break;
      case 'delivering':
        color = Colors.indigo;
        text = 'قيد التوصيل';
        break;
      case 'delivered':
        color = Colors.green;
        text = 'تم التوصيل';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'ملغي';
        break;
      default:
        color = Colors.grey;
        text = 'غير محدد';
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _copyOrderId(String orderId) {
    // نسخ أول 8 أحرف فقط من رقم الطلب
    final shortOrderId = orderId.length >= 8 ? orderId.substring(0, 8) : orderId;
    Clipboard.setData(ClipboardData(text: shortOrderId));
    
    // إظهار رسالة تأكيد
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Text('تم نسخ رقم الطلب: $shortOrderId'),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _generateInvoice(OrderModel order) async {
    try {
      // إظهار مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
              SizedBox(width: 20),
              Text('جاري تحميل الفاتورة...'),
            ],
          ),
        ),
      );

      // الحصول على تفاصيل الطلب
      final orderDetails = await OrderService.getOrderDetails(order.id);
      final items = orderDetails['items'] as List<OrderItemModel>;

      // إغلاق مؤشر التحميل
      Navigator.pop(context);

      // إنشاء الفاتورة
      await InvoiceService.generateInvoice(
        order: order,
        items: items,
        companyName: 'لمسة',
        companyAddress: 'العراق - بغداد',
      );

      // إظهار رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('تم إنشاء الفاتورة بنجاح'),
            ],
          ),
          backgroundColor: Colors.green[600],
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      // إغلاق مؤشر التحميل في حالة الخطأ
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // طباعة تفاصيل الخطأ للتشخيص
      print('خطأ في إنشاء الفاتورة: $e');

      // إظهار رسالة خطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('حدث خطأ في إنشاء الفاتورة: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red[600],
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _cancelOrder(String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إلغاء الطلب'),
        content: Text('هل أنت متأكد من إلغاء هذا الطلب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // حفظ مرجع للـ ScaffoldMessenger قبل إغلاق الـ dialog
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              
              try {
                await OrderService.updateOrderStatus(orderId, 'cancelled');
                if (mounted) {
                  _loadOrders(); // إعادة تحميل الطلبات
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('تم إلغاء الطلب بنجاح'),
                      backgroundColor: Colors.green[600],
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('فشل في إلغاء الطلب'),
                      backgroundColor: Colors.red[600],
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('تأكيد'),
          ),
        ],
      ),
    );
  }
}

