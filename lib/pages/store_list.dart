import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'package:shopping_list/classes/colors.dart';
import 'package:shopping_list/my_widgets/language_service.dart';
import 'package:shopping_list/my_widgets/speed_dial_child_custom.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:speech_to_text/speech_to_text.dart';

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
  bool alphaOrder = false;
  bool speechEnabled = false;
  bool isListening = false;
  final textController = TextEditingController();
  final SpeechToText speech = SpeechToText();
  List<Store> storeList = [];

  final GlobalKey _fabKey = GlobalKey();
  final GlobalKey _addButtonKey = GlobalKey();
  final GlobalKey _newStoreKey = GlobalKey();
  int? _tutorialStoreId;

  final ValueNotifier<bool> _speedDialOpen = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    initSpeech();
    loadStoresAndAlphaOrder();
    startTutorial();
  }

  Future<void> initSpeech() async {
    speechEnabled = await speech.initialize();
    setState(() {});
  }

  Future<void> loadStoresAndAlphaOrder() async {
    storeList = await Storage.loadAllStores();
    alphaOrder = await Storage.loadAlphaOrder(1);
    setState(() {});
  }

  void startTutorial() {
    ShowcaseView.register();
    WidgetsBinding.instance.addPostFrameCallback((_) => ShowcaseView.get().startShowCase([_fabKey]));
  }

  void updateStoreList(List<Store> updatedList) {
    storeList = updatedList;
    setState(() {});
  }

  Future<void> addShopToList(String storeName) async {
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

    _tutorialStoreId = newId;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () => ShowcaseView.get().startShowCase([_newStoreKey]));
    });
  }

  Future<void> removeStore(int index) async {
    await Storage.deleteStore(storeList.elementAt(index).id);
    storeList.removeAt(index);
    setState(() {});
  }

  Future<dynamic> showNewStoreDialog(BuildContext context) {
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
                      addShopToList(textController.text);
                      Navigator.pop(context);
                    },
                    autofocus: true,
                    controller: textController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: context.read<LanguageService>().text("storeList.addNewHint"),
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
                    addShopToList(textController.text);
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
        leading: IconButton(
          onPressed: () => Navigator.pushNamed(context, '/Settings', arguments: {'updateStoreList': updateStoreList}),
          icon: Icon(Icons.settings, semanticLabel: 'Settings'),
        ),
        title: Text(context.watch<LanguageService>().text("storeList.title").toUpperCase()),
        centerTitle: true,
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
                await Storage.saveAlphaOrder(value, 1);
                alphaOrder = value;
                setState(() {});
              },
              value: alphaOrder,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: alphaOrder
            ? ListView.builder(
                itemCount: storeList.length + 1,
                itemBuilder: (context, index) {
                  if (index < storeList.length) {
                    storeList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                    final store = storeList[index];
                    final card = StoreCard(
                      store: store,
                      index: index,
                      removeStore: removeStore,
                    );

                    if (_tutorialStoreId != null && store.id == _tutorialStoreId) {
                      return Showcase(
                        key: _newStoreKey,
                        description: 'Tap on your new store to open it.',
                        disableBarrierInteraction: true,
                        child: card,
                      );
                    }
                    return card;
                  }
                  return const ScrollCard();
                },
              )
            : ReorderableCardList(list: storeList, store: Store.empty(), updateProgressBarOrRemoveStore: removeStore),
      ),
      floatingActionButton: Showcase(
        key: _fabKey,
        description: 'Tap here to open the menu.',
        disableBarrierInteraction: true,
        disableScaleAnimation: true,
        disableMovingAnimation: true,
        onTargetClick: () {
          _speedDialOpen.value = true; // force the dial open
          // Wait for the open animation + child widgets to mount, then
          // showcase the "+" button specifically.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 300), () {
              ShowcaseView.get().startShowCase([_addButtonKey]);
            });
          });
        },
        disposeOnTap: true,
        child: SpeedDial(
          openCloseDial: _speedDialOpen,
          overlayOpacity: 0,
          icon: Icons.menu,
          activeIcon: Icons.close,
          children: [
            speedDialChildCustom(
              context: context,
              icon: Icons.add,
              labelKey: "storeList.addButton",
              onTap: () => showNewStoreDialog(context),
              showcaseKey: _addButtonKey,
              showcaseDescription: 'Tap here to create a new store.',
              speedDialOpen: _speedDialOpen,
            ),
            speedDialChildCustom(
              context: context,
              icon: Icons.checklist_rounded,
              labelKey: "storeList.showAllItems",
              onTap: () => Navigator.pushNamed(context, '/AllItemsList'),
            ),
          ],
        ),
      ),
    );
  }
}
