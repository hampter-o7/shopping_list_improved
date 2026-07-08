import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_list/classes/colors.dart';
import 'package:shopping_list/classes/item.dart';
import 'package:shopping_list/classes/store.dart';
import 'package:shopping_list/my_widgets/language_service.dart';
import 'package:shopping_list/storage/local_storage.dart';

class ItemCard extends StatefulWidget {
  final bool isAllItemCard;
  final Item item;
  final List<Item> list;
  final Function() update;
  final Store? store;

  const ItemCard({
    super.key,
    required this.isAllItemCard,
    required this.item,
    required this.list,
    required this.update,
    this.store,
  });

  @override
  State<ItemCard> createState() => _ItemCard();
}

class _ItemCard extends State<ItemCard> {
  bool _canChangeName = false;
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleChangeName(String newName, String oldName) async {
    if (newName == oldName) {
      _canChangeName = false;
      setState(() {});
      return;
    }

    String alreadyExists = widget.isAllItemCard
        ? context.read<LanguageService>().text("allItemList.alreadyExists")
        : context.read<LanguageService>().text("itemList.alreadyExists", {"storeName": widget.store!.name});
    Item? item = await Storage.checkIfItemExists(newName);
    int index = widget.list.indexOf(widget.item);
    if (item != null) {
      if (widget.list.any((element) => element.id == item.id)) {
        _canChangeName = false;
        setState(() {});
        _showSnackbar(alreadyExists);
        return;
      }
      if (!widget.isAllItemCard) {
        if (widget.item.storeList.length < 2) {
          Storage.deleteItem(widget.item.id, widget.store!.id);
        } else {
          widget.item.storeList.remove(widget.store!.id);
          widget.store!.storeItemList.remove(widget.item.id);
          Storage.saveItem(widget.item);
        }
        widget.list.remove(widget.item);
        widget.store!.storeItemList.insert(index, item.id);
        item.storeList.add(widget.store!.id);
        widget.list.insert(index, item);
        await Storage.saveStore(widget.store!);
      }
    }
    widget.item.name = newName;
    await Storage.saveItem(widget.list[index]);
    _canChangeName = false;
    widget.update();
  }

  void _showSnackbar(String message) {
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
                  if (widget.isAllItemCard) {
                    widget.list.remove(widget.item);
                  } else {
                    widget.store!.storeItemList.removeWhere((element) => element == widget.item.id);
                    widget.list.remove(widget.item);
                  }
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
            child: _canChangeName
                ? TextField(
                    controller: _textController,
                    onSubmitted: (newName) async => _handleChangeName(newName, widget.item.name),
                    onTapOutside: (oldName) {
                      _canChangeName = false;
                      setState(() {});
                    },
                    autofocus: true,
                    decoration: InputDecoration(hintText: widget.item.name),
                  )
                : Text(
                    widget.item.name,
                    style: !widget.item.isChecked
                        ? TextStyle(color: AppColors.of(context).resolvedItemText, fontWeight: FontWeight.bold)
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
                PopupMenuItem<String>(value: 'changeName', child: Text(context.read<LanguageService>().text("actions.changeName"))),
                PopupMenuItem<String>(value: 'deleteItem', child: Text(context.read<LanguageService>().text("actions.delete"))),
              ];
            },
            onSelected: (String value) async {
              switch (value) {
                case 'changeName':
                  _textController.text = widget.item.name;
                  _canChangeName = true;
                  setState(() {});
                  break;
                case 'deleteItem':
                  if (widget.isAllItemCard) {
                    Storage.deleteItemFromAllStores(widget.item.id);
                    widget.list.remove(widget.item);
                  } else {
                    Storage.deleteItem(widget.item.id, widget.store!.id);
                    widget.store!.storeItemList.removeWhere((element) => element == widget.item.id);
                    widget.list.remove(widget.item);
                  }
                  widget.update();
                  break;
              }
            },
          ),
        ],
      ),
    );
  }
}
