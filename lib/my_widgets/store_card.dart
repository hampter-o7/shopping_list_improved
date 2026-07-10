import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_list/classes/store.dart';
import 'package:shopping_list/my_widgets/language_service.dart';
import 'package:shopping_list/storage/local_storage.dart';

class StoreCard extends StatefulWidget {
  final Store store;
  final int index;
  final Function removeStore;

  const StoreCard({
    super.key,
    required this.store,
    required this.index,
    required this.removeStore,
  });

  @override
  State<StoreCard> createState() => _StoreCard();
}

class _StoreCard extends State<StoreCard> {
  bool _canChangeName = false;
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: ListTile(
              contentPadding: const EdgeInsets.only(left: 10, right: 16),
              onTap: () => Navigator.pushNamed(context, '/ItemList', arguments: {'store': widget.store}),
              title: _canChangeName
                  ? TextField(
                      controller: _textController,
                      onSubmitted: (newName) {
                        widget.store.name = newName;
                        Storage.saveStore(widget.store);
                        _canChangeName = false;
                        setState(() {});
                      },
                      onTapOutside: (oldName) {
                        _canChangeName = false;
                        setState(() {});
                      },
                      autofocus: true,
                      decoration: InputDecoration(hintText: widget.store.name),
                    )
                  : Text(widget.store.name),
              leading: SizedBox(
                width: 40,
                height: 40,
                child: widget.store.imageLocation.isNotEmpty
                    ? File(widget.store.imageLocation).existsSync()
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(widget.store.imageLocation), fit: BoxFit.contain),
                          )
                        : const Icon(Icons.shopping_cart_rounded)
                    : const Icon(Icons.shopping_cart_rounded),
              ),
            ),
          ),
          PopupMenuButton<String>(
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry<String>>[
                PopupMenuItem<String>(value: 'changeName', child: Text(context.read<LanguageService>().text("actions.changeName"))),
                PopupMenuItem<String>(value: 'changeImage', child: Text(context.read<LanguageService>().text("actions.changeImage"))),
                PopupMenuItem<String>(value: 'deleteStore', child: Text(context.read<LanguageService>().text("actions.delete"))),
              ];
            },
            onSelected: (String value) async {
              switch (value) {
                case 'changeName':
                  _textController.text = widget.store.name;
                  _canChangeName = true;
                  break;
                case 'changeImage':
                  await Storage.saveStoreImage(widget.store);
                  break;
                case 'deleteStore':
                  widget.removeStore(widget.index);
                  break;
              }
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
