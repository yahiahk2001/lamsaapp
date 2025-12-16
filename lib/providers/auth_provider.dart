import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/jwt_error_handler.dart';
import '../services/fcm_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    
    // التحقق من المستخدم الحالي عند بدء التطبيق
    _currentUser = Supabase.instance.client.auth.currentUser;
    
    // إذا كان هناك جلسة ولكن لا يوجد مستخدم، نحاول إعادة تحميل الجلسة
    if (_currentUser == null && Supabase.instance.client.auth.currentSession != null) {
      _refreshSession();
    }
    
    // الاستماع لتغييرات حالة المصادقة
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final previousUser = _currentUser;
      _currentUser = data.session?.user;
      _error = null;
      notifyListeners();
      
      // تحديث FCM Token عند تسجيل الدخول
      if (_currentUser != null && previousUser?.id != _currentUser?.id) {
        _updateFCMTokenForUser(_currentUser!.id);
      }
      
      // تحديث معرف المستخدم في NotificationProvider
      // سيتم تحديثه من main.dart عند الحاجة
    });
  }

  Future<void> _refreshSession() async {
    try {
      await Supabase.instance.client.auth.refreshSession();
      _currentUser = Supabase.instance.client.auth.currentUser;
      notifyListeners();
    } catch (e) {
      
      // إذا فشل تحديث الجلسة، نحاول تسجيل الخروج وإعادة تسجيل الدخول
      if (e.toString().contains('JWT expired') || 
          e.toString().contains('Unauthorized') ||
          e.toString().contains('PGRST303')) {
        try {
          await Supabase.instance.client.auth.signOut();
          _currentUser = null;
          notifyListeners();
        } catch (signOutError) {
          _currentUser = null;
          notifyListeners();
        }
      } else {
        _currentUser = null;
        notifyListeners();
      }
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      setLoading(true);
      
      // حذف FCM Token قبل تسجيل الخروج
      await FCMService.deleteFCMToken();
      
      // تسجيل الخروج من Supabase
      await Supabase.instance.client.auth.signOut();
      
      // إعادة تعيين حالة المستخدم
      _currentUser = null;
      setError(null);
      
      // إخطار المستمعين بالتغيير
      notifyListeners();
      
    } catch (e) {
      setError('فشل في تسجيل الخروج: $e');
      
      // حتى في حالة الخطأ، نعيد تعيين حالة المستخدم
      _currentUser = null;
      notifyListeners();
    } finally {
      setLoading(false);
    }
  }

  // تحديث FCM Token للمستخدم
  Future<void> _updateFCMTokenForUser(String userId) async {
    try {
      await FCMService.updateTokenForUser(userId);
    // ignore: empty_catches
    } catch (e) {
    }
  }

  // التحقق من صحة الجلسة
  Future<bool> checkSession() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _currentUser = session.user;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      setError('فشل في التحقق من الجلسة: $e');
      return false;
    }
  }

  // توجيه المستخدم إلى صفحة تسجيل الدخول عند خطأ JWT
  void redirectToLoginOnJwtError(BuildContext context, dynamic error) {
    JwtErrorHandler.handleJwtError(context, error);
  }
}
















