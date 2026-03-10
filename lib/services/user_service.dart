import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// حفظ معلومات المستخدم في قاعدة البيانات
  static Future<void> saveUserToDatabase(User supabaseUser, GoogleSignInAccount googleUser) async {
    try {
      
      final String userEmail = supabaseUser.email ?? googleUser.email;
      
      // التحقق من وجود المستخدم في الجدول بالـ ID أو البريد الإلكتروني
      final userExistsById = await _checkUserExists(supabaseUser.id);
      // ignore: unnecessary_null_comparison
      final userExistsByEmail = userEmail != null ? await _checkUserExistsByEmail(userEmail) : false;
      
      if (userExistsById || userExistsByEmail) {
        await _updateUserProfile(supabaseUser, googleUser);
        return;
      }

      // إنشاء مستخدم جديد
      await _createNewUser(supabaseUser, googleUser);
      
    } catch (e) {
      throw Exception('فشل في حفظ معلومات المستخدم: $e');
    }
  }

  /// إنشاء مستخدم أساسي في قاعدة البيانات (للمستخدمين الجدد عبر Google)
  static Future<void> createBasicUser(
      User supabaseUser, GoogleSignInAccount googleUser) async {
    try {
      final userEmail = supabaseUser.email ?? googleUser.email;

      // التحقق من وجود المستخدم في الجدول
      final userExistsById = await _checkUserExists(supabaseUser.id);
      final userExistsByEmail = await _checkUserExistsByEmail(userEmail);

      if (userExistsById || userExistsByEmail) {
        return;
      }

      // إنشاء مستخدم جديد بالبيانات الأساسية فقط
      final userData = <String, dynamic>{
        'id': supabaseUser.id,
        'email': userEmail,
        'name': _sanitizeName(googleUser.displayName), // إضافة الاسم
        'phone_number': null, // إضافة رقم الهاتف كـ null
        'user_type': 'customer', // إضافة نوع المستخدم
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('users').insert(userData);
    } catch (e) {
      // إذا كان هناك تضارب، حاول الحصول على المستخدم الموجود
      if (e.toString().contains('23505')) {
        return;
      }

      // لا نريد إيقاف العملية إذا فشل إنشاء المستخدم الأساسي
    }
  }

  /// إنشاء مستخدم أساسي في قاعدة البيانات (للمستخدمين الجدد عبر البريد)
  static Future<void> createBasicUserWithEmail(User supabaseUser) async {
    try {
      final userEmail = supabaseUser.email;

      // التحقق من وجود المستخدم في الجدول
      final userExistsById = await _checkUserExists(supabaseUser.id);
      // ignore: unnecessary_null_comparison
      final userExistsByEmail =
          userEmail != null ? await _checkUserExistsByEmail(userEmail) : false;

      if (userExistsById || userExistsByEmail) {
        return;
      }

      // إنشاء مستخدم جديد بالبيانات الأساسية فقط
      final userData = <String, dynamic>{
        'id': supabaseUser.id,
        'email': userEmail,
        'name': null,
        'phone_number': null,
        'user_type': 'customer',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('users').insert(userData);
    } catch (e) {
      // لا نريد إيقاف عملية المصادقة إذا فشل إنشاء المستخدم الأساسي
    }
  }

  /// التحقق من وجود المستخدم في قاعدة البيانات
  static Future<bool> _checkUserExists(String userId) async {
    try {
      final result = await _supabase
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      
      return result != null;
    } catch (e) {
      return false;
    }
  }

  /// التحقق من وجود المستخدم بالبريد الإلكتروني
  static Future<bool> _checkUserExistsByEmail(String email) async {
    try {
      final result = await _supabase
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      
      return result != null;
    } catch (e) {
      return false;
    }
  }

  /// إنشاء مستخدم جديد في قاعدة البيانات
  static Future<void> _createNewUser(User supabaseUser, GoogleSignInAccount googleUser) async {
    try {
      // التحقق مرة أخرى من وجود المستخدم قبل الإنشاء
      final userEmail = supabaseUser.email ?? googleUser.email;
      final userExistsById = await _checkUserExists(supabaseUser.id);
      // ignore: unnecessary_null_comparison
      final userExistsByEmail = userEmail != null ? await _checkUserExistsByEmail(userEmail) : false;
      
      if (userExistsById || userExistsByEmail) {
        await _updateUserProfile(supabaseUser, googleUser);
        return;
      }

      // إنشاء بيانات المستخدم التكيفية
      final userData = await _createAdaptiveUserData(supabaseUser, googleUser);

      await _supabase.from('users').insert(userData);
      
      _logUserDetails(supabaseUser, googleUser);
      
    } catch (e) {
      
      // التحقق من أن الخطأ ليس بسبب وجود المستخدم
      if (e.toString().contains('duplicate key') || e.toString().contains('unique constraint')) {
        await _updateUserProfile(supabaseUser, googleUser);
        return;
      }
      
      // محاولة إنشاء المستخدم بالبيانات الأساسية فقط
      await _createUserWithBasicDataOnly(supabaseUser, googleUser);
    }
  }

  /// إنشاء بيانات المستخدم الأساسية فقط (الأعمدة المطلوبة)
  static Map<String, dynamic> _createBasicUserData(User supabaseUser, GoogleSignInAccount googleUser) {
    final userData = <String, dynamic>{
      'id': supabaseUser.id,
      'email': supabaseUser.email ?? googleUser.email,
      'name': _sanitizeName(googleUser.displayName),
      'user_type': 'customer',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    return userData;
  }

  /// إنشاء مستخدم جديد بالبيانات الأساسية فقط
  static Future<void> _createUserWithBasicDataOnly(User supabaseUser, GoogleSignInAccount googleUser) async {
    try {
      // التحقق مرة أخرى من وجود المستخدم قبل الإنشاء
      final userEmail = supabaseUser.email ?? googleUser.email;
      final userExistsById = await _checkUserExists(supabaseUser.id);
      // ignore: unnecessary_null_comparison
      final userExistsByEmail = userEmail != null ? await _checkUserExistsByEmail(userEmail) : false;
      
      if (userExistsById || userExistsByEmail) {
        await _updateUserProfile(supabaseUser, googleUser);
        return;
      }

      // إنشاء بيانات المستخدم الأساسية فقط
      final userData = _createBasicUserData(supabaseUser, googleUser);

      await _supabase.from('users').insert(userData);
      
      _logUserDetails(supabaseUser, googleUser);
      
    } catch (e) {
      
      // التحقق من أن الخطأ ليس بسبب وجود المستخدم
      if (e.toString().contains('duplicate key') || e.toString().contains('unique constraint')) {
        await _updateUserProfile(supabaseUser, googleUser);
        return;
      }
      
      throw Exception('فشل في إنشاء المستخدم في قاعدة البيانات: $e');
    }
  }


  /// تحديث ملف المستخدم
  static Future<void> _updateUserProfile(User supabaseUser, GoogleSignInAccount googleUser) async {
    try {
      final userEmail = supabaseUser.email ?? googleUser.email;
      
      final updateData = {
        'name': _sanitizeName(googleUser.displayName),
        'profile_image': googleUser.photoUrl,
        'user_type': 'customer',
        'updated_at': DateTime.now().toIso8601String(),
      };

      // محاولة التحديث بالـ ID أولاً
      try {
        await _supabase
            .from('users')
            .update(updateData)
            .eq('id', supabaseUser.id);
        
        return;
      // ignore: empty_catches
      } catch (e) {
      }

      // إذا فشل التحديث بالـ ID، جرب بالبريد الإلكتروني
      try {
        await _supabase
            .from('users')
            .update(updateData)
            .eq('email', userEmail);
        
      // ignore: empty_catches
      } catch (e) {
      }
          
    } catch (e) {
      // لا نريد إيقاف العملية إذا فشل تحديث البيانات
    }
  }

  /// تنظيف اسم المستخدم
  static String _sanitizeName(String? displayName) {
    if (displayName == null || displayName.trim().isEmpty) {
      return 'مستخدم';
    }
    
    // إزالة الأحرف غير المسموح بها
    final cleanName = displayName.trim();
    return cleanName.length > 50 ? cleanName.substring(0, 50) : cleanName;
  }

  /// استخراج رقم الهاتف من البريد الإلكتروني (مؤقت)
  static String _extractPhoneFromEmail(String? email) {
    if (email == null) return '';
    
    // يمكن تحسين هذه الطريقة لاحقاً
    return email.contains('@') ? email.split('@')[0] : email;
  }

  /// طباعة تفاصيل المستخدم
  static void _logUserDetails(User supabaseUser, GoogleSignInAccount googleUser) {
  }

  /// الحصول على معلومات المستخدم الحالي
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return null;
      }


      // التحقق من صحة الجلسة قبل إجراء أي عمليات
      try {
        final session = _supabase.auth.currentSession;
        if (session != null) {
          // التحقق من انتهاء صلاحية الجلسة
          final expiresAt = session.expiresAt;
          final now = DateTime.now();
          if (expiresAt != null && now.isAfter(DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000))) {
            await _supabase.auth.refreshSession();
          }
        }
      } catch (sessionError) {
        // إذا فشل تحديث الجلسة، نستمر في المحاولة
      }

      try {
        // محاولة الحصول على المستخدم من قاعدة البيانات بالـ ID أولاً
        final result = await _supabase
            .from('users')
            .select('id, email, name, phone_number, user_type, created_at, updated_at')
            .eq('id', user.id)
            .maybeSingle();

        // للتشخيص
        
        if (result != null) {
          return result;
        }
        
        // إذا لم يتم العثور على المستخدم بالـ ID، جرب البحث بالبريد الإلكتروني
        if (user.email != null && user.email!.isNotEmpty) {
          final emailResult = await _supabase
              .from('users')
              .select('id, email, name, phone_number, user_type, created_at, updated_at')
              .eq('email', user.email!)
              .maybeSingle();
          
          if (emailResult != null) {
            
            // تحديث الـ ID ليتطابق مع المستخدم الحالي في Supabase
            try {
              await _supabase
                  .from('users')
                  .update({'id': user.id, 'updated_at': DateTime.now().toIso8601String()})
                  .eq('email', user.email!);
              
              
              // إعادة الحصول على البيانات المحدثة
              final updatedResult = await _supabase
                  .from('users')
                  .select('id, email, name, phone_number, user_type, created_at, updated_at')
                  .eq('id', user.id)
                  .single();
              
              return updatedResult;
            } catch (updateError) {
              // حتى لو فشل التحديث، نعيد البيانات الموجودة
              return emailResult;
            }
          }
        }
        
        // إذا لم يتم العثور على المستخدم، قم بإنشائه
        
        // إنشاء سجل جديد للمستخدم
        final userData = {
          'id': user.id,
          'email': user.email ?? '',
          'name': user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? 'مستخدم',
          'phone_number': null,
          'user_type': 'customer',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        // للتشخيص
        
        try {
          await _supabase.from('users').insert(userData);
          
          // إعادة الحصول على البيانات المحدثة
          final newResult = await _supabase
              .from('users')
              .select('id, email, name, phone_number, user_type, created_at, updated_at')
              .eq('id', user.id)
              .single();

          // للتشخيص
          return newResult;
        } catch (insertError) {
          
          // إذا كان هناك تضارب في البريد الإلكتروني، حاول الحصول على المستخدم الموجود
          if (insertError.toString().contains('23505') && insertError.toString().contains('email')) {
            
            if (user.email != null && user.email!.isNotEmpty) {
              try {
                final existingUser = await _supabase
                    .from('users')
                    .select('id, email, name, phone_number, user_type, created_at, updated_at')
                    .eq('email', user.email!)
                    .single();
                
                
                // تحديث الـ ID ليتطابق مع المستخدم الحالي
                try {
                  await _supabase
                      .from('users')
                      .update({'id': user.id, 'updated_at': DateTime.now().toIso8601String()})
                      .eq('email', user.email!);
                  
                  
                  // إعادة الحصول على البيانات المحدثة
                  final updatedResult = await _supabase
                      .from('users')
                      .select('id, email, name, phone_number, user_type, created_at, updated_at')
                      .eq('id', user.id)
                      .single();
                  
                  return updatedResult;
                } catch (updateError) {
                  // حتى لو فشل التحديث، نعيد البيانات الموجودة
                  return existingUser;
                }
              // ignore: empty_catches
              } catch (getError) {
              }
            }
          }
          
          // إذا كان هناك تضارب في الـ ID، حاول الحصول على المستخدم الموجود
          if (insertError.toString().contains('23505') && insertError.toString().contains('id')) {
            
            try {
              final existingUser = await _supabase
                  .from('users')
                  .select('id, email, name, phone_number, user_type, created_at, updated_at')
                  .eq('id', user.id)
                  .single();
              
              return existingUser;
            // ignore: empty_catches
            } catch (getError) {
            }
          }
          
          rethrow;
        }
      } catch (e) {
        
        // التحقق من خطأ JWT expired
        if (e.toString().contains('JWT expired') || 
            e.toString().contains('Unauthorized') ||
            e.toString().contains('PGRST303')) {
          
          try {
            // محاولة تحديث الجلسة
            await _supabase.auth.refreshSession();
            
            // إعادة المحاولة بعد تحديث الجلسة
            final refreshedResult = await _supabase
                .from('users')
                .select('id, email, name, phone_number, user_type, created_at, updated_at')
                .eq('id', user.id)
                .single();
            
            return refreshedResult;
          } catch (refreshError) {
            // إذا فشل تحديث الجلسة، نستمر في المحاولة
          }
        }
        
        // إذا كان الخطأ يشير إلى عدم وجود المستخدم، حاول إنشاؤه
        if (e.toString().contains('PGRST116') || e.toString().contains('0 rows')) {
          
          // إنشاء سجل جديد للمستخدم
          final userData = {
            'id': user.id,
            'email': user.email ?? '',
            'name': user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? 'مستخدم',
            'phone_number': null,
            'user_type': 'customer',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };

          try {
            await _supabase.from('users').insert(userData);
            
            final newResult = await _supabase
                .from('users')
                .select('id, email, name, phone_number, user_type, created_at, updated_at')
                .eq('id', user.id)
                .single();

            return newResult;
          } catch (createError) {
            return null;
          }
        }
        
        return null;
      }
    } catch (e) {
      
      // التحقق من خطأ JWT وتوجيه المستخدم إذا لزم الأمر
      if (e.toString().contains('JWT expired') || 
          e.toString().contains('Unauthorized') ||
          e.toString().contains('PGRST303')) {
        // لا يمكننا استخدام context هنا، لذا سنترك التوجيه للمكونات الأخرى
      }
      
      return null;
    }
  }

  /// تحديث ملف المستخدم
  static Future<void> updateUserProfile(
    String userId, {
    String? name,
    String? phoneNumber,
  }) async {
    try {
      
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
        'user_type': 'customer', // إضافة نوع المستخدم
      };

      if (name != null && name.trim().isNotEmpty) {
        updateData['name'] = name.trim();
      }

      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
        updateData['phone_number'] = phoneNumber.trim();
      }

      await _supabase
          .from('users')
          .update(updateData)
          .eq('id', userId);
      
      
    } catch (e) {
      throw Exception('فشل في تحديث معلومات المستخدم: $e');
    }
  }

  /// الحصول على معلومات المستخدم بالبريد الإلكتروني
  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final result = await _supabase
          .from('users')
          .select()
          .eq('email', email)
          .single();

      return result;
    } catch (e) {
      return null;
    }
  }

  /// التحقق من اكتمال بيانات المستخدم
  static Future<bool> isUserProfileComplete(String userId) async {
    try {
      final userData = await getCurrentUser();
      if (userData == null) {
        // رمي استثناء بدلاً من إرجاع false
        // هذا يسمح للكود المستدعي بالتمييز بين فشل الشبكة والبيانات غير المكتملة
        throw Exception('Failed to get user data');
      }

      // التحقق من وجود الاسم ورقم الهاتف
      final name = userData['name'] as String?;
      final phoneNumber = userData['phone_number'] as String?;

      // يجب أن يكون الاسم موجوداً وغير فارغ
      if (name == null || name.trim().isEmpty) {
        return false;
      }

      // يجب أن يكون رقم الهاتف موجوداً وغير فارغ
      if (phoneNumber == null || phoneNumber.trim().isEmpty) {
        return false;
      }

      return true;
    } catch (e) {
      // إعادة رمي الخطأ بدلاً من إرجاع false
      // هذا يسمح للكود المستدعي بالتمييز بين فشل الشبكة والبيانات غير المكتملة
      rethrow;
    }
  }

  /// تحديث معلومات المستخدم
  static Future<void> updateUserInfo(String userId, Map<String, dynamic> data) async {
    try {
      await _supabase
          .from('users')
          .update({
            ...data,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      
    } catch (e) {
      throw Exception('فشل في تحديث معلومات المستخدم: $e');
    }
  }

  /// حذف حساب المستخدم
  static Future<void> deleteUser(String userId) async {
    try {
      await _supabase
          .from('users')
          .delete()
          .eq('id', userId);
      
    } catch (e) {
      throw Exception('فشل في حذف المستخدم: $e');
    }
  }

  /// التحقق من وجود عمود في جدول المستخدمين
  static Future<bool> _hasColumn(String columnName) async {
    try {
      // محاولة استعلام بسيط للتحقق من وجود العمود
      await _supabase
          .from('users')
          .select(columnName)
          .limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// التحقق من هيكل جدول المستخدمين وطباعة الأعمدة المتاحة
  static Future<void> checkTableStructure() async {
    try {
      
      // محاولة الحصول على سجل واحد لرؤية الأعمدة المتاحة
      final result = await _supabase
          .from('users')
          .select('*')
          .limit(1);
      
      if (result.isNotEmpty) {
      } else {
        
        // إنشاء سجل تجريبي للتحقق من الأعمدة
        final testUser = {
          'id': 'test-${DateTime.now().millisecondsSinceEpoch}',
          'email': 'test@example.com',
          'name': 'Test User',
          'user_type': 'customer',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        try {
          await _supabase.from('users').insert(testUser);
          
          // حذف المستخدم التجريبي
          await _supabase.from('users').delete().eq('id', testUser['id']!);
        // ignore: empty_catches
        } catch (e) {
        }
      }
    // ignore: empty_catches
    } catch (e) {
    }
  }

  /// الحصول على هيكل جدول المستخدمين
  static Future<Map<String, bool>> _getTableStructure() async {
    final structure = <String, bool>{};
    
    // التحقق من الأعمدة الأساسية
    structure['id'] = await _hasColumn('id');
    structure['email'] = await _hasColumn('email');
    structure['name'] = await _hasColumn('name');
    structure['user_type'] = await _hasColumn('user_type');
    structure['created_at'] = await _hasColumn('created_at');
    structure['updated_at'] = await _hasColumn('updated_at');
    
    // التحقق من الأعمدة الاختيارية
    structure['phone_number'] = await _hasColumn('phone_number');
    structure['profile_image'] = await _hasColumn('profile_image');
    
    return structure;
  }

  /// إنشاء بيانات المستخدم بناءً على هيكل الجدول
  static Future<Map<String, dynamic>> _createAdaptiveUserData(User supabaseUser, GoogleSignInAccount googleUser) async {
    final structure = await _getTableStructure();
    final userData = <String, dynamic>{};

    // إضافة الأعمدة الأساسية
    if (structure['id'] == true) userData['id'] = supabaseUser.id;
    if (structure['email'] == true) userData['email'] = supabaseUser.email ?? googleUser.email;
    if (structure['name'] == true) userData['name'] = _sanitizeName(googleUser.displayName);
    if (structure['user_type'] == true) userData['user_type'] = 'customer';
    if (structure['created_at'] == true) userData['created_at'] = DateTime.now().toIso8601String();
    if (structure['updated_at'] == true) userData['updated_at'] = DateTime.now().toIso8601String();

    // إضافة الأعمدة الاختيارية
    if (structure['phone_number'] == true) {
      userData['phone_number'] = _extractPhoneFromEmail(googleUser.email);
    }
    if (structure['profile_image'] == true) {
      userData['profile_image'] = googleUser.photoUrl;
    }

    return userData;
  }

}
