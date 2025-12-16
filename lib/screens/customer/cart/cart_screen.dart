// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:lamsa/screens/customer/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../providers/cart_provider.dart';
import '../../../services/cart_service.dart';
import '../../../services/user_service.dart';
import '../../../services/app_settings_service.dart';
import '../../../utils/colors.dart';
import '../../../widgets/common/connectivity_wrapper.dart';
import '../../../utils/error_handler.dart';
import '../../../utils/jwt_error_handler.dart';



// محتوى صفحة السلة
class CartContent extends StatefulWidget {
  const CartContent({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CartContentState createState() => _CartContentState();
}

class _CartContentState extends State<CartContent> {
  @override
  void initState() {
    super.initState();
    
    // التحقق من اكتمال بيانات المستخدم
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser != null) {
          final isProfileComplete = await UserService.isUserProfileComplete(currentUser.id);
          // إذا رجعت false فقط (وليس استثناء)، فالبيانات فعلاً غير مكتملة
          if (!isProfileComplete && mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
          }
        }
      } catch (e) {
        // إذا حدث خطأ (مثل فشل الشبكة)، لا نوجه للـ login
        // نتحقق فقط من أخطاء JWT
        if (ErrorHandler.isJwtError(e)) {
          // ignore: use_build_context_synchronously
          JwtErrorHandler.handleJwtError(context, e);
        }
        // في حالة أخطاء الشبكة الأخرى، نتجاهلها ونسمح للمستخدم بالاستمرار
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityWrapper(
      child: Scaffold(
        body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          return cartProvider.isEmpty
              ? _buildEmptyCart(context)
              : _buildCartContent(context, cartProvider);
        },
      ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
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
                    colors: [AppColors.buttonColor, AppColors.buttonLightColor],
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
                  Icons.shopping_cart_outlined,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 24),
                              Text(
                  'سلتك فارغة',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              SizedBox(height: 8),
                              Text(
                  'أضف بعض الحلويات اللذيذة إلى سلتك\nواستمتع بأشهى المذاقات',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              SizedBox(height: 32),
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
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  },
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
                        'تصفح الحلويات',
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

  Widget _buildCartContent(BuildContext context, CartProvider cartProvider) {
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
      child: Column(
        children: [
          // قائمة المنتجات
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: cartProvider.items.length,
              itemBuilder: (context, index) {
                final item = cartProvider.items[index];
                return _buildCartItem(context, item, cartProvider);
              },
            ),
          ),
          
          // العرض الترويجي
          FutureBuilder<String?>(
            future: AppSettingsService.getPromotionalOffer(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.buttonColor, AppColors.buttonLightColor],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.2),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_offer,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          snapshot.data!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),
          
          SizedBox(height: 8),
          
          // ملخص الطلب
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor.withOpacity(0.08),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'المجموع الكلي',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${cartProvider.totalAmount.toStringAsFixed(0)} دينار',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                                  Container(
                    width: double.infinity,
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
                    onPressed: () {
                      // التحقق من أن مجموع الطلب أكبر أو يساوي 20000 دينار
                      if (cartProvider.totalAmount >= 20000) {
                        Navigator.pushNamed(context, '/location');
                      } else {
                        // عرض تنبيه إذا كان المجموع أقل من المطلوب
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'يجب أن يكون الطلب أكبر أو يساوي 20 ألف دينار',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.orange[600],
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: EdgeInsets.all(16),
                            duration: Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_checkout,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'إتمام الطلب',
                          style: TextStyle(
                            fontSize: 16,
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
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item, CartProvider cartProvider) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.06),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(item.imageUrl ?? 'https://via.placeholder.com/70'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '${item.price.toStringAsFixed(0)} دينار',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
                // عرض نوع الطلب
                if (item.isCarton) ...[
                  SizedBox(height: 2),
                  Text(
                    'طلب كارتون',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[600],
                    ),
                  ),
                ] else ...[
                  SizedBox(height: 2),
                  Text(
                    'طلب قطعة',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green[600],
                    ),
                  ),
                ],
                SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: cartProvider.isLoading ? null : () async {
                              if (item.quantity > 1) {
                                await cartProvider.updateQuantity(item.productId, item.quantity - 1);
                              } else {
                                await cartProvider.removeItem(item.productId);
                              }
                            },
                            icon: Icon(Icons.remove, size: 16),
                            color: Colors.red[400],
                            padding: EdgeInsets.all(6),
                            constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${item.quantity}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: cartProvider.isLoading ? null : () async {
                              await cartProvider.updateQuantity(item.productId, item.quantity + 1);
                            },
                            icon: Icon(Icons.add, size: 16),
                            color: Colors.green[600],
                            padding: EdgeInsets.all(6),
                            constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'المجموع',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${item.subtotal.toStringAsFixed(0)} دينار',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

