// ignore_for_file: use_super_parameters, library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:lamsa/screens/customer/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/product_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../services/user_service.dart';
import '../../../utils/colors.dart';
// removed unused import
import '../cart/cart_screen.dart';
import '../../../widgets/common/connectivity_wrapper.dart';
import 'product_image_viewer_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _selectedImageIndex = 0;
  int _quantity = 1;
  String _orderType = 'piece'; // 'piece' أو 'carton'
  bool _isAddingToCart = false;
  final TextEditingController _orderNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // تحميل السلة من Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadCart();
    });
    
    // تحميل الكمية من السلة إذا كان المنتج موجود فيها
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = context.read<CartProvider>();
      if (cartProvider.containsProduct(widget.product.id)) {
        _quantity = cartProvider.getProductQuantity(widget.product.id);
      }
      
      // تحميل ملاحظات الطلب العامة
      if (cartProvider.orderNotes != null && cartProvider.orderNotes!.isNotEmpty) {
        _orderNotesController.text = cartProvider.orderNotes!;
      }
    });
    
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

  @override
  void dispose() {
    _orderNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityWrapper(
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundWhite,
          elevation: 0,
          surfaceTintColor: AppColors.backgroundWhite,
          
          centerTitle: true,
          title: Text(
            widget.product.name,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: AppColors.buttonColor, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Consumer<CartProvider>(
              builder: (context, cartProvider, child) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CartContent()),
                    );
                  },
                  child: Stack(
                    children: [
                      IconButton(
                        icon: Icon(Icons.shopping_cart, color: AppColors.buttonColor, size: 28),
                        onPressed: null, // تم تعطيل الضغط هنا لأننا نستخدم GestureDetector
                      ),
                      if (cartProvider.totalItems > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            constraints: BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${cartProvider.totalItems}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // صور المنتج
              _buildProductImages(),
              
              SizedBox(height: 16),
              
              // معلومات المنتج الأساسية
              _buildProductInfo(),
              
              SizedBox(height: 16),
              
              // وصف المنتج
              if (widget.product.description != null) ...[
                _buildProductDescription(),
                SizedBox(height: 16),
              ],
              
              // اختيار الكمية والنوع
              _buildOrderOptions(),
              
              SizedBox(height: 16),
              
              // ملاحظات الطلب العامة
              _buildOrderNotesField(),
              
              // مساحة إضافية في الأسفل
              SizedBox(height: 80),
            ],
          ),
        ),
        
        // زر إضافة للسلة ثابت في الأسفل
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }



  Widget _buildProductImages() {
    final images = widget.product.images;
    
    if (images.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cake,
                size: 40,
                color: AppColors.primaryColor,
              ),
              SizedBox(height: 8),
              Text(
                'لا توجد صورة متاحة',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GestureDetector(
              onTap: () {
                // فتح شاشة عرض الصور
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductImageViewerScreen(
                      images: images,
                      initialIndex: _selectedImageIndex,
                    ),
                  ),
                );
              },
              child: PageView.builder(
                itemCount: images.length,
                onPageChanged: (index) {
                  setState(() {
                    _selectedImageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.backgroundLight,
                        child: Center(
                          child: Icon(
                            Icons.cake,
                            size: 40,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppColors.backgroundLight,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          
         
          
          if (images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) {
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    width: _selectedImageIndex == index ? 20 : 6,
                    height: 6,
                    margin: EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: _selectedImageIndex == index 
                          ? Colors.white 
                          : Colors.white.withOpacity(0.5),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // اسم المنتج
          Text(
            widget.product.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 16),
          
          // الأسعار
          Row(
            children: [
              // سعر القطعة
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.buttonColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                     
                      Text(
                        'سعر القطعة',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${widget.product.price.toStringAsFixed(0)} دينار',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(width: 12),
              
              // سعر الكارتون
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      
                      Text(
                        'سعر الكارتون',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.product.cartonPrice != null 
                            ? '${widget.product.cartonPrice!.toStringAsFixed(0)} دينار'
                            : 'غير متوفر',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductDescription() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
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
                Icons.description,
                size: 16,
                color: AppColors.primaryColor,
              ),
              SizedBox(width: 8),
              Text(
                'الوصف',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            widget.product.description!,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  double _getCurrentPrice() {
    if (_orderType == 'carton' && widget.product.cartonPrice != null) {
      return widget.product.cartonPrice!;
    }
    return widget.product.price;
  }

  Widget _buildOrderOptions() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
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
                Icons.shopping_basket,
                size: 16,
                color: AppColors.buttonColor,
              ),
              SizedBox(width: 8),
              Text(
                'خيارات الطلب',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // اختيار نوع الطلب
          Center(
            child: Text(
              'نوع الطلب',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _orderType = 'piece';
                      _quantity = 1;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _orderType == 'piece' ? AppColors.buttonColor : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _orderType == 'piece' ? AppColors.buttonColor : AppColors.textSecondary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cake,
                          size: 14,
                          color: _orderType == 'piece' ? Colors.white : AppColors.textSecondary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'قطعة',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _orderType == 'piece' ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (widget.product.cartonPrice != null) {
                      setState(() {
                        _orderType = 'carton';
                        _quantity = 1;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _orderType == 'carton' ? AppColors.buttonColor : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _orderType == 'carton' ? AppColors.buttonColor : AppColors.textSecondary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 14,
                          color: _orderType == 'carton' ? Colors.white : AppColors.textSecondary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'كارتون',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _orderType == 'carton' ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          if (widget.product.cartonPrice == null && _orderType == 'carton')
            Container(
              margin: EdgeInsets.only(top: 8),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red[600], size: 12),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'سعر الكارتون غير متوفر',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          SizedBox(height: 16),
          
          // اختيار الكمية
          Center(
            child: Column(
              children: [
                // عداد الكمية في المنتصف
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'الكمية',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: _quantity > 1 ? AppColors.buttonColor : AppColors.textSecondary.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: () {
                                if (_quantity > 1) {
                                  setState(() {
                                    _quantity--;
                                  });
                                }
                              },
                              icon: Icon(Icons.remove, size: 16),
                              color: _quantity > 1 ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Text(
                              '$_quantity',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.buttonColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: () {
                                setState(() {
                                  _quantity++;
                                });
                              },
                              icon: Icon(Icons.add, size: 16),
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // معلومات السعر أسفل الكمية
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.buttonColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.buttonColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'المجموع',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${(_getCurrentPrice() * _quantity).toStringAsFixed(0)} دينار',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.buttonColor,
                        ),
                      ),
                      Text(
                        '($_quantity ${_orderType == 'carton' ? 'كارتون' : 'قطعة'})',
                        style: TextStyle(
                          fontSize: 8,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderNotesField() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
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
                Icons.edit_note,
                size: 16,
                color: AppColors.primaryColor,
              ),
              SizedBox(width: 8),
              Text(
                'ملاحظات الطلب (اختياري)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          TextField(
            controller: _orderNotesController,
            maxLines: 3,
            onChanged: (value) {
              // تحديث ملاحظات الطلب العامة في CartProvider عند تغيير النص
              final cartProvider = context.read<CartProvider>();
              cartProvider.setOrderNotes(value.trim().isEmpty ? null : value.trim());
            },
            decoration: InputDecoration(
              hintText: 'مثل: طابق معين، علامات مميزة، ملاحظات خاصة...',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 11,
              ),
              filled: true,
              fillColor: AppColors.backgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
              ),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final isInCart = cartProvider.containsProduct(widget.product.id);
          
          return SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: (_isAddingToCart || cartProvider.isLoading) ? null : () => _addToCart(cartProvider),
              icon: (_isAddingToCart || cartProvider.isLoading)
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      isInCart ? Icons.refresh : Icons.add_shopping_cart,
                      color: Colors.white,
                      size: 18,
                    ),
              label: Text(
                isInCart ? 'تحديث في السلة' : 'أضف للسلة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          );
        },
      ),
    );
  }

  void _addToCart(CartProvider cartProvider) async {
    setState(() {
      _isAddingToCart = true;
    });

    try {
      // إضافة المنتج للسلة مع السعر المحدد
      if (_orderType == 'carton' && widget.product.cartonPrice != null) {
        // إنشاء منتج مؤقت مع سعر الكارتون
        final productWithCartonPrice = widget.product.copyWith(
          price: widget.product.cartonPrice!,
        );
        await cartProvider.addItemWithCustomPrice(
          productWithCartonPrice,
          quantity: _quantity,
          notes: null, // لا نستخدم ملاحظات فردية
          isCarton: true,
        );
      } else {
        await cartProvider.addItem(
          widget.product,
          quantity: _quantity,
          notes: null, // لا نستخدم ملاحظات فردية
          isCarton: false,
        );
      }

      // رسالة نجاح
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  cartProvider.containsProduct(widget.product.id)
                      ? 'تم تحديث ${widget.product.name} في السلة'
                      : 'تم إضافة ${widget.product.name} إلى السلة ($_quantity ${_orderType == 'carton' ? 'كارتون' : 'قطعة'})',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'عرض السلة',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartContent()),
              );
            },
          ),
        ),
      );

      // تحديث الواجهة
      setState(() {});
    } catch (e) {
      // رسالة خطأ
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'حدث خطأ أثناء إضافة المنتج للسلة',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isAddingToCart = false;
      });
    }
  }
}