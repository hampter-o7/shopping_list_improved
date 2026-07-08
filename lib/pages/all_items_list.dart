import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_list/classes/colors.dart';
import 'package:shopping_list/classes/item.dart';
import 'package:shopping_list/my_widgets/item_card.dart';
import 'package:shopping_list/my_widgets/language_service.dart';
import 'package:shopping_list/my_widgets/scroll_card.dart';
import 'package:shopping_list/storage/local_storage.dart';

class AllItemsList extends StatefulWidget {
  const AllItemsList({super.key});

  @override
  State<AllItemsList> createState() => _AllItemsListState();
}

class _AllItemsListState extends State<AllItemsList> {
  double _progress = 0;
  List<Item> _allItemsList = [];

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    _allItemsList = await Storage.loadAllItems();
    _sortAndUpdateProgressBar();
  }

  void _sortAndUpdateProgressBar() {
    _allItemsList.sort(
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
    _updateProgressBar();
  }

  void _updateProgressBar() {
    if (_allItemsList.isEmpty) {
      _progress = 0;
    } else {
      int numberOfIsChecked = 0;
      for (Item item in _allItemsList) {
        if (item.isChecked) numberOfIsChecked++;
      }
      _progress = numberOfIsChecked / _allItemsList.length;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.read<LanguageService>().text("allItemList.title").toUpperCase()),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          Visibility(visible: kDebugMode, child: IconButton(onPressed: () => Storage.printAllSavedData(), icon: const Icon(Icons.print))),
        ],
      ),
      body: Column(
        children: [
          Visibility(
            visible: _allItemsList.isNotEmpty,
            child: Container(
              color: AppColors.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: SizedBox(
                height: 20,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: _progress),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) => LinearProgressIndicator(value: value, minHeight: 20),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: -2.5,
                      child: Text(
                        '${(_progress * 100).toInt()}%',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onColor(AppColors.of(context).progressBar)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _allItemsList.length + 1,
              itemBuilder: (context, index) {
                if (index < _allItemsList.length) {
                  return ItemCard(
                    isAllItemCard: true,
                    item: _allItemsList[index],
                    list: _allItemsList,
                    update: _sortAndUpdateProgressBar,
                  );
                }
                return const ScrollCard();
              },
            ),
          ),
        ],
      ),
    );
  }
}
