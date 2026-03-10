// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:lamsa/screens/customer/auth/login_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../order/order_confirmation_screen.dart';
import '../../../services/user_service.dart';
import '../../../utils/colors.dart';
import '../../../widgets/common/connectivity_wrapper.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final LatLng _defaultLatLng = LatLng(33.3152, 44.3661); // بغداد
  LatLng _selectedLatLng = LatLng(33.3152, 44.3661);
  MapController? _mapController;
  bool _isLoading = false;
  bool _isGettingLocation = false;
  String _address = 'جاري تحديد العنوان...';
  // ignore: unused_field
  bool _hasLocationPermission = false;
  LatLng? _lastCameraTarget;
  bool _isAnimatingCamera = false;
  bool _isMapReady = false;
  final TextEditingController _searchController = TextEditingController();
  double _currentZoom = 14.0;
  LatLng _currentCenter = LatLng(33.3152, 44.3661);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeLocation();
    
    // التحقق من اكتمال بيانات المستخدم وفحص ميزة الموقع
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // فحص ميزة الموقع أولاً
      await _checkLocationService();
      
      // التحقق من اكتمال بيانات المستخدم
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
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    await _initPermissionState();
    await _determinePositionAndMove();
  }

  Future<void> _checkLocationService() async {
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (mounted) {
        setState(() {
        });
      }
      
      if (!isEnabled && mounted) {
        _showLocationServiceDialog();
      }
    } catch (e) {
      if (mounted) {
        _showLocationServiceDialog();
      }
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.location_off,
                color: Colors.orange,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'ميزة الموقع غير مفعلة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'لا يمكن استخدام الخريطة بدون تفعيل ميزة الموقع في جهازك.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'يرجى تفعيل ميزة الموقع من إعدادات الجهاز للاستمرار.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // العودة للصفحة السابقة
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'إلغاء',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings, size: 18),
                SizedBox(width: 8),
                Text(
                  'فتح الإعدادات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  Future<void> _openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
      
      // فحص ميزة الموقع بعد العودة من الإعدادات
      Future.delayed(Duration(milliseconds: 500), () async {
        if (mounted) {
          final isEnabled = await Geolocator.isLocationServiceEnabled();
          if (isEnabled) {
            setState(() {
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم تفعيل ميزة الموقع بنجاح'),
                backgroundColor: Colors.green[600],
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لا يمكن فتح إعدادات الموقع تلقائياً. يرجى فتحها يدوياً.'),
            backgroundColor: Colors.orange[600],
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityWrapper(
      child: Scaffold(
        body: Column(
          children: [
            // شريط البحث
            _buildSearchBar(),
            // الخريطة
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.35,
              child: _buildMapSection(),
            ),
            // تفاصيل الموقع
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildLocationDetailsWithoutButtons(),
              ),
            ),
            // الأزرار الثابتة في الأسفل
            _buildFixedButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: 'ابحث عن موقع...',
          hintStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(Icons.search, color: AppColors.primaryColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onSubmitted: _searchLocation,
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _defaultLatLng,
                initialZoom: 14,
                onMapReady: () {
                  setState(() {
                    _isMapReady = true;
                  });
                  
                  // تأخير بسيط قبل تحريك الكاميرا
                  Future.delayed(Duration(milliseconds: 500), () {
                    if (_mapController != null) {
                      _moveCamera(_selectedLatLng);
                    }
                  });
                },
                onTap: (tapPosition, point) => _onPositionChanged(point),
                onPositionChanged: (position, hasGesture) {
                  // تحديث الموقع المؤقت أثناء التحريك
                  if (mounted) {
                    setState(() {
                      _currentZoom = position.zoom;
                      _currentCenter = position.center;
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.sweetappp',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLatLng,
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          // يمكن إضافة منطق للسحب هنا
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowColor.withOpacity(0.3),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // أزرار التحكم داخل الخريطة
            Positioned(
              right: 16,
              top: 16,
              child: Column(
                children: [
                  // زر التكبير
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundWhite,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowColor.withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _zoomIn,
                      icon: Icon(Icons.add, color: AppColors.textPrimary),
                      padding: EdgeInsets.all(8),
                      constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                  ),
                  SizedBox(height: 8),
                  // زر التصغير
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundWhite,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowColor.withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _zoomOut,
                      icon: Icon(Icons.remove, color: AppColors.textPrimary),
                      padding: EdgeInsets.all(8),
                      constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                  ),
                ],
              ),
            ),
            // زر تحديد الموقع الحالي
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowColor.withOpacity(0.3),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _getCurrentLocation,
                  icon: _isGettingLocation
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.my_location, color: Colors.white),
                  padding: EdgeInsets.all(12),
                  constraints: BoxConstraints(minWidth: 48, minHeight: 48),
                ),
              ),
            ),
            // مؤشر التحميل على الخريطة
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundWhite,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                        ),
                        SizedBox(height: 8),
                        Text('جاري تحديد الموقع...'),
                      ],
                    ),
                  ),
                ),
              ),
            // مؤشر تحميل الخريطة
            if (!_isMapReady)
              Container(
                color: AppColors.backgroundLight,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'جاري تحميل الخريطة...',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'تأكد من اتصالك بالإنترنت',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDetailsWithoutButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تفاصيل الموقع',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16),
        
        // العنوان
        _buildInfoCard(
          icon: Icons.location_on,
          title: 'العنوان',
          content: _address,
          isLoading: _address == 'جاري تحديد العنوان...',
        ),
        
        SizedBox(height: 12),
        
        // الإحداثيات
        _buildInfoCard(
          icon: Icons.gps_fixed,
          title: 'الإحداثيات',
          content: '${_selectedLatLng.latitude.toStringAsFixed(6)}, ${_selectedLatLng.longitude.toStringAsFixed(6)}',
        ),
        
      
      ],
    );
  }

  Widget _buildFixedButtons() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: _isGettingLocation
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.my_location),
              label: Text('موقعي الحالي'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isLoading || _address == 'جاري تحديد العنوان...' 
                  ? null 
                  : _confirmLocation,
              icon: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.check_circle),
              label: Text('تأكيد الموقع'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    bool isLoading = false,
    bool isInfo = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isInfo ? AppColors.buttonColor.withOpacity(0.1) : AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isInfo ? AppColors.buttonColor.withOpacity(0.3) : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isInfo ? AppColors.buttonColor : AppColors.primaryColor,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                isLoading
                    ? Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            content,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      )
                    : Text(
                        content,
                        style: TextStyle(
                          fontSize: isInfo ? 14 : 16,
                          fontWeight: isInfo ? FontWeight.normal : FontWeight.w600,
                          color: isInfo ? AppColors.buttonColor : AppColors.textPrimary,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Future<void> _initPermissionState() async {
    try {
      final permission = await Geolocator.checkPermission();
      final hasPermission = permission == LocationPermission.always || 
                           permission == LocationPermission.whileInUse;
      if (mounted) {
        setState(() {
          _hasLocationPermission = hasPermission;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasLocationPermission = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _isLoading = true;
    });

    try {
      // فحص ميزة الموقع أولاً
      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        if (mounted) {
          setState(() {
            _isGettingLocation = false;
            _isLoading = false;
          });
          _showLocationServiceDialog();
        }
        return;
      }

      await _ensureLocationPermission();
      await _initPermissionState();
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      final latLng = LatLng(position.latitude, position.longitude);
      await _moveCamera(latLng);
      await _reverseGeocode(latLng);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديد موقعك الحالي بنجاح'),
            backgroundColor: Colors.green[600],
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تحديد الموقع. تأكد من تفعيل GPS والسماح بالوصول للموقع'),
            backgroundColor: Colors.red[600],
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final locations = await geocoding.locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final latLng = LatLng(location.latitude, location.longitude);
        await _moveCamera(latLng);
        await _reverseGeocode(latLng);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم العثور على الموقع'),
              backgroundColor: Colors.green[600],
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('لم يتم العثور على الموقع المطلوب'),
              backgroundColor: Colors.orange[600],
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في البحث عن الموقع'),
            backgroundColor: Colors.red[600],
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _zoomIn() async {
    if (_mapController != null) {
      _mapController!.move(_currentCenter, _currentZoom + 1);
    }
  }

  Future<void> _zoomOut() async {
    if (_mapController != null) {
      _mapController!.move(_currentCenter, _currentZoom - 1);
    }
  }

  void _confirmLocation() {
    // التحقق من أن الموقع محدد
    if (_address == 'جاري تحديد العنوان...' || _address == 'العنوان غير متاح') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى تحديد الموقع أولاً'),
          backgroundColor: Colors.orange[600],
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // إظهار تأكيد
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.location_on,
                color: AppColors.primaryColor,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'تأكيد الموقع',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل تريد تأكيد هذا الموقع؟',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _address,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'إلغاء',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // الانتقال إلى صفحة تأكيد الطلب
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderConfirmationScreen(
                    latitude: _selectedLatLng.latitude,
                    longitude: _selectedLatLng.longitude,
                    address: _address,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 18),
                SizedBox(width: 8),
                Text(
                  'تأكيد',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  Future<void> _determinePositionAndMove() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();
      final hasPermission = permission == LocationPermission.always || 
                           permission == LocationPermission.whileInUse;

      if (serviceEnabled && hasPermission) {
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          );
          final latLng = LatLng(position.latitude, position.longitude);
          await _moveCamera(latLng);
          await _reverseGeocode(latLng);
          return;
        } catch (_) {
          // في حالة فشل الحصول على الموقع الحالي، استخدم الموقع الافتراضي
        }
      }
      
      // استخدام الموقع الافتراضي
      await _moveCamera(_defaultLatLng);
      await _reverseGeocode(_defaultLatLng);
    } catch (_) {
      await _moveCamera(_defaultLatLng);
      await _reverseGeocode(_defaultLatLng);
    }
  }

  Future<void> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('خدمة تحديد الموقع غير مفعلة');
    }
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('تم رفض إذن الوصول للموقع');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('تم رفض إذن الوصول للموقع بشكل دائم. يرجى تفعيله من الإعدادات');
    }
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        latLng.latitude, 
        latLng.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[];
        
        // ترتيب أفضل للعنوان العربي
        if (p.street != null && p.street!.isNotEmpty) parts.add(p.street!);
        if (p.subLocality != null && p.subLocality!.isNotEmpty) parts.add(p.subLocality!);
        if (p.locality != null && p.locality!.isNotEmpty) parts.add(p.locality!);
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) parts.add(p.administrativeArea!);
        if (p.country != null && p.country!.isNotEmpty) parts.add(p.country!);
        
        if (mounted) {
          setState(() {
            _address = parts.isNotEmpty ? parts.join('، ') : 'موقع بدون عنوان محدد';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _address = 'موقع بدون عنوان محدد';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _address = 'العنوان غير متاح';
        });
      }
    }
  }

  Future<void> _moveCamera(LatLng latLng) async {
    const double epsilon = 1e-7;
    final sameTarget = _lastCameraTarget != null &&
        (latLng.latitude - _lastCameraTarget!.latitude).abs() < epsilon &&
        (latLng.longitude - _lastCameraTarget!.longitude).abs() < epsilon;

    if (sameTarget || _isAnimatingCamera || !_isMapReady) {
      if (mounted) {
        setState(() {
          _selectedLatLng = latLng;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _selectedLatLng = latLng;
        _isAnimatingCamera = true;
      });
    }

    try {
      if (_mapController != null) {
        _mapController!.move(latLng, 16);
        _lastCameraTarget = latLng;
        
        // إعادة تحديد العلامة بعد تحريك الكاميرا
        await Future.delayed(Duration(milliseconds: 100));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnimatingCamera = false;
        });
      }
    }
  }

  Future<void> _onPositionChanged(LatLng pos) async {
    await _moveCamera(pos);
    await _reverseGeocode(pos);
  }
}