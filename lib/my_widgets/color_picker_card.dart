import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_list/classes/colors.dart';
import 'package:shopping_list/my_widgets/language_service.dart';
import 'package:shopping_list/my_widgets/theme_manager.dart';

class ColorPickerCard extends StatefulWidget {
  final String name;
  final bool isNotMandatory;
  final AppColorKey colorKey;
  final Map<AppColorKey, Color> customColors;
  final Function updateCustomColors;

  const ColorPickerCard({
    super.key,
    required this.name,
    required this.isNotMandatory,
    required this.colorKey,
    required this.customColors,
    required this.updateCustomColors,
  });

  @override
  State<ColorPickerCard> createState() => _ColorPickerCard();
}

class _ColorPickerCard extends State<ColorPickerCard> {
  late Color colorPicked = widget.customColors[widget.colorKey] ?? AppColors.of(context).getByKey(widget.colorKey);

  @override
  void didUpdateWidget(covariant ColorPickerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    colorPicked = widget.customColors[widget.colorKey] ?? AppColors.of(context).getByKey(widget.colorKey);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.of(context).resolvedItemBackground,
      child: ListTile(
        title: Text(
          widget.name,
          style: TextStyle(
            color: AppColors.of(context).resolvedItemText,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                ThemeManager themeManager = context.read<ThemeManager>();
                ColorPalette basePalette = themeManager.theme == AppTheme.system || themeManager.theme == AppTheme.custom
                    ? (MediaQuery.platformBrightnessOf(context) == Brightness.dark ? AppColors.dark : AppColors.light)
                    : themeManager.defaultPalette;
                Color defaultColor = basePalette.getByKey(widget.colorKey);
                colorPicked = defaultColor;
                widget.updateCustomColors(widget.colorKey, defaultColor, true);
                setState(() {});
              },
              icon: Icon(!widget.isNotMandatory ? Icons.close : Icons.calculate),
              style: ButtonStyle(
                iconColor: WidgetStatePropertyAll(
                  AppColors.of(context).resolvedItemText,
                ),
              ),
            ),
            ColorIndicator(
              width: 40,
              height: 40,
              borderRadius: 0,
              color: colorPicked,
              elevation: 1,
              onSelect: () async {
                final Color newColor = await showColorPickerDialog(
                  context,
                  colorPicked,
                  title: Text(context.read<LanguageService>().text("colorPickerCard.title"), style: Theme.of(context).textTheme.titleLarge),
                  heading: Text(context.read<LanguageService>().text("colorPickerCard.heading"), style: Theme.of(context).textTheme.titleLarge),
                  subheading: Text(context.read<LanguageService>().text("colorPickerCard.subheading"), style: Theme.of(context).textTheme.titleSmall),
                  width: 50,
                  height: 50,
                  spacing: 4,
                  runSpacing: 4,
                  borderRadius: 10,
                  elevation: 0,
                  enableOpacity: false,
                  showColorCode: false,
                  pickersEnabled: <ColorPickerType, bool>{
                    ColorPickerType.both: false,
                    ColorPickerType.primary: true,
                    ColorPickerType.accent: false,
                    ColorPickerType.bw: false,
                    ColorPickerType.custom: false,
                    ColorPickerType.wheel: true,
                  },
                  copyPasteBehavior: const ColorPickerCopyPasteBehavior(
                    copyButton: false,
                    pasteButton: false,
                    longPressMenu: false,
                  ),
                  actionButtons: const ColorPickerActionButtons(
                    okButton: true,
                    closeButton: true,
                    dialogActionButtons: false,
                  ),
                );
                colorPicked = newColor;
                widget.updateCustomColors(widget.colorKey, newColor, false);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}
