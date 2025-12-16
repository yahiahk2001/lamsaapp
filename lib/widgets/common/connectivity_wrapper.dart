import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../../utils/colors.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  
  const ConnectivityWrapper({
    super.key,
    required this.child,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ConnectivityWrapperState createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = true;
  bool _isDialogShowing = false;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // تأخير بسيط لتجنب ظهور النافذة فوراً
    Future.delayed(Duration(milliseconds: 1000), () {
      if (mounted) {
        _initConnectivity();
      }
    });
    // تأخير الاستماع للتغييرات لتجنب التفعيل الفوري
    Future.delayed(Duration(milliseconds: 1500), () {
      if (mounted) {
        _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    if (!mounted) return;
    
    late List<ConnectivityResult> result;
    try {
      result = await Connectivity().checkConnectivity();
    } catch (e) {
      result = [ConnectivityResult.none];
    }
    
    if (!mounted) return;
    
    setState(() {
      _hasInitialized = true;
    });
    
    return _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    if (!mounted) return;
    
    bool connected = result.any((r) => r != ConnectivityResult.none);
    
    // إذا انقطع الاتصال والنافذة غير مفتوحة
    if (!connected && !_isDialogShowing && _hasInitialized) {
      // فحص إضافي للتأكد من انقطاع الاتصال
      Future.delayed(Duration(milliseconds: 500), () async {
        if (!mounted) return;
        
        try {
          final recheck = await Connectivity().checkConnectivity();
          bool stillDisconnected = recheck.every((r) => r == ConnectivityResult.none);
          
          if (stillDisconnected && !_isDialogShowing && mounted) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isDialogShowing) {
                _showNoConnectionDialog();
              }
            });
          }
        } catch (e) {
          // تجاهل الأخطاء في الفحص الإضافي
        }
      });
    }
    
    // إذا عاد الاتصال والنافذة مفتوحة
    if (connected && _isDialogShowing) {
      // إغلاق النافذة بدون setState أولاً لتجنب _debugLocked
      _isDialogShowing = false;
      _closeDialogSafely();
    }
    
    // تحديث حالة الاتصال بعد frame
    if (_isConnected != connected) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isConnected != connected) {
          setState(() {
            _isConnected = connected;
          });
        }
      });
    }
  }

  void _closeDialogSafely() {
    if (!mounted) return;
    
    // إغلاق النافذة بعد اكتمال البناء بدون استدعاء setState
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          // التحقق من إمكانية الإغلاق قبل المحاولة
          if (Navigator.canPop(context)) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        } catch (e) {
          print('خطأ عند إغلاق نافذة الاتصال: $e');
        }
      }
    });
  }

  void _showNoConnectionDialog() {
    if (!mounted || _isConnected || _isDialogShowing) return;
    
    // تعيين الحالة قبل عرض النافذة
    setState(() {
      _isDialogShowing = true;
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      // ignore: deprecated_member_use
      builder: (BuildContext dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  size: 40,
                  color: Colors.red.shade400,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'لا يوجد اتصال بالإنترنت',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.buttonColor, AppColors.buttonLightColor],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    if (mounted) {
                      // إغلاق النافذة
                      Navigator.of(dialogContext).pop();
                      setState(() {
                        _isDialogShowing = false;
                      });
                      
                      // إعادة فحص الاتصال
                      await _initConnectivity();
                      
                      // فحص إضافي بعد ثانية
                      Future.delayed(Duration(seconds: 1), () async {
                        if (mounted) {
                          await _initConnectivity();
                        }
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'إعادة المحاولة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      // عند إغلاق النافذة بأي طريقة، تحديث الحالة
      if (mounted) {
        setState(() {
          _isDialogShowing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

