import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static final light = ColorPalette(
    background: const Color(0xFFFFFFFF),
    titleBackground: const Color(0xFFFF9800),
    titleText: const Color(0xFFFFFFFF),
    itemTextCrossed: const Color(0xFF222222),
    fabFill: const Color(0xFFFF9800),
    progressBar: const Color(0xFF4CAF50),
  );

  static final dark = ColorPalette(
    background: const Color(0xFF121212),
    itemTextCrossed: const Color(0xFFE0E0E0),
    fabFill: const Color(0xFF9C27B0),
    fabIcon: const Color(0xFF000000),
    progressBar: const Color(0xFF4CAF50),
  );

  static ColorPalette of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }

  static Color invertColor(Color color) {
    return Color.fromARGB(
      color.alpha,
      255 - color.red,
      255 - color.green,
      255 - color.blue,
    );
  }

  static Color overlayColor(Color color, int overplayOpacity) {
    double alpha = overplayOpacity / 100;
    return Color.fromARGB(
      color.alpha,
      ((1 - alpha) * color.red + alpha * 0xFF).round(),
      ((1 - alpha) * color.red + alpha * 0xFF).round(),
      ((1 - alpha) * color.red + alpha * 0xFF).round(),
    );
  }
}

class ColorPalette {
  final Color background;
  final Color titleBackground;
  final Color titleText;
  final Color itemBackgroundCheckFill;
  final Color itemTextNormalBorderCheck;
  final Color itemTextCrossed;
  final Color itemTextCrossedLine;
  final Color fabFill;
  final Color fabIcon;
  final Color progressBar;

  ColorPalette({
    required this.background,
    Color? titleBackground,
    Color? titleText,
    Color? itemBackgroundCheckFill,
    Color? itemTextNormalBorderCheck,
    required this.itemTextCrossed,
    Color? itemTextCrossedLine,
    required this.fabFill,
    Color? fabIcon,
    required this.progressBar,
  })  : titleBackground = titleBackground ?? AppColors.overlayColor(background, 16),
        titleText = titleText ?? AppColors.invertColor(titleBackground ?? AppColors.overlayColor(background, 16)),
        itemBackgroundCheckFill = itemBackgroundCheckFill ?? AppColors.overlayColor(background, 8),
        itemTextNormalBorderCheck =
            itemTextNormalBorderCheck ?? AppColors.invertColor(itemBackgroundCheckFill ?? AppColors.overlayColor(background, 8)),
        itemTextCrossedLine = itemTextCrossedLine ?? AppColors.invertColor(itemTextCrossed),
        fabIcon = fabIcon ?? AppColors.invertColor(fabFill);
}
