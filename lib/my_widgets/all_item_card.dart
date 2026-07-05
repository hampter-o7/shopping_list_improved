import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_list/classes/colors.dart';
import 'package:shopping_list/my_widgets/language_service.dart';

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
    String alreadyExists = context.read<LanguageService>().text("allItemList.alreadyExists");
    Item? item = await Storage.checkIfItemExists(newName);
    if (item != null) {
      canChangeName = false;
      setState(() {});
      showSnackbar(alreadyExists);
      return;
    }
    widget.item.name = newName;
    await Storage.saveItem(widget.item);
    canChangeName = false;
    setState(() {});
  }

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 5)));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry<String>>[
                PopupMenuItem<String>(value: '1', child: Text(context.read<LanguageService>().text("actions.changeName"))),
                PopupMenuItem<String>(value: '2', child: Text(context.read<LanguageService>().text("actions.delete"))),
              ];
            },
            onSelected: (String value) async {
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
            },
          ),
        ],
      ),
    );
  }
}
