import 'package:flutter/material.dart';
import 'package:shopping_list/classes/colors.dart';

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

  void handleChangeName(String newName, String oldName) async {
    if (newName == oldName) {
      canChangeName = false;
      setState(() {});
      return;
    }
    Item? item = await Storage.checkIfItemExists(newName);
    if (item != null) {
      canChangeName = false;
      setState(() {});
      showSnackbar('This item already exists on your shopping list');
      return;
    }
    widget.item.name = newName;
    await Storage.saveItem(widget.item);
    canChangeName = false;
    setState(() {});
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
        setState(() {});
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
      color: AppColors.of(context).resolvedItemBackground,
      child: Row(
        children: [
          Transform.scale(
            scale: 1.5,
            child: Checkbox(
              semanticLabel: 'Checkbox for ${widget.item.name}',
              value: widget.item.isChecked,
              onChanged: (value) {
                if (widget.item.isOneTimeItem) {
                  Storage.deleteItemFromAllStores(widget.item.id);
                  widget.removeItem(widget.item);
                  widget.update();
                  return;
                }
                widget.item.isChecked = value!;
                Storage.saveItem(widget.item);
                widget.update();
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
                      handleChangeName(newName, widget.item.name);
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
                  child: Text('Change name', style: TextStyle(color: AppColors.of(context).resolvedItemText)),
                ),
                PopupMenuItem<String>(
                  value: '2',
                  child: Text('Delete', style: TextStyle(color: AppColors.of(context).resolvedItemText)),
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
