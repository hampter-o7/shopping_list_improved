import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_list/classes/colors.dart';
import 'package:shopping_list/my_widgets/color_picker_card.dart';
import 'package:shopping_list/my_widgets/language_service.dart';
import 'package:shopping_list/my_widgets/scroll_card.dart';
import 'package:shopping_list/my_widgets/theme_manager.dart';

class ColorPicker extends StatefulWidget {
  const ColorPicker({super.key});

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  final Map<AppColorKey, Color> _customColors = {};
  AppTheme _selectedTheme = AppTheme.light;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ThemeManager themeManager = context.read<ThemeManager>();
    _selectedTheme = themeManager.theme;
    ColorPalette? colorPalette = themeManager.getCustomPalette();
    if (colorPalette != null) {
      _mapFromColorPalette(colorPalette);
    }
  }

  void _mapFromColorPalette(ColorPalette palette) {
    _customColors[AppColorKey.background] = palette.background;
    _customColors[AppColorKey.primaryColor] = palette.primaryColor;
    _customColors[AppColorKey.secondaryColor] = palette.secondaryColor;
    _customColors[AppColorKey.progressBar] = palette.progressBar;
    _setIfNotNull(AppColorKey.resolvedTitleText, palette.titleText);
    _setIfNotNull(AppColorKey.resolvedItemBackground, palette.itemBackgroundCheckFill);
    _setIfNotNull(AppColorKey.resolvedItemText, palette.itemText);
    _setIfNotNull(AppColorKey.resolvedItemCheckbox, palette.itemCheckbox);
    _setIfNotNull(AppColorKey.resolvedItemCrossed, palette.itemTextCrossed);
    _setIfNotNull(AppColorKey.resolvedItemCrossedLine, palette.itemTextCrossedLine);
    _setIfNotNull(AppColorKey.resolvedFabFill, palette.fabFill);
    _setIfNotNull(AppColorKey.resolvedFabIcon, palette.fabIcon);
  }

  void _setIfNotNull(AppColorKey key, Color? value) {
    if (value != null) {
      _customColors[key] = value;
    }
  }

  ColorPalette _mapToColorPalette() {
    ThemeManager themeManager = context.read<ThemeManager>();
    ColorPalette basePalette = themeManager.theme == AppTheme.system || themeManager.theme == AppTheme.custom
        ? (MediaQuery.platformBrightnessOf(context) == Brightness.dark ? AppColors.dark : AppColors.light)
        : themeManager.defaultPalette;
    ColorPalette newCustomPalette = ColorPalette(
      background: _customColors[AppColorKey.background] ?? basePalette.background,
      primaryColor: _customColors[AppColorKey.primaryColor] ?? basePalette.primaryColor,
      secondaryColor: _customColors[AppColorKey.secondaryColor] ?? basePalette.secondaryColor,
      progressBar: _customColors[AppColorKey.progressBar] ?? basePalette.progressBar,
      titleText: _customColors[AppColorKey.resolvedTitleText],
      itemBackgroundCheckFill: _customColors[AppColorKey.resolvedItemBackground],
      itemText: _customColors[AppColorKey.resolvedItemText],
      itemCheckbox: _customColors[AppColorKey.resolvedItemCheckbox],
      itemTextCrossed: _customColors[AppColorKey.resolvedItemCrossed],
      itemTextCrossedLine: _customColors[AppColorKey.resolvedItemCrossedLine],
      fabFill: _customColors[AppColorKey.resolvedFabFill],
      fabIcon: _customColors[AppColorKey.resolvedFabIcon],
    );
    return newCustomPalette;
  }

  void _updateCustomColors(AppColorKey appColorKey, Color newColor, bool isRemove) {
    if (!isRemove) {
      _customColors[appColorKey] = newColor;
    } else {
      _customColors.remove(appColorKey);
    }
    ThemeManager themeManager = context.read<ThemeManager>();
    ColorPalette newCustomPalette = _mapToColorPalette();
    themeManager.setCustomPalette(newCustomPalette);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.read<LanguageService>().text("colorPicker.title").toUpperCase()),
        centerTitle: true,
        actions: [
          Visibility(
            visible: kDebugMode,
            child: IconButton(
              onPressed: () {
                final result = _customColors.entries.map((entry) {
                  return "${entry.key}, ${entry.value.toARGB32().toRadixString(16).padLeft(8, '0')}";
                }).join("\n");
                debugPrint(result);
              },
              icon: const Icon(Icons.print),
            ),
          ),
        ],
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SegmentedButton<AppTheme>(
            style: SegmentedButton.styleFrom(
              backgroundColor: AppColors.of(context).resolvedItemBackground,
              foregroundColor: AppColors.of(context).resolvedItemText,
              selectedBackgroundColor: AppColors.of(context).resolvedItemText,
              selectedForegroundColor: AppColors.of(context).resolvedItemBackground,
              side: BorderSide(color: AppColors.of(context).resolvedItemBackground, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            segments: const [
              ButtonSegment(value: AppTheme.light, icon: Icon(Icons.light_mode)),
              ButtonSegment(value: AppTheme.system, icon: Icon(Icons.phone_android)),
              ButtonSegment(value: AppTheme.custom, icon: Icon(Icons.settings)),
              ButtonSegment(value: AppTheme.dark, icon: Icon(Icons.dark_mode)),
            ],
            selected: {
              _selectedTheme,
            },
            onSelectionChanged: (selection) {
              _selectedTheme = selection.first;
              context.read<ThemeManager>().setTheme(_selectedTheme);
              setState(() {});
            },
          ),
          Text(
            context.read<LanguageService>().text("colorPicker.mandatory"),
            style: TextStyle(fontSize: 20, color: AppColors.of(context).resolvedItemText),
          ),
          ColorPickerCard(
            name: context.read<LanguageService>().text("colorPicker.background"),
            isNotMandatory: false,
            colorKey: AppColorKey.background,
            customColors: _customColors,
            updateCustomColors: _updateCustomColors,
          ),
          ColorPickerCard(
            name: context.read<LanguageService>().text("colorPicker.primary"),
            isNotMandatory: false,
            colorKey: AppColorKey.primaryColor,
            customColors: _customColors,
            updateCustomColors: _updateCustomColors,
          ),
          ColorPickerCard(
            name: context.read<LanguageService>().text("colorPicker.secondary"),
            isNotMandatory: false,
            colorKey: AppColorKey.secondaryColor,
            customColors: _customColors,
            updateCustomColors: _updateCustomColors,
          ),
          ColorPickerCard(
            name: context.read<LanguageService>().text("colorPicker.progressBar"),
            isNotMandatory: false,
            colorKey: AppColorKey.progressBar,
            customColors: _customColors,
            updateCustomColors: _updateCustomColors,
          ),
          Text(
            context.read<LanguageService>().text("colorPicker.optional"),
            style: TextStyle(fontSize: 16, color: AppColors.of(context).resolvedItemText),
          ),
          ColorPickerCard(
            name: context.read<LanguageService>().text("colorPicker.titleText"),
            isNotMandatory: true,
            colorKey: AppColorKey.resolvedTitleText,
            customColors: _customColors,
            updateCustomColors: _updateCustomColors,
          ),
          ColorPickerCard(
            name: context.read<LanguageService>().text("colorPicker.itemBackground"),
            isNotMandatory: true,
            colorKey: AppColorKey.resolvedItemBackground,
            customColors: _customColors,
            updateCustomColors: _updateCustomColors,
          ),
          ColorPickerCard(
            name: context.read<LanguageService>().text("colorPicker.itemText"),
            isNotMandatory: true,
            colorKey: AppColorKey.resolvedItemText,
            customColors: _customColors,
            updateCustomColors: _updateCustomColors,
          ),
          ColorPickerCard(
            name: context.read<LanguageService>().text("colorPicker.itemCheckbox"),
            isNotMandatory: true,
            colorKey: AppColorKey.resolvedItemCheckbox,
            customColors: _customColors,
            updateCustomColors: _updateCustomColors,
          ),
          ColorPickerCard(
            name: context.read<LanguageService>().text("colorPicker.itemCrossed"),
            isNotMandatory: true,
            colorKey: AppColorKey.resolvedItemCrossed,
            customColors: _customColors,
            updateCustomColors: _updateCustomColors,
          ),
          ColorPickerCard(
            name: context.read<LanguageService>().text("colorPicker.itemCrossedLine"),
            isNotMandatory: true,
            colorKey: AppColorKey.resolvedItemCrossedLine,
            customColors: _customColors,
            updateCustomColors: _updateCustomColors,
          ),
          ColorPickerCard(
            name: context.read<LanguageService>().text("colorPicker.fabIcon"),
            isNotMandatory: true,
            colorKey: AppColorKey.resolvedFabIcon,
            customColors: _customColors,
            updateCustomColors: _updateCustomColors,
          ),
          const ScrollCard(),
        ],
      ),
    );
  }
}
