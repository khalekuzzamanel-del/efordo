import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;

  static BorderRadius get smCircular => BorderRadius.circular(sm);
  static BorderRadius get mdCircular => BorderRadius.circular(md);
  static BorderRadius get lgCircular => BorderRadius.circular(lg);
  static BorderRadius get xlCircular => BorderRadius.circular(xl);
}
