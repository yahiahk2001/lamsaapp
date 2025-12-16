// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../../utils/colors.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.backgroundWhite,
            AppColors.backgroundWhite.withOpacity(0.95),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.12),
            blurRadius: 20,
            offset: Offset(0, -4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.05),
            blurRadius: 40,
            offset: Offset(0, -2),
            spreadRadius: 0,
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6),
          child: GNav(
            rippleColor: AppColors.primaryColor.withOpacity(0.15),
            hoverColor: AppColors.primaryColor.withOpacity(0.15),
            gap: 6,
            activeColor: AppColors.primaryColor,
            iconSize: 22,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            duration: Duration(milliseconds: 500),
            tabBackgroundColor: AppColors.primaryColor.withOpacity(0.08),
            color: AppColors.textSecondary,
            selectedIndex: currentIndex,
            onTabChange: onTap,
            curve: Curves.easeInOutCubic,
            tabs: [
              _buildTab(
                icon: Icons.home_rounded,
                activeIcon: Icons.home_filled,
                text: 'الرئيسية',
                index: 0,
              ),
              _buildTab(
                icon: Icons.receipt_long_rounded,
                activeIcon: Icons.receipt_long,
                text: 'طلباتي',
                index: 1,
              ),
              _buildTab(
                icon: Icons.person_rounded,
                activeIcon: Icons.person,
                text: 'الملف الشخصي',
                index: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  GButton _buildTab({
    required IconData icon,
    required IconData activeIcon,
    required String text,
    required int index,
  }) {
    final isActive = currentIndex == index;
    
    return GButton(
      icon: isActive ? activeIcon : icon,
      text: text,
      iconActiveColor: AppColors.buttonColor,
      textColor: AppColors.buttonColor,
      backgroundColor: AppColors.buttonColor.withOpacity(0.08),
      iconSize: isActive ? 24 : 22,
      textStyle: TextStyle(
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
        fontSize: isActive ? 12 : 11,
      ),
      leading: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: isActive 
            ? LinearGradient(
                colors: [
                  AppColors.buttonColor.withOpacity(0.15),
                  AppColors.buttonLightColor.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
          boxShadow: isActive ? [
            BoxShadow(
              color: AppColors.buttonColor.withOpacity(0.2),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ] : null,
        ),
        child: Icon(
          isActive ? activeIcon : icon,
          color: isActive ? AppColors.buttonColor : AppColors.textSecondary,
          size: isActive ? 24 : 22,
        ),
      ),
    );
  }
}
