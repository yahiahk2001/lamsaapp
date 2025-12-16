// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/user_service.dart';
import '../../../models/user_model.dart';
import '../../../utils/colors.dart';
import '../../../widgets/common/connectivity_wrapper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _userData;
  bool _isLoading = true;
  bool _isUpdatingProfile = false;
  bool _showProfileUpdate = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    UserService.checkTableStructure();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser != null) {
          final isProfileComplete = await UserService.isUserProfileComplete(currentUser.id);
          if (!isProfileComplete && mounted) {
            // يمكن إضافة منطق هنا إذا لزم الأمر
          }
        }
      } catch (e) {
        // إذا حدث خطأ (مثل فشل الشبكة)، نتجاهله ونسمح للمستخدم بالاستمرار
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userData = await UserService.getCurrentUser();
      
      if (userData != null) {
       
        setState(() {
          _userData = UserModel.fromJson(userData);
          _phoneController.text = _userData!.phoneNumber ?? '';
          _nameController.text = _userData!.name ?? '';
        });
        
      } else {
        
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser != null) {
          setState(() {
            _userData = UserModel(
              id: currentUser.id,
              email: currentUser.email ?? '',
              name: currentUser.userMetadata?['full_name'] ?? currentUser.email?.split('@')[0] ?? 'مستخدم',
              phoneNumber: null,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          });
          
          _createUserInDatabase(currentUser);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في تحميل بيانات المستخدم: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        setState(() {
          _userData = UserModel(
            id: currentUser.id,
            email: currentUser.email ?? '',
            name: currentUser.userMetadata?['full_name'] ?? currentUser.email?.split('@')[0] ?? 'مستخدم',
            phoneNumber: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        });
      }
    } finally {
      if(mounted){
        setState(() {
        _isLoading = false;
      });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يرجى إدخال الاسم'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isUpdatingProfile = true;
      });

      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('المستخدم غير مسجل دخول');
      }

      await UserService.updateUserProfile(
        currentUser.id,
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );

      
      await _loadUserData();

      setState(() {
        _showProfileUpdate = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث معلوماتك الشخصية بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      
      if (e.toString().contains('PGRST116') || e.toString().contains('0 rows')) {
        try {
          final currentUser = Supabase.instance.client.auth.currentUser;
          if (currentUser != null) {
            final userData = {
              'id': currentUser.id,
              'email': currentUser.email,
              'name': _nameController.text.trim(),
              'phone_number': _phoneController.text.trim(),
              'user_type': 'customer',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            };

            await Supabase.instance.client.from('users').insert(userData);
            
            await _loadUserData();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم إنشاء الملف الشخصي وتحديث معلوماتك بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
            return;
          }
        // ignore: empty_catches
        } catch (createError) {
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في تحديث معلوماتك: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdatingProfile = false;
      });
    }
  }

  Future<void> _createUserInDatabase(User currentUser) async {
    try {
      
      final userData = {
        'id': currentUser.id,
        'email': currentUser.email ?? '',
        'name': currentUser.userMetadata?['full_name'] ?? currentUser.email?.split('@')[0] ?? 'مستخدم',
        'phone_number': null,
        'user_type': 'customer',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client.from('users').insert(userData);
      
      await _loadUserData();
      
    // ignore: empty_catches
    } catch (e) {
    }
  }

  Future<void> _showLogoutConfirmation() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.logout,
                  color: Colors.red[600],
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'تأكيد تسجيل الخروج',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            'هل أنت متأكد من رغبتك في تسجيل الخروج من التطبيق؟',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
                    ),
                    child: Text(
                      'إلغاء',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _signOut();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'تأكيد',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          actionsPadding: EdgeInsets.fromLTRB(24, 0, 24, 24),
        );
      },
    );
  }

  Future<void> _signOut() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();
      
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تسجيل الخروج')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityWrapper(
      child: Scaffold(
        
        backgroundColor: AppColors.backgroundLight,
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.buttonColor),
                ),
              )
            : CustomScrollView(
                slivers: [
                  // Header مع أيقونة المستخدم الكبيرة
                  SliverAppBar(
                    expandedHeight: 280,
                    floating: false,
                    pinned: true,
                    backgroundColor: AppColors.buttonColor,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.buttonColor,
                              AppColors.buttonLightColor,
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 60),
                            // أيقونة المستخدم الكبيرة
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.person,
                                size: 60,
                                color: AppColors.buttonColor,
                              ),
                            ),
                            SizedBox(height: 20),
                            // اسم المستخدم
                            Text(
                              _userData?.name ?? 'مستخدم',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                           
                        
                            
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // محتوى الصفحة
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // معلومات المستخدم
                          _buildInfoSection(),
                          
                          SizedBox(height: 32),
                          
                          // زر تعديل المعلومات
                          if (!_showProfileUpdate)
                            _buildActionButton(
                              icon: Icons.edit,
                              label: 'تعديل معلوماتي',
                              onTap: () {
                                setState(() {
                                  _showProfileUpdate = true;
                                  _nameController.text = _userData?.name ?? '';
                                  _phoneController.text = _userData?.phoneNumber ?? '';
                                });
                              },
                              isPrimary: true,
                            ),
                          
                          // حقول التعديل
                          if (_showProfileUpdate) ...[
                            SizedBox(height: 24),
                            _buildEditSection(),
                          ],
                          
                          SizedBox(height: 32),
                          
                          // الأزرار الإضافية
                          _buildActionButton(
                            icon: Icons.privacy_tip,
                            label: 'سياسة الخصوصية',
                            onTap: () async {
                              final url = Uri.parse('https://poolicy-and-privecy-lamsaa-appp.netlify.app/');
                              try {
                                final canLaunch = await canLaunchUrl(url);
                                if (canLaunch) {
                                  final result = await launchUrl(
                                    url,
                                    mode: LaunchMode.externalApplication,
                                  );
                                  if (!result) {
                                    throw 'فشل في فتح الرابط';
                                  }
                                } else {
                                  throw 'لا يمكن فتح هذا الرابط';
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('فشل في فتح الرابط: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          
                          SizedBox(height: 16),
                          
                          _buildActionButton(
                            icon: Icons.info,
                            label: 'من نحن',
                            onTap: () {
                              Navigator.pushNamed(context, '/about-us');
                            },
                          ),
                          
                          SizedBox(height: 16),
                          
                          _buildActionButton(
                            icon: Icons.support_agent_rounded,
                            label: 'الدعم الفني',
                            onTap: () {
                              Navigator.pushNamed(context, '/support');
                            },
                          ),
                          
                          SizedBox(height: 16),
                          
                          _buildActionButton(
                            icon: Icons.code,
                            label: 'مطور لمسة',
                            onTap: () {
                              Navigator.pushNamed(context, '/developer');
                            },
                          ),
                          
                          SizedBox(height: 32),
                          
                          // زر تسجيل الخروج
                          _buildActionButton(
                            icon: Icons.logout,
                            label: 'تسجيل الخروج',
                            onTap: _showLogoutConfirmation,
                            isLogout: true,
                          ),
                          
                          SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'معلوماتي',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 20),
        _buildInfoRow('الاسم', _userData?.name ?? 'غير محدد'),
        SizedBox(height: 16),
        _buildInfoRow('رقم الهاتف', _userData?.phoneNumber ?? 'غير محدد'),
      ],
    );
  }

  Widget _buildEditSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تعديل المعلومات',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 20),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'الاسم',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.buttonColor, width: 2),
            ),
            prefixIcon: Icon(Icons.person, color: AppColors.textSecondary),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'رقم الهاتف',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.buttonColor, width: 2),
            ),
            prefixIcon: Icon(Icons.phone, color: AppColors.textSecondary),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isUpdatingProfile ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isUpdatingProfile
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'حفظ التغييرات',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _showProfileUpdate = false;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
                ),
                child: Text(
                  'إلغاء',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    bool isLogout = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: isLogout 
                  ? Colors.red[50] 
                  : isPrimary 
                      ? AppColors.buttonColor
                      : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLogout 
                    ? Colors.red[200]! 
                    : isPrimary 
                        ? AppColors.buttonColor
                        : AppColors.textSecondary.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  icon, 
                  color: isLogout 
                      ? Colors.red[600] 
                      : isPrimary 
                          ? Colors.white
                          : AppColors.textSecondary, 
                  size: 24,
                ),
                SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: isLogout 
                        ? Colors.red[700] 
                        : isPrimary 
                            ? Colors.white
                            : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.arrow_back_ios,
                  color: isLogout 
                      ? Colors.red[400] 
                      : isPrimary 
                          ? Colors.white.withOpacity(0.8)
                          : AppColors.textSecondary.withOpacity(0.6),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
