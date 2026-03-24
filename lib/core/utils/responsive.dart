import 'package:flutter/material.dart';

class Responsive {

  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double height(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static double font(BuildContext context, double size) =>
      width(context) * size;
}