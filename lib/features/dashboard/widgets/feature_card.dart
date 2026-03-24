import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class FeatureCard extends StatelessWidget {

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const FeatureCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,

  });

  @override
  Widget build(BuildContext context) {

    // ✅ MediaQuery INSIDE WIDGET
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return GestureDetector(
        onTap: onTap,
        child:Container(
      padding: EdgeInsets.all(width * 0.04),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.04),
        boxShadow: [
          BoxShadow(
            blurRadius: width * 0.02,
            color: Colors.black12,
            offset: Offset(0, height * 0.005),
          )
        ],
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          // ✅ Icon Responsive
          Icon(
            icon,
            size: width * 0.12,
            color: AppColors.primary,
          ),

          SizedBox(height: height * 0.015),

          // ✅ Text Responsive
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: width * 0.04,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ));
  }
}