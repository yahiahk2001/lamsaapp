import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'error_handler.dart';

class JwtErrorHandler {
  /// معالجة خطأ JWT وتوجيه المستخدم إلى صفحة تسجيل الدخول
  static void handleJwtError(BuildContext context, dynamic error) {
    if (ErrorHandler.isJwtError(error)) {
      
      // عرض رسالة للمستخدم
      ErrorHandler.showWarningSnackBar(
        context, 
        'انتهت صلاحية الجلسة. يرجى إعادة تسجيل الدخول.'
      );
      
      // تأخير قليل قبل التوجيه
      Future.delayed(Duration(seconds: 2), () {
        if (context.mounted) {
          _signOutAndRedirect(context);
        }
      });
    }
  }

  /// تسجيل الخروج والتوجيه إلى صفحة تسجيل الدخول
  static void _signOutAndRedirect(BuildContext context) {
    try {
      // تسجيل الخروج من Supabase
      Supabase.instance.client.auth.signOut();
    // ignore: empty_catches
    } catch (e) {
    }
    
    // التوجيه إلى صفحة تسجيل الدخول بعد اكتمال البناء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    });
  }

  /// التحقق من صحة الجلسة ومحاولة تحديثها
  static Future<bool> refreshSessionIfNeeded() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        // التحقق من انتهاء صلاحية الجلسة
        final expiresAt = session.expiresAt;
        final now = DateTime.now();
        if (expiresAt != null && now.isAfter(DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000))) {
          await Supabase.instance.client.auth.refreshSession();
          return true;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// معالجة خطأ JWT مع محاولة تحديث الجلسة أولاً
  static Future<void> handleJwtErrorWithRefresh(BuildContext context, dynamic error) async {
    if (ErrorHandler.isJwtError(error)) {
      
      final refreshSuccess = await refreshSessionIfNeeded();
      
      if (!refreshSuccess) {
        // إذا فشل تحديث الجلسة، قم بتوجيه المستخدم
        // ignore: use_build_context_synchronously
        handleJwtError(context, error);
      }
    }
  }
}
