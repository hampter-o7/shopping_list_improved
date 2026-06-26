import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_list/classes/colors.dart';
import 'package:shopping_list/my_widgets/color_picker_card.dart';
import 'package:shopping_list/my_widgets/theme_manager.dart';

class ColorPicker extends StatefulWidget {
  const ColorPicker({super.key});

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late Map<AppColorKey, Color> customColors = {};
  AppTheme selectedTheme = AppTheme.light;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ThemeManager themeManager = context.read<ThemeManager>();
    selectedTheme = themeManager.theme;
    ColorPalette? colorPalette = themeManager.getCustomPalette();
    if (colorPalette != null) {
      mapFromColorPalette(colorPalette);
    }
  }

  void mapFromColorPalette(ColorPalette palette) {
    customColors[AppColorKey.background] = palette.background;
    customColors[AppColorKey.primaryColor] = palette.primaryColor;
    customColors[AppColorKey.secondaryColor] = palette.secondaryColor;
    customColors[AppColorKey.progressBar] = palette.progressBar;
    setIfNotNull(AppColorKey.resolvedTitleText, palette.titleText);
    setIfNotNull(AppColorKey.resolvedItemBackground, palette.itemBackgroundCheckFill);
    setIfNotNull(AppColorKey.resolvedItemText, palette.itemText);
    setIfNotNull(AppColorKey.resolvedItemCheckbox, palette.itemCheckbox);
    setIfNotNull(AppColorKey.resolvedItemCrossed, palette.itemTextCrossed);
    setIfNotNull(AppColorKey.resolvedItemCrossedLine, palette.itemTextCrossedLine);
    setIfNotNull(AppColorKey.resolvedFabFill, palette.fabFill);
    setIfNotNull(AppColorKey.resolvedFabIcon, palette.fabIcon);
  }

  void setIfNotNull(AppColorKey key, Color? value) {
    if (value != null) {
      customColors[key] = value;
    }
  }

  ColorPalette mapToColorPalette() {
    ThemeManager themeManager = context.read<ThemeManager>();
    ColorPalette basePalette = themeManager.theme == AppTheme.system || themeManager.theme == AppTheme.custom
        ? (MediaQuery.platformBrightnessOf(context) == Brightness.dark ? AppColors.dark : AppColors.light)
        : themeManager.defaultPalette;
    ColorPalette newCustomPalette = ColorPalette(
      background: customColors[AppColorKey.background] ?? basePalette.background,
      primaryColor: customColors[AppColorKey.primaryColor] ?? basePalette.primaryColor,
      secondaryColor: customColors[AppColorKey.secondaryColor] ?? basePalette.secondaryColor,
      progressBar: customColors[AppColorKey.progressBar] ?? basePalette.progressBar,
      titleText: customColors[AppColorKey.resolvedTitleText],
      itemBackgroundCheckFill: customColors[AppColorKey.resolvedItemBackground],
      itemText: customColors[AppColorKey.resolvedItemText],
      itemCheckbox: customColors[AppColorKey.resolvedItemCheckbox],
      itemTextCrossed: customColors[AppColorKey.resolvedItemCrossed],
      itemTextCrossedLine: customColors[AppColorKey.resolvedItemCrossedLine],
      fabFill: customColors[AppColorKey.resolvedFabFill],
      fabIcon: customColors[AppColorKey.resolvedFabIcon],
    );
    return newCustomPalette;
  }

  void updateCustomColors(AppColorKey appColorKey, Color newColor, bool isRemove) {
    if (!isRemove) {
      customColors[appColorKey] = newColor;
    } else {
      customColors.remove(appColorKey);
    }
    ThemeManager themeManager = context.read<ThemeManager>();
    ColorPalette newCustomPalette = mapToColorPalette();
    themeManager.setCustomPalette(newCustomPalette);
    debugPrint(newCustomPalette.toJson().toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text(
          'THEME PICKER',
          style: TextStyle(color: AppColors.of(context).resolvedTitleText),
        ),
        centerTitle: true,
        backgroundColor: AppColors.of(context).resolvedTitleBackground,
        actions: [
          Visibility(
            visible: kDebugMode,
            child: IconButton(
              onPressed: () {
                final result = customColors.entries.map((entry) {
                  return "${entry.key}, ${entry.value.toARGB32().toRadixString(16).padLeft(8, '0')}";
                }).join("\n");
                debugPrint(result);
                debugPrint("");
              },
              icon: const Icon(Icons.print),
            ),
          ),
        ],
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.of(context).resolvedTitleText,
          ),
          onPressed: () => Navigator.pop(context),
        ),
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
              selectedTheme,
            },
            onSelectionChanged: (selection) {
              selectedTheme = selection.first;
              context.read<ThemeManager>().setTheme(selectedTheme);
              setState(() {});
            },
          ),
          Text(
            "Mandatory colors",
            style: TextStyle(
              fontSize: 20,
              color: AppColors.of(context).resolvedItemText,
            ),
          ),
          ColorPickerCard(
            name: "Background",
            isNotMandatory: false,
            colorKey: AppColorKey.background,
            customColors: customColors,
            updateCustomColors: updateCustomColors,
          ),
          ColorPickerCard(
            name: "Primary color",
            isNotMandatory: false,
            colorKey: AppColorKey.primaryColor,
            customColors: customColors,
            updateCustomColors: updateCustomColors,
          ),
          ColorPickerCard(
            name: "Secondary color",
            isNotMandatory: false,
            colorKey: AppColorKey.secondaryColor,
            customColors: customColors,
            updateCustomColors: updateCustomColors,
          ),
          ColorPickerCard(
            name: "Progress bar",
            isNotMandatory: false,
            colorKey: AppColorKey.progressBar,
            customColors: customColors,
            updateCustomColors: updateCustomColors,
          ),
          Text(
            "Optional colors (derived from mandatory)",
            style: TextStyle(
              fontSize: 16,
              color: AppColors.of(context).resolvedItemText,
            ),
          ),
          ColorPickerCard(
            name: "Title text",
            isNotMandatory: true,
            colorKey: AppColorKey.resolvedTitleText,
            customColors: customColors,
            updateCustomColors: updateCustomColors,
          ),
          ColorPickerCard(
            name: "Item background",
            isNotMandatory: true,
            colorKey: AppColorKey.resolvedItemBackground,
            customColors: customColors,
            updateCustomColors: updateCustomColors,
          ),
          ColorPickerCard(
            name: "Item text",
            isNotMandatory: true,
            colorKey: AppColorKey.resolvedItemText,
            customColors: customColors,
            updateCustomColors: updateCustomColors,
          ),
          ColorPickerCard(
            name: "Item checkbox",
            isNotMandatory: true,
            colorKey: AppColorKey.resolvedItemCheckbox,
            customColors: customColors,
            updateCustomColors: updateCustomColors,
          ),
          ColorPickerCard(
            name: "Crossed item text",
            isNotMandatory: true,
            colorKey: AppColorKey.resolvedItemCrossed,
            customColors: customColors,
            updateCustomColors: updateCustomColors,
          ),
          ColorPickerCard(
            name: "Item crossed line",
            isNotMandatory: true,
            colorKey: AppColorKey.resolvedItemCrossedLine,
            customColors: customColors,
            updateCustomColors: updateCustomColors,
          ),
          ColorPickerCard(
            name: "Action button icon",
            isNotMandatory: true,
            colorKey: AppColorKey.resolvedFabIcon,
            customColors: customColors,
            updateCustomColors: updateCustomColors,
          ),
        ],
      ),
    );
  }
}
