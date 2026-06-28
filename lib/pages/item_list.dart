import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shopping_list/classes/colors.dart';
import 'package:shopping_list/my_widgets/scroll_card.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../classes/item.dart';
import '../classes/store.dart';
import '../my_widgets/item_card.dart';
import '../my_widgets/reorderable_card_list.dart';
import '../storage/local_storage.dart';

class ItemList extends StatefulWidget {
  const ItemList({super.key});

  @override
  State<ItemList> createState() => _ItemListState();
}

class _ItemListState extends State<ItemList> {
  List<Item> itemList = [];
  String storeName = 'Store';
  final textController = TextEditingController();
  final SpeechToText speech = SpeechToText();
  late Store store;
  double progress = 0;
  bool alphaOrder = false;
  late StreamSubscription<bool> keyboardSubscription;
  bool speechEnabled = false;
  bool isListening = false;

  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  Future<void> initSpeech() async {
    speechEnabled = await speech.initialize();
    setState(() {});
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    Map args = ModalRoute.of(context)!.settings.arguments as Map;
    store = args['store'];
    storeName = store.name;
    List<int> idItemList = store.storeItemList;
    itemList = await Storage.loadAllStoreItems(idItemList);
    alphaOrder = await Storage.loadAlphaOrder(2);
    updateProgressBar();
  }

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void removeAllCheckmarks(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        persist: false,
        action: SnackBarAction(
          label: 'Yes',
          onPressed: () {
            for (Item item in itemList) {
              debugPrint("SnackBar shown at ${DateTime.now()}");
              item.isChecked = false;
              Storage.saveItem(item);
            }
            updateProgressBar();
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> addItemToList(String itemName, bool isOneTimeItem) async {
    Item? item = await Storage.checkIfItemExists(itemName);
    if (item != null) {
      if (store.storeItemList.contains(item.id)) {
        showSnackbar('This item is already on your ${store.name} shopping list.');
        textController.clear();
        return;
      }
      item.storeList.add(store.id);
      itemList.add(item);
      store.storeItemList.add(item.id);
      Storage.saveItem(item);
    } else {
      int newId = await Storage.generateIdNumber(false);
      Item newItem = Item(
        name: itemName,
        id: newId,
        isChecked: false,
        storeList: [],
        isOneTimeItem: isOneTimeItem,
      );
      newItem.storeList.add(store.id);
      itemList.add(newItem);
      Storage.saveItem(newItem);
      store.storeItemList.add(newItem.id);
    }
    Storage.saveStore(store);
    textController.clear();
    updateProgressBar();
  }

  Future<dynamic> showNewItemSheet(BuildContext context) {
    bool isOneTimeItem = false;
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(15.0),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Wrap(
                children: [
                  TextField(
                    onSubmitted: (value) {
                      addItemToList(textController.text, isOneTimeItem);
                      Navigator.pop(context);
                    },
                    autofocus: true,
                    controller: textController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'Name of new item',
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(15.0),
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isListening ? Icons.mic : Icons.mic_off,
                          color: AppColors.of(context).resolvedItemText,
                        ),
                        onPressed: () async {
                          if (isListening) {
                            await speech.stop();
                            isListening = false;
                          } else {
                            if (!speechEnabled) return;
                            await speech.listen(
                              onResult: (result) {
                                textController.text = result.recognizedWords;
                                textController.selection = TextSelection.fromPosition(
                                  TextPosition(offset: textController.text.length),
                                );
                                isListening = false;
                                setModalState(() {});
                              },
                            );
                            isListening = true;
                          }
                          debugPrint("$isListening");
                          setModalState(() {});
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("One time item"),
                      Checkbox(
                        value: isOneTimeItem,
                        onChanged: (changed) {
                          isOneTimeItem = changed ?? false;
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        addItemToList(textController.text, isOneTimeItem);
                        Navigator.pop(context);
                      },
                      child: const Text('ADD'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void updateProgressBar() {
    if (itemList.isEmpty) {
      progress = 0;
    } else {
      int numberOfIsChecked = 0;
      for (Item item in itemList) {
        if (item.isChecked) numberOfIsChecked++;
      }
      progress = numberOfIsChecked / itemList.length;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                store.imageLocation.isNotEmpty
                    ? SizedBox(
                        width: 50,
                        height: 50,
                        child: Container(margin: const EdgeInsets.all(3), child: Image.file(File(store.imageLocation), fit: BoxFit.cover)))
                    : Container(),
                Text(storeName, style: TextStyle(color: AppColors.of(context).resolvedTitleText)),
              ],
            ),
          ],
        ),
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
          Semantics(
            container: true,
            label: 'Alphabetical switch',
            checked: alphaOrder,
            value: 'Feature is ${alphaOrder ? 'enabled' : 'disabled'}',
            increasedValue: 'Tap to disable feature',
            decreasedValue: 'Tap to enable feature',
            child: Switch(
              activeThumbColor: AppColors.of(context).resolvedItemText,
              activeTrackColor: AppColors.of(context).resolvedItemBackground,
              inactiveThumbColor: AppColors.of(context).resolvedItemText,
              inactiveTrackColor: AppColors.of(context).resolvedItemBackground,
              trackOutlineColor: WidgetStateProperty.all(AppColors.of(context).resolvedTitleText),
              onChanged: (bool value) async {
                await Storage.saveAlphaOrder(value, 2);
                alphaOrder = value;
                setState(() {});
              },
              value: alphaOrder,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Visibility(
            visible: itemList.isNotEmpty,
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
                          color: AppColors.onColor(AppColors.of(context).progressBar),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          alphaOrder
              ? Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: itemList.length + 1,
                    itemBuilder: (context, index) {
                      if (index < itemList.length) {
                        itemList.sort(
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
                        return ItemCard(
                          list: itemList,
                          store: store,
                          index: index,
                          updateProgressBar: updateProgressBar,
                        );
                      } else {
                        return const ScrollCard();
                      }
                    },
                  ),
                )
              : Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ReorderableCardList(
                      list: itemList,
                      store: store,
                      updateProgressBarOrRemoveStore: updateProgressBar,
                    ),
                  ),
                ),
        ],
      ),
      floatingActionButton: SpeedDial(
        overlayOpacity: 0,
        icon: Icons.menu,
        activeIcon: Icons.close,
        backgroundColor: AppColors.of(context).resolvedFabFill,
        foregroundColor: AppColors.of(context).resolvedFabIcon,
        children: [
          SpeedDialChild(
            child: Icon(Icons.add, color: AppColors.of(context).resolvedFabIcon),
            label: 'Add new item',
            labelBackgroundColor: AppColors.of(context).resolvedFabFill,
            labelStyle: TextStyle(color: AppColors.of(context).resolvedFabIcon),
            backgroundColor: AppColors.of(context).resolvedFabFill,
            onTap: () {
              showNewItemSheet(context);
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.deselect, color: AppColors.of(context).resolvedFabIcon),
            label: 'Uncheck all',
            labelBackgroundColor: AppColors.of(context).resolvedFabFill,
            labelStyle: TextStyle(color: AppColors.of(context).resolvedFabIcon),
            backgroundColor: AppColors.of(context).resolvedFabFill,
            onTap: () {
              removeAllCheckmarks("Are you sure you want to remove all checkmarks?");
            },
          ),
        ],
      ),
    );
  }
}
