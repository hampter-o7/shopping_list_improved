import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'package:shopping_list/classes/colors.dart';
import 'package:shopping_list/classes/item.dart';
import 'package:shopping_list/classes/store.dart';
import 'package:shopping_list/my_widgets/item_card.dart';
import 'package:shopping_list/my_widgets/language_service.dart';
import 'package:shopping_list/my_widgets/reorderable_card_list.dart';
import 'package:shopping_list/my_widgets/scroll_card.dart';
import 'package:shopping_list/my_widgets/speed_dial_child_custom.dart';
import 'package:shopping_list/storage/local_storage.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ItemList extends StatefulWidget {
  const ItemList({super.key});

  @override
  State<ItemList> createState() => _ItemListState();
}

class _ItemListState extends State<ItemList> {
  bool alphaOrder = false;
  // TODO implement other language recognition
  bool speechEnabled = false;
  bool isListening = false;
  double progress = 0;
  String storeName = 'Store';
  final textController = TextEditingController();
  final SpeechToText speech = SpeechToText();
  late Store store;
  List<Item> itemList = [];

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

  Future<void> addItemToList(String itemName, bool isOneTimeItem) async {
    String alreadyExists = context.read<LanguageService>().text("itemList.alreadyExists", {"storeName": store.name});
    Item? item = await Storage.checkIfItemExists(itemName);
    if (item != null) {
      if (store.storeItemList.contains(item.id)) {
        showSnackbar(alreadyExists);
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

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 5)));
  }

  Future<void> removeAllCheckmarksDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          content: Text(context.read<LanguageService>().text("itemList.uncheckAllConfirm")),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.read<LanguageService>().text("actions.cancel")),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                for (Item item in itemList) {
                  item.isChecked = false;
                  Storage.saveItem(item);
                }
                updateProgressBar();
              },
              child: Text(context.read<LanguageService>().text("actions.yes")),
            ),
          ],
        );
      },
    );
  }

  Future<dynamic> showNewItemDialog(BuildContext context) {
    bool isOneTimeItem = false;
    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
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
                      hintText: context.read<LanguageService>().text("itemList.addNewHint"),
                      suffixIcon: IconButton(
                        icon: Icon(isListening ? Icons.mic : Icons.mic_off, color: AppColors.of(context).resolvedItemText),
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
                      Text(context.read<LanguageService>().text("itemList.oneTime")),
                      Checkbox(
                        value: isOneTimeItem,
                        onChanged: (changed) {
                          isOneTimeItem = changed ?? false;
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                FilledButton(
                  onPressed: () {
                    textController.text = "";
                    Navigator.pop(context);
                  },
                  child: Text(context.read<LanguageService>().text("actions.cancel")),
                ),
                FilledButton(
                  onPressed: () {
                    addItemToList(textController.text, isOneTimeItem);
                    Navigator.pop(context);
                  },
                  child: Text(context.read<LanguageService>().text("actions.add")),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          child: Image.file(File(store.imageLocation), fit: BoxFit.contain),
                        ),
                      )
                    : Container(),
                Text(storeName),
              ],
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          Visibility(visible: kDebugMode, child: IconButton(onPressed: () => Storage.printAllSavedData(), icon: const Icon(Icons.print))),
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
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return LinearProgressIndicator(value: value, minHeight: 20);
                        },
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: -2.5,
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
                          isAllItemCard: false,
                          item: itemList[index],
                          list: itemList,
                          update: updateProgressBar,
                          store: store,
                        );
                      }
                      return const ScrollCard();
                    },
                  ),
                )
              : Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ReorderableCardList(list: itemList, store: store, updateProgressBar: updateProgressBar),
                  ),
                ),
        ],
      ),
      floatingActionButton: SpeedDial(
        overlayOpacity: 0,
        icon: Icons.menu,
        activeIcon: Icons.close,
        children: [
          speedDialChildCustom(
            context: context,
            icon: Icons.add,
            labelKey: "itemList.addButton",
            onTap: () => showNewItemDialog(context),
          ),
          speedDialChildCustom(context: context, icon: Icons.deselect, labelKey: "itemList.uncheckAll", onTap: () => removeAllCheckmarksDialog()),
        ],
      ),
    );
  }
}
