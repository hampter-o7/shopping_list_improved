import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'package:shopping_list/classes/colors.dart';
import 'package:shopping_list/classes/store.dart';
import 'package:shopping_list/my_widgets/language_service.dart';
import 'package:shopping_list/my_widgets/reorderable_card_list.dart';
import 'package:shopping_list/my_widgets/scroll_card.dart';
import 'package:shopping_list/my_widgets/speech_service.dart';
import 'package:shopping_list/my_widgets/speed_dial_child_custom.dart';
import 'package:shopping_list/my_widgets/store_card.dart';
import 'package:shopping_list/storage/local_storage.dart';

class StoreList extends StatefulWidget {
  const StoreList({super.key});

  @override
  State<StoreList> createState() => _StoreListState();
}

class _StoreListState extends State<StoreList> {
  bool _alphaOrder = false;
  final _textController = TextEditingController();
  List<Store> _storeList = [];

  @override
  void initState() {
    super.initState();
    _loadStoresAndAlphaOrder();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadStoresAndAlphaOrder() async {
    _storeList = await Storage.loadAllStores();
    _alphaOrder = await Storage.loadAlphaOrder(1);
    setState(() {});
  }

  void _updateStoreList(List<Store> updatedList) {
    _storeList = updatedList;
    setState(() {});
  }

  Future<void> _addShopToList(String storeName) async {
    int newId = await Storage.generateIdNumber(true);
    Store newStore = Store(
      name: storeName,
      id: newId,
      order: _storeList.length,
      imageLocation: '',
      storeItemList: [],
    );
    _storeList.add(newStore);
    Storage.saveStore(newStore);
    _textController.clear();
    setState(() {});
  }

  Future<void> _removeStore(int index) async {
    await Storage.deleteStore(_storeList.elementAt(index).id);
    _storeList.removeAt(index);
    setState(() {});
  }

  Future<dynamic> _showNewStoreDialog(BuildContext context) {
    final speech = SpeechService();
    bool isListening = false;
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
                      _addShopToList(_textController.text);
                      Navigator.pop(context);
                    },
                    autofocus: true,
                    controller: _textController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: context.read<LanguageService>().text("storeList.addNewHint"),
                      suffixIcon: IconButton(
                          icon: Icon(isListening ? Icons.mic : Icons.mic_none),
                          onPressed: () async {
                            if (!speech.isListening) {
                              isListening = true;
                              setModalState(() {});
                              await speech.startListening(
                                (text) {
                                  _textController.text = text;
                                  _textController.selection = TextSelection.fromPosition(TextPosition(offset: _textController.text.length));
                                  isListening = false;
                                  setModalState(() {});
                                },
                                onError: (errorMsg) {
                                  isListening = false;
                                  setModalState(() {});
                                },
                              );
                            } else {
                              speech.stopListening();
                              isListening = false;
                            }
                            setModalState(() {});
                          }),
                    ),
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
                    _addShopToList(_textController.text);
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
      _storeList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pushNamed(context, '/Settings', arguments: {'updateStoreList': _updateStoreList}),
          icon: const Icon(Icons.settings, semanticLabel: 'Settings'),
        ),
        title: Text(context.watch<LanguageService>().text("storeList.title").toUpperCase()),
        centerTitle: true,
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
                await Storage.saveAlphaOrder(value, 1);
                _alphaOrder = value;
                setState(() {});
              },
              value: _alphaOrder,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: _alphaOrder
            ? ListView.builder(
                itemCount: _storeList.length + 1,
                itemBuilder: (context, index) {
                  if (index < _storeList.length) {
                    return StoreCard(
                      store: _storeList[index],
                      index: index,
                      removeStore: _removeStore,
                    );
                  }
                  return const ScrollCard();
                },
              )
            : ReorderableCardList(list: _storeList, removeStore: _removeStore),
      ),
      floatingActionButton: SpeedDial(
        overlayOpacity: 0,
        icon: Icons.menu,
        activeIcon: Icons.close,
        children: [
          speedDialChildCustom(
            context: context,
            icon: Icons.add,
            labelKey: "storeList.addButton",
            onTap: () => _showNewStoreDialog(context),
          ),
          speedDialChildCustom(
            context: context,
            icon: Icons.checklist_rounded,
            labelKey: "storeList.showAllItems",
            onTap: () => Navigator.pushNamed(context, '/AllItemsList'),
          ),
        ],
      ),
    );
  }
}
