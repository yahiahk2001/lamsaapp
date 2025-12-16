import 'package:flutter/material.dart';
import '../../../widgets/common/search_widget.dart';
import '../../../utils/colors.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
                  surfaceTintColor: AppColors.backgroundWhite,

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'البحث',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SearchWidget(
        onSearchStateChanged: (isSearching) {
          // يمكن إضافة منطق إضافي هنا إذا لزم الأمر
        },
        onSearchCleared: () {
          // يمكن إضافة منطق إضافي هنا إذا لزم الأمر
        },
      ),
    );
  }
}
