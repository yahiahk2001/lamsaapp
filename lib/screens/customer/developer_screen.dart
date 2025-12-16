import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../widgets/common/connectivity_wrapper.dart';

class DeveloperScreen extends StatelessWidget {
  const DeveloperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ConnectivityWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'مطور لمسة',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          backgroundColor: AppColors.backgroundWhite,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: AppColors.buttonColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.backgroundLight, AppColors.backgroundWhite],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // شعار المطور
                  Image.asset(
                    'assets/digital-createvity-logo.png',
                    height: 150,
                    width: 150,
                  ),
                  
                  SizedBox(height: 30),
                  Text(
                    'تم انشاء هذا التطبيق عن طريق فريق ',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // النص                  SizedBox(height: 10),
                  SizedBox(height: 8),
                  Text(
                    'الابداع الرقمي - Digital Creativity',
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color.fromARGB(255, 2, 34, 62),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                      'لتطوير وانشاء تطبيقات المتاجر الالكترونية بانسب الاسعار و بتصاميم حديثة و جذابة',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                                    SizedBox(height: 100),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
