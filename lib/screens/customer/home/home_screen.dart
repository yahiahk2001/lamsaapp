// ignore_for_file: empty_catches

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lamsa/screens/customer/cart/cart_screen.dart';
import 'package:lamsa/screens/customer/orders/orders_screen.dart';
import 'package:lamsa/screens/customer/notifications/notifications_screen.dart';
import 'package:lamsa/screens/customer/profile/profile_screen.dart';
import '../../../widgets/common/bottom_navigation.dart';
import '../../../widgets/common/advertisement_slider.dart';
import '../../../widgets/common/product_card.dart';
import '../../../providers/home_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../models/category_model.dart';
import '../../../models/advertisement_model.dart';

import '../../../services/cart_service.dart';
import '../../../services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../category/category_products_screen.dart';
import '../category/categories_screen.dart';
import '../search/search_screen.dart';
import '../../../utils/colors.dart';
import '../../../utils/error_handler.dart';
import '../../../utils/jwt_error_handler.dart';
import '../../../utils/exit_confirmation.dart';

class HomeScreen extends StatefulWidget {
  final int initialTabIndex;
  
  const HomeScreen({super.key, this.initialTabIndex = 0});
  
  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  late int _currentIndex;
  
  // قائمة الصفحات مع تحسين الذاكرة
  late final List<Widget> _pages;

  @override
  bool get wantKeepAlive => true; // الحفاظ على حالة الصفحة

  @override
  void initState() {
    super.initState();
    
    // تعيين التبويب المحدد من المعامل
    _currentIndex = widget.initialTabIndex;
    
    // إنشاء قائمة الصفحات مع تمرير callback function
    _pages = [
      _HomeContent(),
      OrdersContent(onNavigateToHome: () {
        setState(() {
          _currentIndex = 0;
        });
      }),
      const ProfileScreen(),
    ];
    
    // تحميل البيانات عند بدء الصفحة مع تحسين الأداء
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeData();
    });
  }

  Future<void> _initializeData() async {
    try {
      // تحميل البيانات الأساسية أولاً
      await context.read<HomeProvider>().loadHomeData();

      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null && mounted) {
        // تحميل البيانات الأخرى في الخلفية دون انتظار
        _initializeBackgroundData(currentUser);
      }
    } catch (e) {
      // التحقق من خطأ JWT وتوجيه المستخدم إذا لزم الأمر
      if (ErrorHandler.isJwtError(e)) {
        // ignore: use_build_context_synchronously
        JwtErrorHandler.handleJwtError(context, e);
      }
    }
  }

  void _initializeBackgroundData(User currentUser) {
    // تشغيل هذه العمليات في الخلفية دون انتظار
    Future.microtask(() async {
      try {
        // تحميل بيانات السلة
        // ignore: use_build_context_synchronously
        context.read<CartProvider>().loadCart();
        
        // تحميل بيانات السلة من الخادم
        await CartService.loadCartItems(currentUser.id);
        if (mounted) {
          context.read<CartProvider>().refresh();
        }
        
        // تهيئة الإشعارات
        // ignore: use_build_context_synchronously
        await context.read<NotificationProvider>().initialize();
        
        // التحقق من اكتمال بيانات المستخدم
        try {
          final isProfileComplete = await UserService.isUserProfileComplete(currentUser.id);
          if (!isProfileComplete && mounted) {
            // التوجيه بعد اكتمال البناء
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            });
          }
        } catch (profileCheckError) {
          // إذا حدث خطأ في التحقق من البيانات (مثل فشل الشبكة)، نتجاهله ونسمح للمستخدم بالاستمرار
        }
      } catch (e) {
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // مطلوب لـ AutomaticKeepAliveClientMixin
    return WillPopScope(
      onWillPop: () async {
        // إذا كان المستخدم في الصفحة الرئيسية (التبويب الأول)
        if (_currentIndex == 0) {
          // إظهار رسالة تأكيد الخروج
          return await ExitConfirmation.showExitConfirmation(context);
        } else {
          // إذا كان في تبويب آخر، العودة للصفحة الرئيسية
          setState(() {
            _currentIndex = 0;
          });
          return false; // منع الخروج من التطبيق
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            // Header Container with Logo and Cart button
            if (_currentIndex == 0) _buildHeaderContainer(),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _pages,
              ),
            ),
            CustomBottomNavigation(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderContainer() {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Notifications Button with Badge (moved to left side)
            Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      const Icon(
                        Icons.notifications_rounded,
                        color: AppColors.buttonColor,
                        size: 28,
                      ),
                      if (notificationProvider.unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              notificationProvider.unreadCount > 99 
                                  ? '99+' 
                                  : notificationProvider.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
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
            // Logo
            Expanded(
              child: SizedBox(
                height: 35,
                child: Image.asset(
                  'assets/logoName.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Cart Button with Badge
            Selector<CartProvider, int>(
              selector: (context, cartProvider) => cartProvider.totalItems,
              builder: (context, totalItems, child) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CartContent(),
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      const Icon(
                        Icons.shopping_cart_rounded,
                        color: AppColors.buttonColor,
                        size: 28,
                      ),
                      if (totalItems > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  // ignore: deprecated_member_use
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${totalItems > 99 ? '99+' : totalItems}',
                              style: const TextStyle(
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// محتوى الصفحة الرئيسية مع تحسينات الأداء
class _HomeContent extends StatefulWidget {
  const _HomeContent();
  
  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;


  @override
  void dispose() {
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    super.build(context); // مطلوب لـ AutomaticKeepAliveClientMixin
    
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        return Column(
          children: [
            // Fixed Search Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: AppColors.primaryColor,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'ابحث عن الحلويات المفضلة...',
                          style: TextStyle(
                            color: Color.fromARGB(255, 103, 109, 114),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Regular Content
            Expanded(
              child: RefreshIndicator(
                backgroundColor: const Color.fromARGB(255, 223, 239, 243),
                color: AppColors.buttonColor,
                onRefresh: () async {
                  try {
                    await context.read<HomeProvider>().refreshData();
                  } catch (e) {
                    // تجاهل الأخطاء في RefreshIndicator لتجنب تعطيله
                  }
                },
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.backgroundLight,
                        AppColors.backgroundWhite,
                      ],
                    ),
                  ),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      // التحقق من الوصول لنهاية القائمة مع التمرير مع مسافة هامش
                      if (!homeProvider.isLoadingMoreProducts && 
                          homeProvider.hasMoreProducts && 
                          scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                        
                        // تجنب الاستدعاءات المتكررة
                        Future.microtask(() {
                          if (!homeProvider.isLoadingMoreProducts && homeProvider.hasMoreProducts) {
                            homeProvider.loadMoreProducts();
                          }
                        });
                      }
                      return false;
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          
                          if (homeProvider.isLoading) ...[
                            _buildLoadingState(),
                          ] else if (homeProvider.error != null) ...[
                            _buildErrorState(homeProvider),
                          ] else ...[
                            // Advertisements Section - Full Width
                            if (homeProvider.advertisements.isNotEmpty) ...[
                              _buildAdvertisementsSection(homeProvider.advertisements),
                              const SizedBox(height: 14),
                            ],
                            
                            // Categories Section - 4 Column Grid
                            if (homeProvider.categories.isNotEmpty) ...[
                              _buildCategoriesSection(homeProvider.categories),
                              const SizedBox(height: 20),
                            ],
                            
                            // Popular Products Section
                            _buildPopularProductsSection(),
                          ],
                          
                          // إضافة مساحة إضافية في النهاية لضمان إمكانية التمرير
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }



  Widget _buildLoadingState() {
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Image.asset(
                'assets/justLogo.png',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'نجهز لك أفضل المنتجات الان ...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(HomeProvider homeProvider) {
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Color(0xFFFFE5E5),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 50,
                  color: Color(0xFFFF6B6B),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'عذراً!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12),
              Text(
                homeProvider.error!,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
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
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: AppColors.buttonColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await homeProvider.refreshData();
                    } catch (e) {
                      
                            // التحقق من خطأ JWT وتوجيه المستخدم إذا لزم الأمر
      if (ErrorHandler.isJwtError(e)) {
        // ignore: use_build_context_synchronously
        JwtErrorHandler.handleJwtError(context, e);
      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'إعادة المحاولة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvertisementsSection(List<AdvertisementModel> advertisements) {
    // فلترة الإعلانات النشطة فقط
    final activeAdvertisements = advertisements
        .where((ad) => ad.isCurrentlyActive)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (activeAdvertisements.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 4),
        Builder(
          builder: (context) => Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AdvertisementSlider(
                advertisements: activeAdvertisements,
                height: 160,
                autoPlayInterval: Duration(seconds: 5),
                autoPlay: true,
                onTap: (advertisement) {
                  if (advertisement.linkUrl != null && advertisement.linkUrl!.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم النقر على: ${advertisement.title ?? "الإعلان"}'),
                        backgroundColor: AppColors.primaryColor,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(List<CategoryModel> categories) {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryColor, AppColors.primaryLightColor],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'الاقسام الرئيسية',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.buttonColor, AppColors.buttonLightColor],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoriesScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Text(
                      'عرض الكل',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.9,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return RepaintBoundary(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryProductsScreen(category: category),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // صورة الفئة مع تحسين الأداء
                      Expanded(
                        flex: 2,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Stack(
                            children: [
                              CachedNetworkImage(
                                imageUrl: category.imageUrl ?? 'https://via.placeholder.com/80x80?text=${category.name}',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.low, // تقليل جودة المرشح لتحسين الأداء
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.image,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                ),
                                memCacheWidth: 150, // تقليل حجم الذاكرة المؤقتة
                                memCacheHeight: 150,
                                maxWidthDiskCache: 300, // تقليل حجم التخزين على القرص
                                maxHeightDiskCache: 300,
                              ),
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black54,
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // اسم الفئة
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                category.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPopularProductsSection() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        final allProducts = homeProvider.allProducts;
        final isLoadingMoreProducts = homeProvider.isLoadingMoreProducts;
        final hasMoreProducts = homeProvider.hasMoreProducts;
        
        
        // إذا لم تكن هناك منتجات، نعرض رسالة
        if (allProducts.isEmpty) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد منتجات متاحة',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'جاري تحميل المنتجات...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.buttonColor),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryColor, AppColors.primaryLightColor],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'المنتجات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // نستخدم scroll الرئيسي الآن
              itemCount: allProducts.length + (hasMoreProducts ? 1 : 0),
              itemBuilder: (context, index) {
                // إذا وصلنا إلى نهاية القائمة وهناك المزيد من المنتجات
                if (index == allProducts.length && hasMoreProducts) {
                  
                  // عرض مؤشر التحميل
                  return Container(
                    height: 80,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.buttonColor),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isLoadingMoreProducts ? 'جاري تحميل المزيد...' : 'تحميل المنتجات...',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                // عرض المنتج
                final product = allProducts[index];
                return ProductCard(product: product);
              },
            ),
          ],
        );
      },
    );
  }
}
