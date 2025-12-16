import 'package:flutter/material.dart';
import 'package:lamsa/screens/customer/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lamsa/screens/customer/cart/cart_screen.dart';
import '../../../models/category_model.dart';
import '../../../models/product_model.dart';
import '../../../services/api_service.dart';
import '../../../services/user_service.dart';
import '../../../widgets/common/loading_widget.dart';
import '../../../providers/cart_provider.dart';
import '../../../utils/colors.dart';
import '../../../widgets/common/connectivity_wrapper.dart';
import '../../../widgets/common/product_card.dart';

class CategoryProductsScreen extends StatefulWidget {
  final CategoryModel category;
  
  const CategoryProductsScreen({super.key, required this.category});
  
  @override
  // ignore: library_private_types_in_public_api
  _CategoryProductsScreenState createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  List<ProductModel> _products = [];
  bool _isLoading = true;
  String? _error;
  String _sortBy = 'name'; // name, price_asc, price_desc
  String _searchQuery = '';
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadProducts();
    
    // تحميل السلة من Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadCart();
    });
    
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
        // نسمح للمستخدم بالاستمرار في استخدام التطبيق
      }
    });
  }

  Future<void> _loadProducts() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final products = await ApiService.getProductsByCategory(widget.category.id);
     if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'حدث خطأ في تحميل المنتجات';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProductModel> get _filteredProducts {
    List<ProductModel> filtered = _products;
    
    // تطبيق البحث
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) =>
        product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (product.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }
    
    // تطبيق الترتيب
    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'price_asc':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
    }
    
    return filtered;
  }



  @override
  Widget build(BuildContext context) {
    return ConnectivityWrapper(
      child: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
                  surfaceTintColor: AppColors.backgroundWhite,

        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.buttonColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category.name,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          // Cart Button with Badge
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartContent(),
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.only(right: 16),
                  child: Stack(
                    children: [
                      Padding(padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.shopping_cart_rounded,
                        color: AppColors.buttonColor,
                        size: 28,
                      ),),
                      if (cartProvider.totalItems > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  // ignore: deprecated_member_use
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            constraints: BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${cartProvider.totalItems > 99 ? '99+' : cartProvider.totalItems}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث والترتيب
          _buildSearchAndSortBar(),
          
          // قائمة المنتجات
          Expanded(
            child: _isLoading
                ? LoadingWidget()
                : _error != null
                    ? _buildErrorWidget()
                    : _filteredProducts.isEmpty
                        ? _buildEmptyWidget()
                        : _buildProductsGrid(),
          ),
        ],
      ),
      ));
  }

  Widget _buildSearchAndSortBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: AppColors.shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // شريط البحث
                     SizedBox(
             height: 45,
             child: TextField(
               enabled: true,
               controller: _searchController,
               onChanged: (value) {
                 setState(() {
                   _searchQuery = value;
                 });
               },
               decoration: InputDecoration(
                 hintText: 'البحث في ${widget.category.name}...',
                 hintStyle: TextStyle(
                   color: AppColors.textSecondary,
                   fontSize: 14,
                 ),
                 prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                 suffixIcon: _searchQuery.isNotEmpty
                     ? IconButton(
                         icon: Icon(Icons.clear, color: AppColors.textSecondary, size: 20),
                         onPressed: () {
                           setState(() {
                             _searchQuery = '';
                             _searchController.clear();
                           });
                         },
                       )
                     : null,
                 border: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(12),
                   borderSide: BorderSide(color: Colors.grey[300]!),
                 ),
                 enabledBorder: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(12),
                   borderSide: BorderSide(color: Colors.grey[300]!),
                 ),
                 focusedBorder: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(12),
                   borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
                 ),
                 filled: true,
                 fillColor: Colors.grey[50],
                 contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
               ),
               style: TextStyle(
                 fontSize: 14,
                 color: AppColors.textPrimary,
               ),
               textInputAction: TextInputAction.search,
               keyboardType: TextInputType.text,
             ),
           ),
          
          SizedBox(height: 12),
          
          // أزرار الترتيب
          Row(
            children: [
              Text(
                'ترتيب حسب:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSortChip('name', 'الاسم'),
                      SizedBox(width: 8),
                      _buildSortChip('price_asc', 'السعر: من الأقل'),
                      SizedBox(width: 8),
                      _buildSortChip('price_desc', 'السعر: من الأعلى'),
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

  Widget _buildSortChip(String value, String label) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.buttonColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
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
            onPressed: _loadProducts,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cake_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'لا توجد منتجات ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          return ProductCard(product: product);
        },
      ),
    );
  }

}
