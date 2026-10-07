import 'package:flutter/material.dart';

/// Corner radius tokens.
abstract final class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius cardLarge = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius button = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius input = BorderRadius.all(Radius.circular(md));
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}
