// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../../services/supabase_service.dart';
import '../../../services/user_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/supabase_config.dart';
import '../../../utils/colors.dart';
import '../../../widgets/common/connectivity_wrapper.dart';
import '../../../widgets/common/guest_guard.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String? _whatsappNumber;
  String? _facebookUrl;
  String? _instagramUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    
    // التحقق من اكتمال بيانات المستخدم
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final currentUser = Supabase.instance.client.auth.currentUser;
        if (currentUser != null) {
          final isProfileComplete = await UserService.isUserProfileComplete(currentUser.id);
          if (!isProfileComplete && mounted) {
            print('⚠️ User profile incomplete in support screen, redirecting to welcome screen');
            Navigator.pushReplacementNamed(
              context,
              '/welcome',
              arguments: {
                'supabaseUser': currentUser,
                'googleUserName': currentUser.userMetadata?['full_name'],
                'googleUserEmail': currentUser.email,
              },
            );
          }
        }
      } catch (e) {
        // إذا حدث خطأ (مثل فشل الشبكة)، نتجاهله ونسمح للمستخدم بالاستمرار
      }
    });
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        SupabaseService.getSettingValue(SupabaseConfig.whatsappNumberKey),
        SupabaseService.getSettingValue(SupabaseConfig.facebookUrlKey),
        SupabaseService.getSettingValue(SupabaseConfig.instagramUrlKey),
      ]);

      setState(() {
        _whatsappNumber = results[0] ?? '+9647XXXXXXXXX';
        _facebookUrl = results[1];
        _instagramUrl = results[2];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openWhatsApp() async {
    final phone = (_whatsappNumber ?? '+9647XXXXXXXXX').replaceAll('+', '').replaceAll(' ', '');
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityWrapper(
      child: GuestGuard(
        message: 'يجب عليك تسجيل الدخول للتواصل مع الدعم الفني',
        child: Scaffold(
        appBar: AppBar(
        title: const Text('الدعم والتواصل', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.backgroundWhite,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        // ignore: deprecated_member_use
                        BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.support_agent, color: AppColors.primaryColor),
                            const SizedBox(width: 8),
                            Text('تواصل معنا', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _openWhatsApp,
                            icon: const Icon(Icons.chat, color: Colors.white),
                            label: const Text('التواصل عبر واتساب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        // ignore: deprecated_member_use
                        BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.link, color: Colors.pink[600]),
                            const SizedBox(width: 8),
                            Text('روابط السوشيال ميديا', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          leading: Icon(Icons.facebook, color: Colors.blue[700]),
                          title: const Text('فيسبوك'),
                          subtitle: Text(_facebookUrl ?? 'غير متوفر', maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: const Icon(Icons.open_in_new, size: 18),
                          onTap: () => _openUrl(_facebookUrl),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          leading:  Image.asset('assets/instagram.png', width: 20, height: 20),
                          title: const Text('إنستغرام'),
                          subtitle: Text(_instagramUrl ?? 'غير متوفر', maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: const Icon(Icons.open_in_new, size: 18),
                          onTap: () => _openUrl(_instagramUrl),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ), // Scaffold closing
      ), // GuestGuard closing
    ); // ConnectivityWrapper closing
  }
}
