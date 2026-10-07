import 'package:flutter/material.dart';

/// Animation duration and curve tokens.
abstract final class AppAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration splash = Duration(milliseconds: 900);
  static const Duration page = Duration(milliseconds: 300);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;
  static const Curve emphasized = Curves.easeInOutCubic;
}
