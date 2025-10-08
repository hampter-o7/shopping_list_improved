import 'package:flutter/material.dart';
import 'package:shopping_list/classes/app_colors.dart';

import '../classes/item.dart';
import '../storage/local_storage.dart';

class AllItemCard extends StatefulWidget {
  final Item item;
  final Function removeItem;
  final Function update;
  const AllItemCard({
    super.key,
    required this.item,
    required this.removeItem,
    required this.update,
  });

  @override
  State<AllItemCard> createState() => _ItemCard();
}

class _ItemCard extends State<AllItemCard> {
  final textController = TextEditingController();
  bool canChangeName = false;

  void handleChangeName(String newName) async {
    // Item? item = await Storage.checkIfItemExists(newName);
    // if (item != null) {
    //   if (widget.list.any((element) => element.id == item.id)) {
    //     canChangeName = false;
    //     setState(() {});
    //     showSnackbar('This item already exists on your ${widget.store.name} shopping list');
    //     return;
    //   }

    //   if (widget.list[widget.index].storeList.length < 2) {
    //     Storage.deleteItem(widget.list[widget.index].id, widget.store.id);
    //   } else {
    //     widget.list[widget.index].storeList.remove(widget.store.id);
    //     widget.store.storeItemList.removeAt(widget.index);
    //     Storage.saveItem(widget.list[widget.index]);
    //   }
    //   widget.list.removeAt(widget.index);
    //   widget.list.insert(widget.index, item);
    //   item.storeList.add(widget.store.id);
    //   widget.store.storeItemList.insert(widget.index, item.id);
    //   await Storage.saveStore(widget.store);
    // }
    // widget.list[widget.index].name = newName;
    // await Storage.saveItem(widget.list[widget.index]);
    // canChangeName = false;
    // widget.updateProgressBar();
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
        textController.text = widget.item.name;
        canChangeName = true;
        break;
      case '2':
        Storage.deleteItemFromAllStores(widget.item.id);
        widget.removeItem(widget.item);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.of(context).itemBackgroundCheckFill,
      child: Row(
        children: [
          Transform.scale(
            scale: 1.5,
            child: Checkbox(
              semanticLabel: 'Checkbox for ${widget.item.name}',
              value: widget.item.isChecked,
              onChanged: (value) {
                widget.item.isChecked = value!;
                Storage.saveItem(widget.item);
                widget.update();
              },
              fillColor: MaterialStateColor.resolveWith((states) => AppColors.of(context).itemBackgroundCheckFill),
              checkColor: AppColors.of(context).itemTextNormalBorderCheck,
              side: BorderSide(
                width: 2.0,
                style: BorderStyle.solid,
                color: AppColors.of(context).itemTextNormalBorderCheck,
              ),
            ),
          ),
          Expanded(
            child: canChangeName
                ? TextField(
                    controller: textController,
                    onSubmitted: (newName) async {
                      handleChangeName(newName);
                    },
                    onTapOutside: (oldName) {
                      canChangeName = false;
                      setState(() {});
                    },
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: widget.item.name,
                    ),
                  )
                : Text(
                    widget.item.name,
                    style: !widget.item.isChecked
                        ? TextStyle(
                            color: AppColors.of(context).itemTextNormalBorderCheck,
                            fontWeight: FontWeight.bold,
                          )
                        : TextStyle(
                            color: AppColors.of(context).itemTextCrossed,
                            fontStyle: FontStyle.italic,
                            decoration: TextDecoration.lineThrough,
                            decorationThickness: 2.5,
                            decorationColor: AppColors.of(context).itemTextCrossedLine,
                          ),
                  ),
          ),
          PopupMenuButton<String>(
            iconColor: AppColors.of(context).itemTextNormalBorderCheck,
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: '1',
                  child: Text('Change name'),
                ),
                const PopupMenuItem<String>(
                  value: '2',
                  child: Text('Delete'),
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
