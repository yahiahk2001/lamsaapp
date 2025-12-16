import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/user_service.dart';
import '../../../utils/error_handler.dart';
import '../../../utils/colors.dart';

class WelcomeScreen extends StatefulWidget {
  final User supabaseUser;
  final String? googleUserName;
  final String? googleUserEmail;

  const WelcomeScreen({
    super.key,
    required this.supabaseUser,
    this.googleUserName,
    this.googleUserEmail,
  });

  @override
  // ignore: library_private_types_in_public_api
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // تعبئة اسم المستخدم من Google إذا كان متوفراً
    if (widget.googleUserName != null && widget.googleUserName!.isNotEmpty) {
      _nameController.text = widget.googleUserName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// التحقق من صحة رقم الهاتف العراقي
  bool _isValidIraqiPhone(String phone) {
    // إزالة المسافات والرموز
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // التحقق من أن الرقم يحتوي على أرقام فقط
    if (!RegExp(r'^\d+$').hasMatch(cleanPhone)) {
      return false;
    }
    
    // التحقق من طول الرقم (10 أو 11 رقم)
    if (cleanPhone.length != 10 && cleanPhone.length != 11) {
      return false;
    }
    
    // إذا كان 11 رقم، يجب أن يبدأ بـ 0
    if (cleanPhone.length == 11 && !cleanPhone.startsWith('0')) {
      return false;
    }
    
    // إذا كان 10 أرقام، يجب أن يبدأ بـ 7
    if (cleanPhone.length == 10 && !cleanPhone.startsWith('7')) {
      return false;
    }
    
    return true;
  }

  /// تنسيق رقم الهاتف
  String _formatPhoneNumber(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    if (cleanPhone.length == 10) {
      // إضافة 0 في البداية إذا كان 10 أرقام
      return '0$cleanPhone';
    }
    
    return cleanPhone;
  }

  /// حفظ معلومات المستخدم
  Future<void> _saveUserInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final name = _nameController.text.trim();
      final phone = _formatPhoneNumber(_phoneController.text.trim());

      // تحديث معلومات المستخدم في قاعدة البيانات
      await UserService.updateUserProfile(
        widget.supabaseUser.id,
        name: name,
        phoneNumber: phone,
      );
//------------------------------------------------------
      // الانتقال إلى الصفحة الرئيسية
      if (mounted) {
        Navigator.pushReplacementNamed(context,'/home');
      }
//------------------------------------------------------

    } catch (e, stack) {
      ErrorHandler.logError('Welcome screen save user info', e, stack);
      setState(() {
        _error = ErrorHandler.getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                Text(
                  'أكمل معلومات التسجيل',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 40),
                
                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'الاسم الكامل',
                    hintText: 'أدخل اسمك الكامل',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: AppColors.primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الاسم مطلوب';
                    }
                    if (value.trim().length < 2) {
                      return 'الاسم يجب أن يكون أكثر من حرفين';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 20),
                
                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف',
                    hintText: 'مثال: 07801234567 أو 7801234567',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: AppColors.primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'رقم الهاتف مطلوب';
                    }
                    if (!_isValidIraqiPhone(value.trim())) {
                      return 'يرجى إدخال رقم هاتف عراقي صحيح (10 أو 11 رقم)';
                    }
                    return null;
                  },
                ),
                
               
                
                SizedBox(height: 32),
                
                // Error Message
                if (_error != null) ...[
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                
                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveUserInfo,
                    icon: _isLoading 
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                    label: Text(
                      _isLoading ? 'جاري الحفظ...' : 'أكمل التسجيل',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Terms Text
                Text(
                  'بالضغط على زر "أكمل التسجيل"، أنت توافق على شروط الاستخدام وسياسة الخصوصية',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

