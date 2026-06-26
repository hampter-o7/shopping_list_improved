import 'package:flutter/material.dart';
import 'package:shopping_list/classes/colors.dart';
import 'package:shopping_list/storage/local_storage.dart';

enum AppTheme {
  light,
  system,
  custom,
  dark,
}

class ThemeManager extends ChangeNotifier {
  AppTheme _theme = AppTheme.light;
  ColorPalette? _customPalette;

  ThemeManager() {
    _init();
  }

  Future<void> _init() async {
    final savedTheme = await Storage.loadThemeMode();
    _theme = AppTheme.values[savedTheme];

    _customPalette = await Storage.loadCostumeTheme();

    notifyListeners();
  }

  AppTheme get theme => _theme;

  ThemeData get lightTheme => ThemeData.light().copyWith(
        extensions: [
          _theme == AppTheme.custom ? (_customPalette ?? AppColors.light) : AppColors.light,
        ],
      );

  ThemeData get darkTheme => ThemeData.dark().copyWith(
        extensions: [
          _theme == AppTheme.custom ? (_customPalette ?? AppColors.dark) : AppColors.dark,
        ],
      );

  ThemeMode get themeMode {
    switch (_theme) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
        return ThemeMode.dark;
      case AppTheme.system:
        return ThemeMode.system;
      case AppTheme.custom:
        return ThemeMode.system;
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    _theme = theme;

    await Storage.saveThemeMode(theme.index);

    notifyListeners();
  }

  Future<void> setCustomPalette(ColorPalette palette) async {
    _customPalette = palette;

    await Storage.saveCostumeTheme(palette);

    if (_theme == AppTheme.custom) {
      notifyListeners();
    }
  }

  ColorPalette? getCustomPalette() {
    return _customPalette;
  }

  ColorPalette get defaultPalette {
    return _theme == AppTheme.dark ? AppColors.dark : AppColors.light;
  }
}
