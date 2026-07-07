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
  bool canChangeName = false;
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: ListTile(
              onTap: () => Navigator.pushNamed(context, '/ItemList', arguments: {'store': widget.store}),
              title: canChangeName
                  ? TextField(
                      controller: textController,
                      onSubmitted: (newName) {
                        widget.store.name = newName;
                        Storage.saveStore(widget.store);
                        canChangeName = false;
                        setState(() {});
                      },
                      onTapOutside: (oldName) {
                        canChangeName = false;
                        setState(() {});
                      },
                      autofocus: true,
                      decoration: InputDecoration(hintText: widget.store.name),
                    )
                  : Text(widget.store.name),
              leading: widget.store.imageLocation.isNotEmpty
                  ? Container(
                      margin: const EdgeInsets.all(3),
                      child: File(widget.store.imageLocation).existsSync()
                          ? Image.file(File(widget.store.imageLocation), fit: BoxFit.contain)
                          : Icon(Icons.shopping_cart_rounded),
                    )
                  : Icon(Icons.shopping_cart_rounded),
            ),
          ),
          PopupMenuButton<String>(
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry<String>>[
                PopupMenuItem<String>(value: '1', child: Text(context.read<LanguageService>().text("actions.changeName"))),
                PopupMenuItem<String>(value: '2', child: Text(context.read<LanguageService>().text("actions.changeImage"))),
                PopupMenuItem<String>(value: '3', child: Text(context.read<LanguageService>().text("actions.delete"))),
              ];
            },
            onSelected: (String value) async {
              switch (value) {
                case '1':
                  textController.text = widget.store.name;
                  canChangeName = true;
                  break;
                case '2':
                  await Storage.saveStoreImage(widget.store);
                  break;
                case '3':
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
