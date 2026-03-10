import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/notification_model.dart';
import '../../../utils/colors.dart';
import '../../../widgets/common/connectivity_wrapper.dart';
import '../../../widgets/common/guest_guard.dart';
import 'notification_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // تهيئة الإشعارات عند فتح الشاشة
    // ملاحظة: النظام يقوم تلقائياً بفلترة الإشعارات للمستخدمين الجدد
    // بحيث لا يرون إشعارات قديمة من قبل تسجيلهم في التطبيق
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      if (notificationProvider.currentUserId != null) {
        notificationProvider.initialize();
      } else {
        // إذا لم يكن المستخدم مسجل دخول، نعيد المحاولة بعد قليل
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            final provider = Provider.of<NotificationProvider>(context, listen: false);
            if (provider.currentUserId != null) {
              provider.initialize();
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityWrapper(
      child: GuestGuard(
        message: 'يجب عليك تسجيل الدخول لعرض الإشعارات',
        child: Scaffold(
          
          backgroundColor: AppColors.backgroundLight,
            appBar: AppBar(
           
                     surfaceTintColor: AppColors.backgroundWhite,

            title: const Text(
              'الإشعارات',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'IBMPlexSansArabic',
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppColors.backgroundLight,
            foregroundColor: AppColors.buttonColor,
            elevation: 0,
          actions: [
            Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                if (notificationProvider.unreadCount > 0) {
                  return TextButton(
                    onPressed: () => _markAllAsRead(notificationProvider),
                    child: const Text(
                      'تعيين الكل كمقروء',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            if (notificationProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.buttonColor),
                ),
              );
            }

            if (notificationProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      notificationProvider.error!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => notificationProvider.refreshNotifications(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'إعادة المحاولة',
                        style: TextStyle(fontFamily: 'IBMPlexSansArabic'),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (notificationProvider.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد إشعارات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ستظهر إشعارات طلباتك هنا',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => notificationProvider.refreshNotifications(),
              color: AppColors.buttonColor,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notificationProvider.notifications.length,
                itemBuilder: (context, index) {
                  final notification = notificationProvider.notifications[index];
                  return _buildNotificationCard(notification, notificationProvider);
                },
              ),
            );
          },
        ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, NotificationProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _onNotificationTap(notification, provider),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: notification.isRead ? Colors.white : AppColors.buttonColor.withOpacity(0.05),
            border: notification.isRead 
                ? null 
                : Border.all(color: AppColors.buttonColor.withOpacity(0.3), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // أيقونة الإشعار
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // محتوى الإشعار
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // عنوان الإشعار
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                    const SizedBox(height: 4),
                    // نص الإشعار
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // وقت الإشعار
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          notification.timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                            fontFamily: 'IBMPlexSansArabic',
                          ),
                        ),
                        const Spacer(),
                        // رقم الطلب إذا كان متوفراً
                        if (notification.data != null && notification.data!['order_id'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getNotificationColor(notification.type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '#${notification.data!['order_id'].toString().substring(0, 8)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getNotificationColor(notification.type),
                                fontFamily: 'IBMPlexSansArabic',
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        // مؤشر غير مقروء
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.buttonColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order_confirmed':
        return Icons.check_circle;
      case 'order_updated':
        return Icons.update;
      case 'order_delivered':
        return Icons.local_shipping;
      case 'promotion':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order_confirmed':
        return Colors.green;
      case 'order_updated':
        return Colors.blue;
      case 'order_delivered':
        return Colors.orange;
      case 'promotion':
        return Colors.purple;
      default:
        return AppColors.buttonColor;
    }
  }

  void _onNotificationTap(NotificationModel notification, NotificationProvider provider) {
    // تعيين الإشعار كمقروء إذا لم يكن مقروءاً
    if (!notification.isRead) {
      provider.markAsRead(notification.id);
    }

    // الانتقال إلى صفحة تفاصيل الإشعار
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailScreen(notification: notification),
      ),
    );
  }

  void _markAllAsRead(NotificationProvider provider) {
    provider.markAllAsRead();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم تعيين جميع الإشعارات كمقروءة',
          style: TextStyle(fontFamily: 'IBMPlexSansArabic'),
        ),
        backgroundColor: AppColors.buttonColor,
      ),
    );
  }





}

