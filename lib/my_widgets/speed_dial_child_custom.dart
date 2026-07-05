import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'package:shopping_list/classes/colors.dart';
import 'package:shopping_list/my_widgets/language_service.dart';

SpeedDialChild speedDialChildCustom({
  required BuildContext context,
  required IconData icon,
  required String labelKey,
  required VoidCallback onTap,
}) {
  final colors = AppColors.of(context);
  return SpeedDialChild(
    child: Icon(icon, color: colors.resolvedFabIcon),
    label: context.read<LanguageService>().text(labelKey),
    labelBackgroundColor: colors.resolvedFabFill,
    labelStyle: TextStyle(color: colors.resolvedFabIcon),
    backgroundColor: colors.resolvedFabFill,
    onTap: onTap,
  );
}
