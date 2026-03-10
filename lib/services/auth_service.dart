import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/error_handler.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// تهيئة Google Sign-In
  static Future<void> initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        serverClientId:
            '675816714375-lfo5unskfaq8lq5j2jo35b5pi17rbcr7.apps.googleusercontent.com',
      );
    } catch (e, stack) {
      ErrorHandler.logError('Google Sign-In initialization', e, stack);
      throw Exception('فشل في تهيئة Google Sign-In');
    }
  }

  /// الحصول على بيانات المصادقة من Google
  static Future<GoogleSignInAuthentication?> getGoogleAuthentication(
      GoogleSignInAccount user) async {
    try {
      final auth = user.authentication;

      if (auth.idToken == null) {
        throw Exception('لم يتم الحصول على رمز المصادقة من Google');
      }

      return auth;
    } catch (e) {
      ErrorHandler.logError('Google authentication', e);
      return null;
    }
  }

  /// تسجيل الدخول إلى Supabase باستخدام Google
  static Future<User?> signInToSupabase(
      GoogleSignInAuthentication auth) async {
    try {
      AuthResponse res;
      try {
        res = await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: auth.idToken!,
        );
      } catch (e) {
        // محاولة إنشاء مستخدم جديد إذا فشل تسجيل الدخول العادي
        if (e.toString().contains('provider_email_needs_verification')) {
          return await _createUserWithAlternativeMethod(auth);
        } else {
          rethrow;
        }
      }

      if (res.user != null) {
        return res.user;
      } else {
        return null;
      }
    } catch (e) {
      ErrorHandler.logError('Supabase sign-in', e);
      return null;
    }
  }

  /// تسجيل مستخدم جديد بالبريد وكلمة المرور
  static Future<User?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      return res.user;
    } catch (e, stack) {
      ErrorHandler.logError('Email sign-up', e, stack);
      rethrow;
    }
  }

  /// تسجيل الدخول بالبريد وكلمة المرور
  static Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return res.user;
    } catch (e, stack) {
      ErrorHandler.logError('Email sign-in', e, stack);
      rethrow;
    }
  }

  /// إنشاء مستخدم بطريقة بديلة
  static Future<User?> _createUserWithAlternativeMethod(
      GoogleSignInAuthentication auth) async {
    try {
      // إنشاء مستخدم جديد في Supabase Auth
      final res = await _supabase.auth.signUp(
        email:
            'temp_${DateTime.now().millisecondsSinceEpoch}@example.com', // بريد مؤقت
        password:
            DateTime.now().millisecondsSinceEpoch.toString(), // كلمة مرور مؤقتة
      );

      if (res.user != null) {
        return res.user;
      } else {
        throw Exception('فشل في إنشاء المستخدم بالطريقة البديلة');
      }
    } catch (e) {
      ErrorHandler.logError('Alternative user creation', e);
      return null;
    }
  }

  /// تسجيل الخروج
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _supabase.auth.signOut();
    } catch (e) {
      ErrorHandler.logError('Sign out', e);
      throw Exception('فشل في تسجيل الخروج');
    }
  }

  /// الحصول على المستخدم الحالي
  static User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// التحقق من حالة تسجيل الدخول
  static bool isSignedIn() {
    return _supabase.auth.currentUser != null;
  }

  /// الحصول على معرف المستخدم الحالي
  static String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  /// الحصول على بريد المستخدم الحالي
  static String? getCurrentUserEmail() {
    return _supabase.auth.currentUser?.email;
  }
}
