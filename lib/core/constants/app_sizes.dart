import 'package:flutter/material.dart';

class AppSizes {
  const AppSizes._();

  static double scale(
    BuildContext context,
  ) {
    final width =
        MediaQuery.of(context).size.width;

    return (width / 390).clamp(
      0.8,
      1.2,
    );
  }
}
