import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorHandler {
  /// الحصول على رسالة الخطأ المناسبة باللغة العربية
  static String getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'تأكد من اتصالك بالإنترنت وحاول مرة أخرى';
    } else if (errorString.contains('invalid_grant') || errorString.contains('expired')) {
      return 'انتهت صلاحية الجلسة. يرجى المحاولة مرة أخرى';
    } else if (errorString.contains('provider_email_needs_verification')) {
      return 'مشكلة في إعدادات Google OAuth. يرجى المحاولة مرة أخرى أو التواصل مع الدعم الفني.';
    } else if (errorString.contains('cancelled') || errorString.contains('cancel')) {
      return 'تم إلغاء العملية';
    } else if (errorString.contains('timeout')) {
      return 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى';
    } else if (errorString.contains('permission_denied')) {
      return 'تم رفض الإذن. يرجى السماح بالوصول المطلوب';
    } else if (errorString.contains('sign_in_required')) {
      return 'يجب تسجيل الدخول مرة أخرى';
    } else if (errorString.contains('invalid_credentials')) {
      return 'بيانات الاعتماد غير صحيحة';
    } else if (errorString.contains('user_not_found')) {
      return 'المستخدم غير موجود';
    } else if (errorString.contains('email_already_in_use')) {
      return 'البريد الإلكتروني مستخدم بالفعل';
    } else if (errorString.contains('weak_password')) {
      return 'كلمة المرور ضعيفة جداً';
    } else if (errorString.contains('too_many_requests')) {
      return 'تم تجاوز الحد الأقصى للمحاولات. يرجى الانتظار قليلاً';
    } else if (errorString.contains('quota_exceeded')) {
      return 'تم تجاوز الحد المسموح. يرجى المحاولة لاحقاً';
    } else if (errorString.contains('postgresterror') || errorString.contains('pgrst')) {
      return 'مشكلة في قاعدة البيانات. يرجى المحاولة مرة أخرى';
    } else if (errorString.contains('column') || errorString.contains('schema')) {
      return 'مشكلة في هيكل قاعدة البيانات. يرجى التواصل مع الدعم الفني';
    } else if (errorString.contains('cart') || errorString.contains('shopping')) {
      return 'مشكلة في السلة. يرجى المحاولة مرة أخرى';
    } else if (errorString.contains('order') || errorString.contains('payment')) {
      return 'مشكلة في الطلب. يرجى المحاولة مرة أخرى';
    } else if (errorString.contains('location') || errorString.contains('gps')) {
      return 'مشكلة في تحديد الموقع. تأكد من تفعيل GPS';
    } else {
      return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى';
    }
  }

  /// طباعة تفاصيل الخطأ للتطوير
  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    if (stackTrace != null) {
    }
  }

  /// التحقق من نوع الخطأ
  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') || 
           errorString.contains('connection') || 
           errorString.contains('timeout');
  }

  /// التحقق من خطأ المصادقة
  static bool isAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('invalid_grant') || 
           errorString.contains('expired') || 
           errorString.contains('sign_in_required') ||
           errorString.contains('invalid_credentials');
  }

  /// التحقق من خطأ JWT
  static bool isJwtError(dynamic error) {
    final errorString = error.toString();
    return errorString.contains('JWT expired') || 
           errorString.contains('Unauthorized') ||
           errorString.contains('PGRST303');
  }

  /// التحقق من خطأ الإذن
  static bool isPermissionError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('permission_denied') || 
           errorString.contains('cancelled') || 
           errorString.contains('cancel');
  }

  /// عرض رسالة خطأ للمستخدم
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'إغلاق',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// عرض رسالة نجاح للمستخدم
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// عرض رسالة تحذير للمستخدم
  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange[600],
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// عرض رسالة معلومات للمستخدم
  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue[600],
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// توجيه المستخدم إلى صفحة تسجيل الدخول عند خطأ JWT
  static void redirectToLoginOnJwtError(BuildContext context, dynamic error) {
    if (isJwtError(error)) {
      // عرض رسالة للمستخدم
      showWarningSnackBar(
        context, 
        'انتهت صلاحية الجلسة. يرجى إعادة تسجيل الدخول.'
      );
      
      // تأخير قليل قبل التوجيه
      Future.delayed(Duration(seconds: 2), () {
        if (context.mounted) {
          // تسجيل الخروج من Supabase
          try {
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
      });
    }
  }
}
