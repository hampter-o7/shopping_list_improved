import 'package:flutter/material.dart';
import 'package:shopping_list/classes/app_colors.dart';

class ScrollCard extends StatelessWidget {
  const ScrollCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.of(context).background,
      key: const Key('emptyCard'),
      semanticContainer: false,
      child: const SizedBox(height: 150),
    );
  }
}
