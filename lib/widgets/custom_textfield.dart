import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final IconData? icon;
  final String? errorText;

  const CustomTextField({
    super.key,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.icon,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(
        fontSize: width * 0.04,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: width * 0.04,
          color: Colors.black54,
        ),
        errorText: errorText,
        errorStyle: TextStyle(
          fontSize: width * 0.03,
          color: Colors.red,
        ),
        prefixIcon: icon != null 
          ? Icon(icon, color: Colors.black54, size: width * 0.05)
          : null,
        prefixIconConstraints: icon != null 
          ? BoxConstraints(minWidth: width * 0.06, minHeight: width * 0.06)
          : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: width * 0.04,
          vertical: width * 0.03,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(width * 0.03),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(width * 0.03),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(width * 0.03),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(width * 0.03),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(width * 0.03),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}
