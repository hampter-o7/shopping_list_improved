import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:implicitly_animated_reorderable_list_2/transitions.dart';
import 'package:shopping_list/classes/app_colors.dart';
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
    setState(() {});
  }

  void removeItem(Item item) {
    allItemsList.remove(item);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text('All items list', style: TextStyle(color: AppColors.invertColor(AppColors.of(context).titleBackground))),
        centerTitle: true,
        backgroundColor: AppColors.of(context).titleBackground,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.invertColor(AppColors.of(context).titleBackground)),
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
      body: ImplicitlyAnimatedReorderableList<Item>(
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
    );
  }
}
