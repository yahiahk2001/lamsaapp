import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../widgets/common/connectivity_wrapper.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ConnectivityWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'من نحن',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          backgroundColor:AppColors.backgroundWhite,
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
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // شعار المتجر
                Image.asset(
                  'assets/logo.png',
                  height: 120,
                  width: 120,
                ),
                
                SizedBox(height: 24),
                
                // العنوان
                Text(
                  'من نحن',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 20),
                
                // النص
                Text(
                  'في لمسة، نؤمن أن الحلوى ليست مجرد طعمٍ لذيذ، بل هي لحظة فرح وذكريات تبقى عالقة في القلب.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.justify,
                ),
                
                SizedBox(height: 16),
                
                Text(
                  'من هذا الإيمان انطلقت رحلتنا لنقدّم لكم عالمًا من أشهى الحلويات، بأسعار الجملة، ومع خدمة توصيل مجانية تصل إليكم بسهولة وسرعة أينما كنتم.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.justify,
                ),
                
                SizedBox(height: 16),
                
                Text(
                  'رؤيتنا أن نجعل تجربة شراء الحلوى أكثر متعة وسلاسة، تجمع بين التنوع والجودة والسعر المناسب، لتكون كل قطعة حلوى لمسة تضيف البهجة ليومكم.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.justify,
                ),
                
                SizedBox(height: 16),
                
                Text(
                  'ولأن الشغف لا يعرف حدودًا ✨، فإن طموحنا يتجاوز الحلوى، لنكون منصتكم الأولى للتسوق، حيث تجدون كل ما يضيف لحياتكم قيمة وسعادة.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
