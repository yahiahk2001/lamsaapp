import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../utils/navigation.dart';
import '../utils/colors.dart';
import '../utils/error_handler.dart';
import '../utils/jwt_error_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      
      // انتظار قليل لعرض شاشة التحميل
      await Future.delayed(Duration(seconds: 1));
      
      // الحصول على AuthProvider
      // ignore: use_build_context_synchronously
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // التحقق من حالة تسجيل الدخول في Supabase
      final user = Supabase.instance.client.auth.currentUser;
      
      // التحقق من حالة تسجيل الدخول في AuthProvider
      final authProviderUser = authProvider.currentUser;
      
      // التحقق من الجلسة الحالية
      final session = Supabase.instance.client.auth.currentSession;
      
      if (mounted) {
        // التحقق من وجود جلسة صالحة ومستخدم
        if (session != null && (user != null || authProviderUser != null)) {
          
          // التحقق من اكتمال بيانات المستخدم
          try {
            final isProfileComplete = await UserService.isUserProfileComplete(user?.id ?? authProviderUser?.id ?? '');
            
            if (isProfileComplete) {
              _navigateToHome();
            } else {
              
            }
          } catch (profileCheckError) {
            // إذا فشل التحقق من البيانات (مثل فشل الشبكة)، نفترض أن البيانات مكتملة ونوجه للصفحة الرئيسية
            _navigateToHome();
          }
        } else if (session != null && user == null && authProviderUser == null) {
          // إذا كانت هناك جلسة ولكن لا يوجد مستخدم، نحاول إعادة تحميل الجلسة
          try {
            await Supabase.instance.client.auth.refreshSession();
            final refreshedUser = Supabase.instance.client.auth.currentUser;
            if (refreshedUser != null) {
              
              // التحقق من اكتمال بيانات المستخدم
              try {
                final isProfileComplete = await UserService.isUserProfileComplete(refreshedUser.id);
                
                if (isProfileComplete) {
                  _navigateToHome();
                } else {
                 
                }
              } catch (profileCheckError) {
                // إذا فشل التحقق من البيانات (مثل فشل الشبكة)، نفترض أن البيانات مكتملة ونوجه للصفحة الرئيسية
                _navigateToHome();
              }
            } else {
              _navigateToLogin();
            }
          } catch (e) {
            
            // إذا كان الخطأ بسبب JWT expired، نحاول تسجيل الخروج أولاً
            if (e.toString().contains('JWT expired') || 
                e.toString().contains('Unauthorized') ||
                e.toString().contains('PGRST303')) {
              try {
                await Supabase.instance.client.auth.signOut();
              // ignore: empty_catches
              } catch (signOutError) {
              }
            }
            
            _navigateToLogin();
          }
        } else {
          _navigateToLogin();
        }
      }
    } catch (e) {
      
      // التحقق من خطأ JWT وتوجيه المستخدم إذا لزم الأمر
      if (ErrorHandler.isJwtError(e)) {
        // استخدام JwtErrorHandler للتعامل مع الخطأ
        // ignore: use_build_context_synchronously
        JwtErrorHandler.handleJwtError(context, e);
      }
      
      if (mounted) {
        _navigateToLogin();
      }
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacementNamed(
      context,
      AppNavigation.home,
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(
      context,
      AppNavigation.login,
    );
  }

 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // شعار التطبيق
            SizedBox(
              width: 120,
              height: 120,
              
              child: Image.asset('assets/justLogo.png'),
            ),
            
            
           
          ],
        ),
      ),
    );
  }
}
