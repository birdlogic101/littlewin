import 'package:flutter/material.dart';

class LWRadius {
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double pill = 360.0; // "360px" interpreted as a large number for Flutter

  static final BorderRadius small = BorderRadius.circular(xs);
  static final BorderRadius medium = BorderRadius.circular(md);
  static final BorderRadius large = BorderRadius.circular(lg);
  static final BorderRadius full = BorderRadius.circular(pill);
}
