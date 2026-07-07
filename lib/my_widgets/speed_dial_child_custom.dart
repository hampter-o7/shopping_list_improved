import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'package:shopping_list/classes/colors.dart';
import 'package:shopping_list/my_widgets/language_service.dart';
import 'package:showcaseview/showcaseview.dart';

SpeedDialChild speedDialChildCustom({
  required BuildContext context,
  required IconData icon,
  required String labelKey,
  required VoidCallback onTap,
  GlobalKey? showcaseKey,
  String? showcaseDescription,
  ValueNotifier<bool>? speedDialOpen,
}) {
  final colors = AppColors.of(context);
  final iconWidget = Icon(icon, color: colors.resolvedFabIcon);

  void handleShowcaseTap() {
    speedDialOpen?.value = false;
    onTap();
  }

  return SpeedDialChild(
    child: showcaseKey == null
        ? iconWidget
        : Showcase(
            key: showcaseKey,
            description: showcaseDescription ?? '',
            disableBarrierInteraction: true,
            disposeOnTap: true,
            onTargetClick: handleShowcaseTap,
            child: iconWidget,
          ),
    label: context.read<LanguageService>().text(labelKey),
    labelBackgroundColor: colors.resolvedFabFill,
    labelStyle: TextStyle(color: colors.resolvedFabIcon),
    backgroundColor: colors.resolvedFabFill,
    onTap: showcaseKey == null ? onTap : null,
  );
}
