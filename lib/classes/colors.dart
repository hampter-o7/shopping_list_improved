import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static final light = ColorPalette(
    background: const Color(0xFFFFFFFF),
    primaryColor: const Color(0xFFF57C00),
    secondaryColor: const Color(0xFF1976D2),
    progressBar: const Color(0xFF4CAF50),
  );

  static final dark = ColorPalette(
    background: const Color(0xFF121212),
    primaryColor: const Color(0xFF1E3A8A),
    secondaryColor: const Color(0xFF5B21B6),
    progressBar: const Color(0xFF4CAF50),
  );

  static ColorPalette of(BuildContext context) {
    return Theme.of(context).extension<ColorPalette>()!;
  }

  static Color invertColor(Color color) {
    return Color.fromARGB(
      (color.a * 255).round(),
      255 - (color.r * 255).round(),
      255 - (color.g * 255).round(),
      255 - (color.b * 255).round(),
    );
  }

  static Color overlayColor(Color color, int overplayOpacity) {
    double alpha = overplayOpacity / 100;
    return Color.fromARGB(
      (color.a * 255).round(),
      ((1 - alpha) * (color.r * 255).round() + alpha * 0xFF).round(),
      ((1 - alpha) * (color.g * 255).round() + alpha * 0xFF).round(),
      ((1 - alpha) * (color.b * 255).round() + alpha * 0xFF).round(),
    );
  }

  static Color onColor(Color background) {
    return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}

@immutable
class ColorPalette extends ThemeExtension<ColorPalette> {
  final Color background;
  final Color primaryColor;
  final Color secondaryColor;
  final Color? titleBackground;
  final Color? titleText;
  final Color? itemBackgroundCheckFill;
  final Color? itemText;
  final Color? itemCheckbox;
  final Color? itemTextCrossed;
  final Color? itemTextCrossedLine;
  final Color? fabFill;
  final Color? fabIcon;
  final Color progressBar;

  const ColorPalette({
    required this.background,
    required this.primaryColor,
    required this.secondaryColor,
    this.titleBackground,
    this.titleText,
    this.itemBackgroundCheckFill,
    this.itemText,
    this.itemCheckbox,
    this.itemTextCrossed,
    this.itemTextCrossedLine,
    this.fabFill,
    this.fabIcon,
    required this.progressBar,
  });

  Color get resolvedTitleBackground => titleBackground ?? primaryColor;
  Color get resolvedTitleText => titleText ?? AppColors.onColor(resolvedTitleBackground);
  Color get resolvedItemBackground => itemBackgroundCheckFill ?? AppColors.overlayColor(background, 8);
  Color get resolvedItemText => itemText ?? AppColors.onColor(resolvedItemBackground);
  Color get resolvedItemCheckbox => itemCheckbox ?? AppColors.onColor(resolvedItemBackground);
  Color get resolvedItemCrossed => itemTextCrossed ?? resolvedItemText;
  Color get resolvedItemCrossedLine => itemTextCrossedLine?.withValues(alpha: 0.6) ?? resolvedItemCrossed.withValues(alpha: 0.6);
  Color get resolvedFabFill => fabFill ?? secondaryColor;
  Color get resolvedFabIcon => fabIcon ?? AppColors.onColor(resolvedFabFill);

  Map<String, dynamic> toJson() {
    return {
      'background': _colorToHex(background),
      'primaryColor': _colorToHex(primaryColor),
      'secondaryColor': _colorToHex(secondaryColor),
      'titleBackground': _colorToHexNullable(titleBackground),
      'titleText': _colorToHexNullable(titleText),
      'itemBackgroundCheckFill': _colorToHexNullable(itemBackgroundCheckFill),
      'itemText': _colorToHexNullable(itemText),
      'itemCheckbox': _colorToHexNullable(itemCheckbox),
      'itemTextCrossed': _colorToHexNullable(itemTextCrossed),
      'itemTextCrossedLine': _colorToHexNullable(itemTextCrossedLine),
      'fabFill': _colorToHexNullable(fabFill),
      'fabIcon': _colorToHexNullable(fabIcon),
      'progressBar': _colorToHex(progressBar),
    };
  }

  static String _colorToHex(Color color) {
    return color.toARGB32().toRadixString(16).padLeft(8, '0');
  }

  static String? _colorToHexNullable(Color? color) {
    return color == null ? null : _colorToHex(color).toUpperCase();
  }

  static Color _hexToColor(String hex) {
    return Color(int.parse('0x$hex'));
  }

  static Color? _hexToColorNullable(String? hex) {
    if (hex == null) return null;
    return _hexToColor(hex);
  }

  static ColorPalette fromJson(Map<String, dynamic> json) {
    return ColorPalette(
      background: _hexToColor(json['background']),
      primaryColor: _hexToColor(json['primaryColor']),
      secondaryColor: _hexToColor(json['secondaryColor']),
      titleBackground: _hexToColorNullable(json['titleBackground']),
      titleText: _hexToColorNullable(json['titleText']),
      itemBackgroundCheckFill: _hexToColorNullable(json['itemBackgroundCheckFill']),
      itemText: _hexToColorNullable(json['itemText']),
      itemCheckbox: _hexToColorNullable(json['itemCheckbox']),
      itemTextCrossed: _hexToColorNullable(json['itemTextCrossed']),
      itemTextCrossedLine: _hexToColorNullable(json['itemTextCrossedLine']),
      fabFill: _hexToColorNullable(json['fabFill']),
      fabIcon: _hexToColorNullable(json['fabIcon']),
      progressBar: _hexToColor(json['progressBar']),
    );
  }

  @override
  ColorPalette copyWith({
    Color? background,
    Color? primaryColor,
    Color? secondaryColor,
    Color? progressBar,
  }) {
    return ColorPalette(
      background: background ?? this.background,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      titleBackground: titleBackground,
      titleText: titleText,
      itemBackgroundCheckFill: itemBackgroundCheckFill,
      itemText: itemText,
      itemCheckbox: itemCheckbox,
      itemTextCrossed: itemTextCrossed,
      itemTextCrossedLine: itemTextCrossedLine,
      fabFill: fabFill,
      fabIcon: fabIcon,
      progressBar: progressBar ?? this.progressBar,
    );
  }

  ColorPalette merge(ColorPalette o) {
    return ColorPalette(
      background: o.background,
      primaryColor: o.primaryColor,
      secondaryColor: o.secondaryColor,
      titleBackground: o.titleBackground ?? titleBackground,
      titleText: o.titleText ?? titleText,
      itemBackgroundCheckFill: o.itemBackgroundCheckFill ?? itemBackgroundCheckFill,
      itemText: o.itemText ?? itemText,
      itemCheckbox: o.itemCheckbox ?? itemCheckbox,
      itemTextCrossed: o.itemTextCrossed ?? itemTextCrossed,
      itemTextCrossedLine: o.itemTextCrossedLine ?? itemTextCrossedLine,
      fabFill: o.fabFill ?? fabFill,
      fabIcon: o.fabIcon ?? fabIcon,
      progressBar: o.progressBar,
    );
  }

  @override
  ColorPalette lerp(
    ThemeExtension<ColorPalette>? other,
    double t,
  ) {
    if (other is! ColorPalette) return this;

    return ColorPalette(
      background: Color.lerp(background, other.background, t)!,
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t)!,
      secondaryColor: Color.lerp(secondaryColor, other.secondaryColor, t)!,
      titleBackground: Color.lerp(resolvedTitleBackground, other.resolvedTitleBackground, t)!,
      titleText: Color.lerp(resolvedTitleText, other.resolvedTitleText, t)!,
      itemBackgroundCheckFill: Color.lerp(resolvedItemBackground, other.resolvedItemBackground, t)!,
      itemText: Color.lerp(resolvedItemText, other.resolvedItemText, t)!,
      itemCheckbox: Color.lerp(resolvedItemCheckbox, other.resolvedItemCheckbox, t)!,
      itemTextCrossed: Color.lerp(resolvedItemCrossed, other.resolvedItemCrossed, t)!,
      itemTextCrossedLine: Color.lerp(resolvedItemCrossedLine, other.resolvedItemCrossedLine, t)!,
      fabFill: Color.lerp(resolvedFabFill, other.resolvedFabFill, t)!,
      fabIcon: Color.lerp(resolvedFabIcon, other.resolvedFabIcon, t)!,
      progressBar: Color.lerp(progressBar, other.progressBar, t)!,
    );
  }
}

enum AppColorKey {
  background,
  primaryColor,
  secondaryColor,
  resolvedTitleBackground,
  resolvedTitleText,
  resolvedItemBackground,
  resolvedItemText,
  resolvedItemCheckbox,
  resolvedItemCrossed,
  resolvedItemCrossedLine,
  resolvedFabFill,
  resolvedFabIcon,
  progressBar,
}

extension ColorPaletteX on ColorPalette {
  Color getByKey(AppColorKey key) {
    switch (key) {
      case AppColorKey.background:
        return background;

      case AppColorKey.primaryColor:
        return primaryColor;

      case AppColorKey.secondaryColor:
        return secondaryColor;

      case AppColorKey.resolvedTitleBackground:
        return resolvedTitleBackground;

      case AppColorKey.resolvedTitleText:
        return resolvedTitleText;

      case AppColorKey.resolvedItemBackground:
        return resolvedItemBackground;

      case AppColorKey.resolvedItemText:
        return resolvedItemText;

      case AppColorKey.resolvedItemCheckbox:
        return resolvedItemCheckbox;

      case AppColorKey.resolvedItemCrossed:
        return resolvedItemCrossed;

      case AppColorKey.resolvedItemCrossedLine:
        return resolvedItemCrossedLine;

      case AppColorKey.resolvedFabFill:
        return resolvedFabFill;

      case AppColorKey.resolvedFabIcon:
        return resolvedFabIcon;

      case AppColorKey.progressBar:
        return progressBar;
    }
  }
}
