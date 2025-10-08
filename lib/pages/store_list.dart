import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shopping_list/classes/app_colors.dart';

import '../classes/store.dart';
import '../my_widgets/reorderable_card_list.dart';
import '../my_widgets/scroll_card.dart';
import '../my_widgets/store_card.dart';
import '../storage/local_storage.dart';

class StoreList extends StatefulWidget {
  const StoreList({super.key});

  @override
  State<StoreList> createState() => _StoreListState();
}

class _StoreListState extends State<StoreList> {
  List<Store> storeList = [];
  final textController = TextEditingController();
  bool alphaOrder = false;
  late StreamSubscription<bool> keyboardSubscription;

  @override
  void initState() {
    super.initState();
    loadStoresAndAlphaOrder();
  }

  Future<void> loadStoresAndAlphaOrder() async {
    storeList = await Storage.loadAllStores();
    alphaOrder = await Storage.loadAlphaOrder(1);
    setState(() {});
  }

  void updateStoreList(List<Store> updatedList) {
    storeList = updatedList;
    setState(() {});
  }

  addShopToList(String storeName) async {
    int newId = await Storage.generateIdNumber(true);
    Store newStore = Store(
      name: storeName,
      id: newId,
      order: storeList.length,
      imageLocation: '',
      storeItemList: [],
    );
    storeList.add(newStore);
    Storage.saveStore(newStore);
    textController.clear();
    setState(() {});
  }

  removeStore(int index) async {
    await Storage.deleteStore(storeList.elementAt(index).id);
    storeList.removeAt(index);
    setState(() {});
  }

  Future<dynamic> showNewStoreSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(15.0),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Wrap(
            children: [
              TextField(
                onSubmitted: (value) {
                  addShopToList(textController.text);
                  Navigator.pop(context);
                },
                autofocus: true,
                controller: textController,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: 'Name of new store',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(15.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Center(
                child: TextButton(
                  onPressed: () {
                    addShopToList(textController.text);
                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/Settings',
              arguments: {
                'updateStoreList': updateStoreList,
              },
            );
          },
          icon: Icon(Icons.settings, color: AppColors.invertColor(AppColors.of(context).titleBackground), semanticLabel: 'Settings'),
        ),
        title: Text('Store list', style: TextStyle(color: AppColors.invertColor(AppColors.of(context).titleBackground))),
        centerTitle: true,
        backgroundColor: AppColors.of(context).titleBackground,
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
          Semantics(
            container: true,
            label: 'Alphabetical switch',
            checked: alphaOrder,
            value: 'Feature is ${alphaOrder ? 'enabled' : 'disabled'}',
            increasedValue: 'Tap to disable feature',
            decreasedValue: 'Tap to enable feature',
            child: Switch(
              onChanged: (bool value) async {
                await Storage.saveAlphaOrder(value, 1);
                alphaOrder = value;
                setState(() {});
              },
              value: alphaOrder,
            ),
          ),
        ],
      ),
      body: alphaOrder
          ? ListView.builder(
              itemCount: storeList.length + 1,
              itemBuilder: (context, index) {
                if (index < storeList.length) {
                  storeList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                  return StoreCard(
                    store: storeList[index],
                    index: index,
                    removeStore: removeStore,
                  );
                } else {
                  return const ScrollCard();
                }
              },
            )
          : ReorderableCardList(
              list: storeList,
              store: Store.empty(),
              updateProgressBarOrRemoveStore: removeStore,
            ),
      floatingActionButton: SpeedDial(
        overlayOpacity: 0,
        icon: Icons.menu,
        activeIcon: Icons.close,
        backgroundColor: AppColors.of(context).fabFill,
        foregroundColor: AppColors.of(context).fabIcon,
        children: [
          SpeedDialChild(
            child: Icon(Icons.add, color: AppColors.of(context).fabIcon),
            label: 'Add new store',
            backgroundColor: AppColors.of(context).fabFill,
            onTap: () {
              showNewStoreSheet(context);
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.checklist_rounded, color: AppColors.of(context).fabIcon),
            label: 'Show all items',
            backgroundColor: AppColors.of(context).fabFill,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/AllItemsList',
              );
            },
          ),
        ],
      ),
    );
  }
}
