import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/user_service.dart';
import '../../../services/auth_service.dart';
import '../../../utils/error_handler.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  String? _error;
  bool _isLoading = false;
  StreamSubscription? _authSubscription;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // حقول واجهة البريد/الرمز (لـ iOS)
  final GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isEmailLoginMode = true; // true = تسجيل دخول، false = إنشاء حساب

  @override
  void initState() {
    super.initState();
    _initAnimations();
    // تهيئة Google Sign-In فقط على أندرويد
    if (defaultTargetPlatform == TargetPlatform.android) {
      _initGoogleSignIn();
    }
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /// تهيئة Google Sign-In
  Future<void> _initGoogleSignIn() async {
    try {
      await AuthService.initializeGoogleSignIn();

      _authSubscription = GoogleSignIn.instance.authenticationEvents.listen(
        (event) async {
          await _handleGoogleAuthEvent(event);
        },
        onError: (e, stack) {
          ErrorHandler.logError('Google Sign-In listener', e, stack);
          _handleError(ErrorHandler.getErrorMessage(e));
        },
      );
    } catch (e, stack) {
      ErrorHandler.logError('Google Sign-In initialization', e, stack);
      _handleError('فشل في تهيئة تسجيل الدخول');
    }
  }

  /// معالجة أحداث Google Authentication
  Future<void> _handleGoogleAuthEvent(GoogleSignInAuthenticationEvent event) async {
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn(user: final user):
        await _handleSuccessfulSignIn(user);
        break;

      case GoogleSignInAuthenticationEventSignOut():
        break;
    }
  }

  /// معالجة تسجيل الدخول الناجح
  Future<void> _handleSuccessfulSignIn(GoogleSignInAccount googleUser) async {
    try {

      // الحصول على بيانات المصادقة
      final auth = await AuthService.getGoogleAuthentication(googleUser);
      if (auth == null) return;

      // تسجيل الدخول إلى Supabase
      final supabaseUser = await AuthService.signInToSupabase(auth);
      if (supabaseUser == null) return;

      // التحقق من وجود المستخدم في قاعدة البيانات
      final isNewUser = await _checkIfNewUser(supabaseUser);
      
      if (isNewUser) {
        // إنشاء مستخدم أساسي في قاعدة البيانات
        await UserService.createBasicUser(supabaseUser, googleUser);

        // انتقل إلى صفحة الترحيب
        _navigateToWelcome(
          supabaseUser,
          name: googleUser.displayName,
          email: googleUser.email,
        );
      } else {
        // إذا كان مستخدم موجود، انتقل إلى الصفحة الرئيسية
        _navigateToHome();
      }

    } catch (e, stack) {
      ErrorHandler.logError('Sign-in process', e, stack);
      _handleError(ErrorHandler.getErrorMessage(e));
    }
  }

  /// التحقق من كون المستخدم جديد
  Future<bool> _checkIfNewUser(User supabaseUser) async {
    try {
      final result = await Supabase.instance.client
          .from('users')
          .select('name, phone_number')
          .eq('id', supabaseUser.id)
          .maybeSingle();
      
      // إذا لم يتم العثور على المستخدم أو كان الاسم أو رقم الهاتف فارغين
      if (result == null) {
        return true;
      }
      
      final name = result['name'] as String?;
      final phoneNumber = result['phone_number'] as String?;
      
      // إذا كان الاسم أو رقم الهاتف فارغين، يعتبر مستخدم جديد
      return name == null || name.trim().isEmpty || 
             phoneNumber == null || phoneNumber.trim().isEmpty;
      
    } catch (e) {
      // في حالة الخطأ، نفترض أنه مستخدم جديد
      return true;
    }
  }

  /// معالجة الأخطاء
  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _error = message;
        _isLoading = false;
      });
    }
  }

  /// الانتقال إلى صفحة الترحيب
  void _navigateToWelcome(
    User supabaseUser, {
    String? name,
    String? email,
  }) {
    if (!mounted) return;

    // تحديث حالة المصادقة في AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.clearError();

    Navigator.pushReplacementNamed(
      context,
      '/welcome',
      arguments: {
        'supabaseUser': supabaseUser,
        'googleUserName': name,
        'googleUserEmail': email,
      },
    );
  }

  /// الانتقال إلى الشاشة الرئيسية
  void _navigateToHome() {
    if (!mounted) return;
    
    // تحديث حالة المصادقة في AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.clearError();
    
    Navigator.pushReplacementNamed(
      context,
      '/home',
    );
  }

  /// بدء عملية تسجيل الدخول
  void _startSignIn() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      await GoogleSignIn.instance.authenticate();
    } catch (e, stack) {
      ErrorHandler.logError('Google Sign-In authenticate', e, stack);
      _handleError(ErrorHandler.getErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// تبديل وضع واجهة البريد (تسجيل / إنشاء حساب)
  void _toggleEmailMode(bool isLogin) {
    if (_isEmailLoginMode == isLogin) return;
    setState(() {
      _isEmailLoginMode = isLogin;
      _error = null;
    });
  }

  /// بدء عملية المصادقة بالبريد والرمز (iOS)
  Future<void> _submitEmailAuth() async {
    if (!_emailFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      User? supabaseUser;

      if (_isEmailLoginMode) {
        // تسجيل دخول
        supabaseUser = await AuthService.signInWithEmail(
          email: email,
          password: password,
        );
      } else {
        // إنشاء حساب جديد
        supabaseUser = await AuthService.signUpWithEmail(
          email: email,
          password: password,
        );

        if (supabaseUser != null) {
          await UserService.createBasicUserWithEmail(supabaseUser);
        }
      }

      if (supabaseUser == null) {
        _handleError('فشل في المصادقة، يرجى المحاولة مرة أخرى');
        return;
      }

      final isNewUser = await _checkIfNewUser(supabaseUser);

      if (isNewUser) {
        // إنشاء سجل أساسي إن لم يكن موجوداً ثم الانتقال لإكمال البيانات
        await UserService.createBasicUserWithEmail(supabaseUser);
        _navigateToWelcome(
          supabaseUser,
          email: email,
        );
      } else {
        _navigateToHome();
      }
    } catch (e, stack) {
      ErrorHandler.logError('Email auth', e, stack);
      _handleError(ErrorHandler.getErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: isIOS
              ? _buildEmailAuthContent(context)
              : _buildGoogleAuthContent(context),
        ),
      ),
    );
  }

  Widget _buildLogoAndDescription() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo
        FadeTransition(
          opacity: _fadeAnimation,
          child: SizedBox(
            width: 250,
            height: 250,
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Description
        SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              'من البسكويت للنستله للعصائر..\nلمسة تجمع كل النكهات وتوصلها لك مجاناً',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorAndTermsAndGuest() {
    return Column(
      children: [
        const SizedBox(height: 24),
        // Error Message
        if (_error != null) ...[
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red[600], size: 20),
                    const SizedBox(width: 8),
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
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Terms
        SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
                children: [
                  const TextSpan(
                      text:
                          'بالضغط على زر تسجيل الدخول، أنت توافق على '),
                  TextSpan(
                    text: 'سياسة الخصوصية',
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        final url =
                            'https://poolicy-and-privecy-lamsaa-appp.netlify.app';
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url));
                        }
                      },
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Guest Mode Button
        SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _continueAsGuest,
                icon: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF8B7355),
                  size: 20,
                ),
                label: const Text(
                  'متابعة كضيف',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B7355),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF8B7355),
                  side: const BorderSide(
                    color: Color(0xFF8B7355),
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleAuthContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLogoAndDescription(),
        const SizedBox(height: 60),
        // Google Sign-In Button
        SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _startSignIn,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.login, color: Colors.white, size: 20),
                label: Text(
                  _isLoading
                      ? 'جاري تسجيل الدخول...'
                      : ' الدخول باستخدام Google',
                  style: const TextStyle(
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
          ),
        ),
        _buildErrorAndTermsAndGuest(),
      ],
    );
  }

  Widget _buildEmailAuthContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          _buildLogoAndDescription(),
          const SizedBox(height: 40),
          // Tabs: تسجيل دخول / إنشاء حساب
          SlideTransition(
            position: _slideAnimation,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _toggleEmailMode(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isEmailLoginMode
                            ? AppColors.buttonColor
                            : Colors.grey[200],
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            color: _isEmailLoginMode
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _toggleEmailMode(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isEmailLoginMode
                            ? AppColors.buttonColor
                            : Colors.grey[200],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'إنشاء حساب',
                          style: TextStyle(
                            color: !_isEmailLoginMode
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Form
          Form(
            key: _emailFormKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppColors.primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'البريد الإلكتروني مطلوب';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'يرجى إدخال بريد إلكتروني صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppColors.primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'كلمة المرور مطلوبة';
                    }
                    if (value.length < 6) {
                      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                if (!_isEmailLoginMode) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: AppColors.primaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (!_isEmailLoginMode) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى تأكيد كلمة المرور';
                        }
                        if (value != _passwordController.text) {
                          return 'كلمتا المرور غير متطابقتين';
                        }
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitEmailAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _isEmailLoginMode
                                ? 'تسجيل الدخول'
                                : 'إنشاء حساب',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          _buildErrorAndTermsAndGuest(),
        ],
      ),
    );
  }

  /// متابعة كضيف
  void _continueAsGuest() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // تسجيل الدخول كضيف
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInAsGuest();
      
      // الانتقال إلى الشاشة الرئيسية
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/home',
        );
      }
    } catch (e, stack) {
      ErrorHandler.logError('Guest sign-in', e, stack);
      _handleError(ErrorHandler.getErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
