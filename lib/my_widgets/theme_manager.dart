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

    _customPalette = await Storage.loadCustomTheme();

    notifyListeners();
  }

  AppTheme get theme => _theme;

  ThemeData get lightTheme => _buildTheme(
        _theme == AppTheme.custom ? (_customPalette ?? AppColors.light) : AppColors.light,
        Brightness.light,
      );

  ThemeData get darkTheme => _buildTheme(
        _theme == AppTheme.custom ? (_customPalette ?? AppColors.dark) : AppColors.dark,
        Brightness.dark,
      );

  ThemeData _buildTheme(ColorPalette palette, Brightness brightness) {
    final base = brightness == Brightness.light ? ThemeData.light() : ThemeData.dark();

    return base.copyWith(
      extensions: [palette],
      scaffoldBackgroundColor: palette.background,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.resolvedTitleBackground,
        foregroundColor: palette.resolvedTitleText,
        iconTheme: IconThemeData(color: palette.resolvedTitleText),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.resolvedFabFill,
        foregroundColor: palette.resolvedFabIcon,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateColor.resolveWith((states) => palette.resolvedItemBackground),
        checkColor: WidgetStateColor.resolveWith((states) => palette.resolvedItemCheckbox),
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BorderSide.none;
          }
          return BorderSide(width: 2.0, color: palette.resolvedItemCheckbox);
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.progressBar,
        linearTrackColor: palette.background,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.resolvedItemBackground,
        titleTextStyle: TextStyle(color: palette.resolvedTitleText, fontSize: 20),
        contentTextStyle: TextStyle(color: palette.resolvedItemText, fontSize: 16),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.resolvedItemBackground,
        contentTextStyle: TextStyle(color: palette.resolvedItemText, fontSize: 16),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: palette.resolvedItemText,
        displayColor: palette.resolvedItemText,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: palette.resolvedItemBackground,
        textColor: palette.resolvedItemText,
        iconColor: palette.resolvedItemText,
      ),
      cardTheme: CardThemeData(
        color: palette.resolvedItemBackground,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.resolvedItemBackground,
        iconColor: palette.resolvedItemText,
        labelTextStyle: WidgetStateProperty.all(TextStyle(color: palette.resolvedItemText)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(palette.primaryColor),
          foregroundColor: WidgetStateProperty.all(palette.resolvedTitleText),
        ),
      ),
    );
  }

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

  Future<void> setCustomPalette(ColorPalette? palette) async {
    if (palette == null) {
      return;
    }
    _customPalette = palette;

    await Storage.saveCustomTheme(palette);

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
