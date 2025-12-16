// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/cart_provider.dart';
import '../../../widgets/common/custom_app_bar.dart';
import '../../../utils/colors.dart';
import '../../../services/user_service.dart';
import '../../../services/order_service.dart';
import '../../../models/order_model.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String address;

  const OrderConfirmationScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  @override
  _OrderConfirmationScreenState createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    
    // تحميل السلة من Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadCart();
    });
    
    // تحميل بيانات المستخدم المحفوظة
    _loadUserData();
    
    // تحميل ملاحظات الطلب العامة من السلة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = context.read<CartProvider>();
      if (cartProvider.orderNotes != null && cartProvider.orderNotes!.isNotEmpty) {
        _notesController.text = cartProvider.orderNotes!;
      }
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'تأكيد الطلب',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات العميل
            _buildCustomerInfoSection(),
            
            SizedBox(height: 10),
            
            // معلومات التوصيل
            _buildDeliveryInfoSection(),
            
            SizedBox(height: 10),
            
            // ملخص الطلب
            _buildOrderSummarySection(),
            
            SizedBox(height: 10),
            
            // زر تأكيد الطلب
            _buildSubmitButton(),
          ],
        ),
      ),

    );
  }

  Widget _buildCustomerInfoSection() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: AppColors.primaryColor,
              ),
              SizedBox(width: 8),
              Text(
                'معلومات المستلم',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          
          // اسم العميل
          TextField(
            controller: _customerNameController,
            decoration: InputDecoration(
              labelText: 'الاسم الكامل *',
              hintText: 'أدخل اسمك الكامل',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryColor),
              ),
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          
          SizedBox(height: 6),
          
          // رقم الهاتف
          TextField(
            controller: _customerPhoneController,
            keyboardType: TextInputType.phone,
            maxLength: 11,
            onChanged: (value) {
              // تنسيق رقم الهاتف العراقي
              _formatPhoneNumber(value);
            },
            decoration: InputDecoration(
              labelText: 'رقم الهاتف *',
              hintText: 'أدخل رقم هاتفك',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryColor),
              ),
              prefixIcon: Icon(Icons.phone),
              counterText: '', // إخفاء عداد الأحرف
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoSection() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppColors.primaryColor,
              ),
              SizedBox(width: 8),
              Text(
                'معلومات التوصيل',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          
          // العنوان
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primaryColor,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'العنوان',
                                              style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.address,
                                              style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 6),
          
          // ملاحظات التوصيل
          TextField(
            controller: _notesController,
            maxLines: 3,
            onChanged: (value) {
              // تحديث ملاحظات الطلب العامة في CartProvider عند تغيير النص
              final cartProvider = context.read<CartProvider>();
              cartProvider.setOrderNotes(value.trim().isEmpty ? null : value.trim());
            },
            decoration: InputDecoration(
              labelText: 'ملاحظات الطلب (اختياري)',
              hintText: 'مثال: طابق معين، علامات مميزة، ملاحظات خاصة...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryColor),
              ),
              prefixIcon: Icon(Icons.note),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummarySection() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        return Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shopping_cart,
                    color: AppColors.primaryColor,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ملخص الطلب',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              
              // قائمة المنتجات
              ...cartProvider.items.map((item) => Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.productName,
                                              style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      ),
                    ),
                    Text(
                      '${item.quantity} × ${item.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      '${item.subtotal.toStringAsFixed(0)} دينار',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              )),
              
              Divider(height: 8),
              
              // المجموع
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'المجموع',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${cartProvider.totalAmount.toStringAsFixed(0)} دينار',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : () => _submitOrder(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isSubmitting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'تأكيد الطلب',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  /// تحميل بيانات المستخدم من قاعدة البيانات وملء الحقول تلقائياً
  void _loadUserData() async {
    try {
      // تحميل بيانات المستخدم من قاعدة البيانات
      final userData = await UserService.getCurrentUser();
      
      if (userData != null) {
        
        // ملء الحقول ببيانات المستخدم
        setState(() {
          _customerNameController.text = userData['name'] ?? '';
          String phoneNumber = userData['phone_number'] ?? '';
          _customerPhoneController.text = phoneNumber;
          
          // تطبيق تنسيق رقم الهاتف إذا كان موجوداً
          if (phoneNumber.isNotEmpty) {
            _formatPhoneNumber(phoneNumber);
          }
        });
        
      } else {
        // إذا لم يتم العثور على بيانات المستخدم، اترك الحقول فارغة
        setState(() {
          _customerNameController.clear();
          _customerPhoneController.clear();
        });
      }
    } catch (e) {
      // في حالة الخطأ، اترك الحقول فارغة ويمكن للمستخدم ملؤها يدوياً
      setState(() {
        _customerNameController.clear();
        _customerPhoneController.clear();
      });
    }
  }

  void _formatPhoneNumber(String value) {
    // إزالة جميع الأحرف غير الرقمية
    String numbersOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    // التحقق من طول الرقم
    if (numbersOnly.length > 11) {
      numbersOnly = numbersOnly.substring(0, 11);
    }
    
    // تنسيق الرقم
    String formattedNumber = '';
    if (numbersOnly.length == 10 && numbersOnly.startsWith('7')) {
      // رقم من 10 أرقام يبدأ بـ 7
      formattedNumber = '0$numbersOnly';
    } else if (numbersOnly.length == 11 && numbersOnly.startsWith('07')) {
      // رقم من 11 رقم يبدأ بـ 07
      formattedNumber = numbersOnly;
    // ignore: prefer_is_empty
    } else if (numbersOnly.length > 0) {
      // أي رقم آخر
      formattedNumber = numbersOnly;
    }
    
    // تحديث النص في الحقل إذا كان مختلفاً
    if (_customerPhoneController.text != formattedNumber) {
      _customerPhoneController.value = TextEditingValue(
        text: formattedNumber,
        selection: TextSelection.collapsed(offset: formattedNumber.length),
      );
    }
  }

  bool _isValidIraqiPhoneNumber(String phoneNumber) {
    // إزالة جميع الأحرف غير الرقمية
    String numbersOnly = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    // التحقق من صحة الرقم العراقي
    if (numbersOnly.length == 11 && numbersOnly.startsWith('07')) {
      // رقم من 11 رقم يبدأ بـ 07
      return true;
    } else if (numbersOnly.length == 10 && numbersOnly.startsWith('7')) {
      // رقم من 10 أرقام يبدأ بـ 7
      return true;
    }
    
    return false;
  }

  void _submitOrder() async {
    // التحقق من صحة البيانات
    if (_customerNameController.text.trim().isEmpty) {
      _showError('يرجى إدخال الاسم الكامل');
      return;
    }

    if (_customerPhoneController.text.trim().isEmpty) {
      _showError('يرجى إدخال رقم الهاتف');
      return;
    }

    if (!_isValidIraqiPhoneNumber(_customerPhoneController.text.trim())) {
      _showError('يرجى إدخال رقم هاتف صحيح');
      return;
    }

    final cartProvider = context.read<CartProvider>();
    if (cartProvider.isEmpty) {
      _showError('السلة فارغة');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      print('🔄 بدء عملية تأكيد الطلب...');
      // الحصول على معرف المستخدم الحالي
      final currentUser = Supabase.instance.client.auth.currentUser;
      final userId = currentUser?.id;

      // تنسيق رقم الهاتف قبل الحفظ
      String formattedPhone = _customerPhoneController.text.trim();
      if (formattedPhone.length == 10 && formattedPhone.startsWith('7')) {
        formattedPhone = '0$formattedPhone';
      }

      // تحديث ملاحظات الطلب العامة في CartProvider
      cartProvider.setOrderNotes(_notesController.text.trim().isEmpty ? null : _notesController.text.trim());

      // إنشاء الطلب
      final order = OrderModel(
        id: '', // سيتم إنشاؤه تلقائياً من قاعدة البيانات
        userId: userId,
        customerName: _customerNameController.text.trim(),
        customerPhone: formattedPhone,
        deliveryLatitude: widget.latitude,
        deliveryLongitude: widget.longitude,
        deliveryAddress: widget.address,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        status: 'processing',
        totalAmount: cartProvider.totalAmount,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // حفظ الطلب في قاعدة البيانات
      print('🔄 استدعاء OrderService.saveOrder...');
      final orderId = await OrderService.saveOrder(order);
      print('✅ تم الحصول على معرف الطلب: $orderId');

      // مسح السلة (محلياً وقاعدة البيانات)
      print('🔄 مسح السلة...');
      await cartProvider.clear();
      print('✅ تم مسح السلة بنجاح');

      // عرض رسالة نجاح
      _showSuccess();

      // الانتقال إلى الصفحة الرئيسية ومسح جميع الصفحات السابقة
      Navigator.pushNamedAndRemoveUntil(
        // ignore: use_build_context_synchronously
        context,
        '/home',
        (route) => false,
      );

    } catch (e) {
      print(' خطأ أثناء إرسال الطلب .يرجى المحاولة مرة أخرى $e');
      _showError('حدث خطأ أثناء إرسال الطلب. يرجى المحاولة مرة أخرى');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إرسال طلبك بنجاح! سنتواصل معك قريباً'),
        backgroundColor: Colors.green[600],
        duration: Duration(seconds: 4),
      ),
    );
  }
}
