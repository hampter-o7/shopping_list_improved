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
  bool _alphaOrder = false;
  // TODO implement other language recognition
  bool _speechEnabled = false;
  bool _isListening = false;
  double _progress = 0;
  String _storeName = 'Store';
  final _textController = TextEditingController();
  final SpeechToText _speechController = SpeechToText();
  late Store _store;
  List<Item> _itemList = [];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speechController.initialize();
    setState(() {});
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    Map args = ModalRoute.of(context)!.settings.arguments as Map;
    _store = args['store'];
    _storeName = _store.name;
    List<int> idItemList = _store.storeItemList;
    _itemList = await Storage.loadAllStoreItems(idItemList);
    _alphaOrder = await Storage.loadAlphaOrder(2);
    _updateProgressBar();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _updateProgressBar() {
    if (_itemList.isEmpty) {
      _progress = 0;
    } else {
      int numberOfIsChecked = 0;
      for (Item item in _itemList) {
        if (item.isChecked) numberOfIsChecked++;
      }
      _progress = numberOfIsChecked / _itemList.length;
    }
    setState(() {});
  }

  Future<void> _addItemToList(String itemName, bool isOneTimeItem) async {
    String alreadyExists = context.read<LanguageService>().text("itemList.alreadyExists", {"storeName": _store.name});
    Item? item = await Storage.checkIfItemExists(itemName);
    if (item != null) {
      if (_store.storeItemList.contains(item.id)) {
        _showSnackbar(alreadyExists);
        _textController.clear();
        return;
      }
      item.storeList.add(_store.id);
      _itemList.add(item);
      _store.storeItemList.add(item.id);
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
      newItem.storeList.add(_store.id);
      _itemList.add(newItem);
      Storage.saveItem(newItem);
      _store.storeItemList.add(newItem.id);
    }
    Storage.saveStore(_store);
    _textController.clear();
    _updateProgressBar();
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 5)));
  }

  Future<void> _removeAllCheckmarksDialog() async {
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
                for (Item item in _itemList) {
                  item.isChecked = false;
                  Storage.saveItem(item);
                }
                _updateProgressBar();
              },
              child: Text(context.read<LanguageService>().text("actions.yes")),
            ),
          ],
        );
      },
    );
  }

  Future<dynamic> _showNewItemDialog(BuildContext context) {
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
                      _addItemToList(_textController.text, isOneTimeItem);
                      Navigator.pop(context);
                    },
                    autofocus: true,
                    controller: _textController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: context.read<LanguageService>().text("itemList.addNewHint"),
                      suffixIcon: IconButton(
                        icon: Icon(_isListening ? Icons.mic : Icons.mic_off, color: AppColors.of(context).resolvedItemText),
                        onPressed: () async {
                          if (_isListening) {
                            await _speechController.stop();
                            _isListening = false;
                          } else {
                            if (!_speechEnabled) return;
                            await _speechController.listen(
                              onResult: (result) {
                                _textController.text = result.recognizedWords;
                                _textController.selection = TextSelection.fromPosition(
                                  TextPosition(offset: _textController.text.length),
                                );
                                _isListening = false;
                                setModalState(() {});
                              },
                            );
                            _isListening = true;
                          }
                          debugPrint("$_isListening");
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
                    _textController.text = "";
                    Navigator.pop(context);
                  },
                  child: Text(context.read<LanguageService>().text("actions.cancel")),
                ),
                FilledButton(
                  onPressed: () {
                    _addItemToList(_textController.text, isOneTimeItem);
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
    if (_alphaOrder) {
      _itemList.sort(
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
    }
    return Scaffold(
      appBar: AppBar(
        title: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _store.imageLocation.isNotEmpty
                    ? SizedBox(
                        width: 50,
                        height: 50,
                        child: Container(
                          margin: const EdgeInsets.all(3),
                          child: Image.file(File(_store.imageLocation), fit: BoxFit.contain),
                        ),
                      )
                    : Container(),
                Text(_storeName),
              ],
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          Visibility(visible: kDebugMode, child: IconButton(onPressed: () => Storage.printAllSavedData(), icon: const Icon(Icons.print))),
          Semantics(
            container: true,
            label: 'Alphabetical switch',
            checked: _alphaOrder,
            value: 'Feature is ${_alphaOrder ? 'enabled' : 'disabled'}',
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
                _alphaOrder = value;
                setState(() {});
              },
              value: _alphaOrder,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Visibility(
            visible: _itemList.isNotEmpty,
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
                        '${(_progress * 100).toInt()}%',
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
          _alphaOrder
              ? Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: _itemList.length + 1,
                    itemBuilder: (context, index) {
                      if (index < _itemList.length) {
                        return ItemCard(
                          isAllItemCard: false,
                          item: _itemList[index],
                          list: _itemList,
                          update: _updateProgressBar,
                          store: _store,
                        );
                      }
                      return const ScrollCard();
                    },
                  ),
                )
              : Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ReorderableCardList(list: _itemList, store: _store, updateProgressBar: _updateProgressBar),
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
            onTap: () => _showNewItemDialog(context),
          ),
          speedDialChildCustom(context: context, icon: Icons.deselect, labelKey: "itemList.uncheckAll", onTap: () => _removeAllCheckmarksDialog()),
        ],
      ),
    );
  }
}
