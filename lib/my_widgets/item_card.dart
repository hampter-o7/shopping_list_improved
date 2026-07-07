import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_list/classes/colors.dart';
import 'package:shopping_list/classes/item.dart';
import 'package:shopping_list/classes/store.dart';
import 'package:shopping_list/my_widgets/language_service.dart';
import 'package:shopping_list/storage/local_storage.dart';

class ItemCard extends StatefulWidget {
  final bool _isAllItemCard;
  final Item _item;
  final List<Item> _list;
  final Function _update;
  final Store? _store;

  const ItemCard({
    super.key,
    required bool isAllItemCard,
    required Item item,
    required List<Item> list,
    required Function update,
    Store? store,
  })  : _isAllItemCard = isAllItemCard,
        _item = item,
        _list = list,
        _update = update,
        _store = store;

  @override
  State<ItemCard> createState() => _ItemCard();
}

class _ItemCard extends State<ItemCard> {
  bool _canChangeName = false;
  final _textController = TextEditingController();

  void _handleChangeName(String newName, String oldName) async {
    if (newName == oldName) {
      _canChangeName = false;
      setState(() {});
      return;
    }

    String alreadyExists = widget._isAllItemCard
        ? context.read<LanguageService>().text("allItemList.alreadyExists")
        : context.read<LanguageService>().text("itemList.alreadyExists", {"storeName": widget._store!.name});
    Item? item = await Storage.checkIfItemExists(newName);
    if (item != null) {
      if (widget._list.any((element) => element.id == item.id)) {
        _canChangeName = false;
        setState(() {});
        _showSnackbar(alreadyExists);
        return;
      }
      if (!widget._isAllItemCard) {
        if (widget._item.storeList.length < 2) {
          Storage.deleteItem(widget._item.id, widget._store!.id);
        } else {
          widget._item.storeList.remove(widget._store!.id);
          widget._store!.storeItemList.removeAt(widget._list.indexOf(widget._item));
          widget._store!.storeItemList.removeAt(widget._list.indexOf(widget._item));
          Storage.saveItem(widget._item);
        }
        widget._list.removeAt(widget._list.indexOf(widget._item));
        widget._list.insert(widget._list.indexOf(widget._item), item);
        item.storeList.add(widget._store!.id);
        widget._store!.storeItemList.insert(widget._list.indexOf(widget._item), item.id);
        await Storage.saveStore(widget._store!);
      }
    }
    widget._item.name = newName;
    await Storage.saveItem(widget._item);
    _canChangeName = false;
    widget._update();
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
              semanticLabel: 'Checkbox for ${widget._item.name}',
              value: widget._item.isChecked,
              onChanged: (value) {
                if (widget._item.isOneTimeItem) {
                  Storage.deleteItemFromAllStores(widget._item.id);
                  if (widget._isAllItemCard) {
                    widget._list.remove(widget._item);
                  } else {
                    widget._store!.storeItemList.removeWhere((element) => element == widget._item.id);
                    widget._list.removeAt(widget._list.indexOf(widget._item));
                  }
                  widget._update();
                  return;
                }
                widget._item.isChecked = value!;
                Storage.saveItem(widget._item);
                widget._update();
              },
            ),
          ),
          Expanded(
            child: _canChangeName
                ? TextField(
                    controller: _textController,
                    onSubmitted: (newName) async => _handleChangeName(newName, widget._item.name),
                    onTapOutside: (oldName) {
                      _canChangeName = false;
                      setState(() {});
                    },
                    autofocus: true,
                    decoration: InputDecoration(hintText: widget._item.name),
                  )
                : Text(
                    widget._item.name,
                    style: !widget._item.isChecked
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
                  _textController.text = widget._item.name;
                  _canChangeName = true;
                  setState(() {});
                  break;
                case 'deleteItem':
                  if (widget._isAllItemCard) {
                    Storage.deleteItemFromAllStores(widget._item.id);
                    widget._list.remove(widget._item);
                  } else {
                    Storage.deleteItem(widget._item.id, widget._store!.id);
                    widget._store!.storeItemList.removeWhere((element) => element == widget._item.id);
                    widget._list.removeAt(widget._list.indexOf(widget._item));
                  }
                  widget._update();
                  break;
              }
            },
          ),
        ],
      ),
    );
  }
}
