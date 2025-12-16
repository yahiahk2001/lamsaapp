import 'package:flutter/material.dart';
import '../../../models/notification_model.dart';
import '../../../utils/colors.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
        appBar: AppBar(
                    surfaceTintColor: AppColors.backgroundWhite,

          title: const Text(
            'تفاصيل الإشعار',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'IBMPlexSansArabic',
              fontWeight: FontWeight.bold,
            ),
          ),
        backgroundColor: AppColors.backgroundWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان الإشعار
            Text(
              notification.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
            
            const SizedBox(height: 16),
            
            // وقت الإشعار
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 18,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 8),
                Text(
                  notification.timeAgo,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // نص الإشعار
            Text(
              notification.message,
              style: const TextStyle(
                fontSize: 18,
                height: 1.8,
                color: Colors.black87,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ],
        ),
      ),
    );
  }



}
