import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_list/classes/colors.dart';
import 'package:shopping_list/my_widgets/language_service.dart';

import '../classes/item.dart';
import '../classes/store.dart';
import '../storage/local_storage.dart';

class ItemCard extends StatefulWidget {
  final List<Item> list;
  final Store store;
  final int index;
  final Function updateProgressBar;

  const ItemCard({
    super.key,
    required this.list,
    required this.store,
    required this.index,
    required this.updateProgressBar,
  });

  @override
  State<ItemCard> createState() => _ItemCard();
}

class _ItemCard extends State<ItemCard> {
  final textController = TextEditingController();
  bool canChangeName = false;

  void handleChangeName(String newName, String oldName) async {
    if (newName == oldName) {
      canChangeName = false;
      setState(() {});
      return;
    }
    String alreadyExists = context.read<LanguageService>().text("itemList.alreadyExists", {"storeName": widget.store.name});
    Item? item = await Storage.checkIfItemExists(newName);
    if (item != null) {
      if (widget.list.any((element) => element.id == item.id)) {
        canChangeName = false;
        setState(() {});
        showSnackbar(alreadyExists);
        return;
      }

      if (widget.list[widget.index].storeList.length < 2) {
        Storage.deleteItem(widget.list[widget.index].id, widget.store.id);
      } else {
        widget.list[widget.index].storeList.remove(widget.store.id);
        widget.store.storeItemList.removeAt(widget.index);
        Storage.saveItem(widget.list[widget.index]);
      }
      widget.list.removeAt(widget.index);
      widget.list.insert(widget.index, item);
      item.storeList.add(widget.store.id);
      widget.store.storeItemList.insert(widget.index, item.id);
      await Storage.saveStore(widget.store);
    }
    widget.list[widget.index].name = newName;
    await Storage.saveItem(widget.list[widget.index]);
    canChangeName = false;
    widget.updateProgressBar();
  }

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void handleMenuButtonPress(String value) {
    switch (value) {
      case '1':
        textController.text = widget.list[widget.index].name;
        canChangeName = true;
        setState(() {});
        break;
      case '2':
        Storage.deleteItem(widget.list[widget.index].id, widget.store.id);
        widget.store.storeItemList.removeWhere((element) => element == widget.list[widget.index].id);
        widget.list.removeAt(widget.index);
        widget.updateProgressBar();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.of(context).resolvedItemBackground,
      child: Row(
        children: [
          Transform.scale(
            scale: 1.5,
            child: Checkbox(
              semanticLabel: 'Checkbox for ${widget.list[widget.index].name}',
              value: widget.list[widget.index].isChecked,
              onChanged: (value) {
                if (widget.list[widget.index].isOneTimeItem) {
                  Storage.deleteItemFromAllStores(widget.list[widget.index].id);
                  widget.store.storeItemList.removeWhere((element) => element == widget.list[widget.index].id);
                  widget.list.removeAt(widget.index);
                  widget.updateProgressBar();
                  return;
                }
                widget.list[widget.index].isChecked = value!;
                Storage.saveItem(widget.list[widget.index]);
                widget.updateProgressBar();
              },
              fillColor: WidgetStateColor.resolveWith((states) => AppColors.of(context).resolvedItemBackground),
              checkColor: AppColors.of(context).resolvedItemCheckbox,
              side: BorderSide(
                width: 2.0,
                style: BorderStyle.solid,
                color: AppColors.of(context).resolvedItemCheckbox,
              ),
            ),
          ),
          Expanded(
            child: canChangeName
                ? TextField(
                    controller: textController,
                    onSubmitted: (newName) async {
                      handleChangeName(newName, widget.list[widget.index].name);
                    },
                    onTapOutside: (oldName) {
                      canChangeName = false;
                      setState(() {});
                    },
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: widget.list[widget.index].name,
                    ),
                  )
                : Text(
                    widget.list[widget.index].name,
                    style: !widget.list[widget.index].isChecked
                        ? TextStyle(
                            color: AppColors.of(context).resolvedItemText,
                            fontWeight: FontWeight.bold,
                          )
                        : TextStyle(
                            color: AppColors.of(context).resolvedItemCrossed,
                            fontStyle: FontStyle.italic,
                            decoration: TextDecoration.lineThrough,
                            decorationThickness: 3,
                            decorationColor: AppColors.of(context).resolvedItemCrossedLine,
                          ),
                  ),
          ),
          PopupMenuButton<String>(
            color: AppColors.of(context).resolvedItemBackground,
            iconColor: AppColors.of(context).resolvedItemText,
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: '1',
                  child: Text(context.read<LanguageService>().text("actions.changeName"),
                      style: TextStyle(color: AppColors.of(context).resolvedItemText)),
                ),
                PopupMenuItem<String>(
                  value: '2',
                  child:
                      Text(context.read<LanguageService>().text("actions.delete"), style: TextStyle(color: AppColors.of(context).resolvedItemText)),
                ),
              ];
            },
            onSelected: (String value) async {
              handleMenuButtonPress(value);
            },
          ),
        ],
      ),
    );
  }
}
