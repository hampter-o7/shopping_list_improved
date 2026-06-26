import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:implicitly_animated_reorderable_list_2/transitions.dart';
import 'package:shopping_list/classes/colors.dart';
import 'package:shopping_list/classes/item.dart';

import '../my_widgets/all_item_card.dart';
import '../storage/local_storage.dart';

class AllItemsList extends StatefulWidget {
  const AllItemsList({super.key});

  @override
  State<AllItemsList> createState() => _AllItemsListState();
}

class _AllItemsListState extends State<AllItemsList> {
  List<Item> allItemsList = [];
  double progress = 0;

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    allItemsList = await Storage.loadAllItems();
    updateWindow();
  }

  void updateWindow() {
    allItemsList.sort(
      (a, b) {
        if (a.isChecked && !b.isChecked) {
          return 1;
        } else if (!a.isChecked && b.isChecked) {
          return -1;
        } else {
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
      },
    );
    updateProgressBar();
  }

  void updateProgressBar() {
    if (allItemsList.isEmpty) {
      progress = 0;
    } else {
      int numberOfIsChecked = 0;
      for (Item item in allItemsList) {
        if (item.isChecked) numberOfIsChecked++;
      }
      progress = numberOfIsChecked / allItemsList.length;
    }
    setState(() {});
  }

  void removeItem(Item item) {
    allItemsList.remove(item);
    updateProgressBar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text('ALL ITEMS', style: TextStyle(color: AppColors.of(context).resolvedTitleText)),
        centerTitle: true,
        backgroundColor: AppColors.of(context).resolvedTitleBackground,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.of(context).resolvedTitleText),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Visibility(
            visible: kDebugMode,
            child: IconButton(
              onPressed: () {
                Storage.printAllSavedData();
              },
              icon: const Icon(Icons.print),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Visibility(
            visible: allItemsList.isNotEmpty,
            child: Container(
              color: AppColors.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: SizedBox(
                height: 20,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.of(context).progressBar,
                        ),
                        backgroundColor: AppColors.of(context).background,
                        minHeight: 20,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: Text(
                        '${(progress * 100).toInt()}%',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.onColor(AppColors.of(context).background),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ImplicitlyAnimatedReorderableList<Item>(
                items: allItemsList,
                itemBuilder: (context, animation, item, index) {
                  return Reorderable(
                    key: ValueKey(index),
                    child: AllItemCard(item: item, removeItem: removeItem, update: updateWindow),
                    builder: (context, animation, inDrag) => const SizeFadeTransition(animation: AlwaysStoppedAnimation(1.0)),
                  );
                },
                areItemsTheSame: (a, b) => false,
                onReorderFinished: (Item item, int from, int to, List<Item> newItems) {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
