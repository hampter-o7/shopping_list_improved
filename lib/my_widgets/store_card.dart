import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shopping_list/classes/colors.dart';

import '../classes/store.dart';
import '../storage/local_storage.dart';

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
  final textController = TextEditingController();
  bool canChangeName = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.of(context).resolvedItemBackground,
      child: Row(
        children: [
          Expanded(
            child: ListTile(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/ItemList',
                  arguments: {
                    'store': widget.store,
                  },
                );
              },
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
                      decoration: InputDecoration(
                        hintText: widget.store.name,
                      ),
                    )
                  : Text(
                      widget.store.name,
                      style: TextStyle(color: AppColors.of(context).resolvedItemText),
                    ),
              leading: widget.store.imageLocation.isNotEmpty
                  ? Container(
                      margin: const EdgeInsets.all(3),
                      child: File(widget.store.imageLocation).existsSync()
                          ? Image.file(File(widget.store.imageLocation))
                          : Icon(Icons.shopping_cart_rounded, color: AppColors.of(context).resolvedItemText),
                    )
                  : Icon(Icons.shopping_cart_rounded, color: AppColors.of(context).resolvedItemText),
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
                  child: Text('Add/change image', style: TextStyle(color: AppColors.of(context).resolvedItemText)),
                ),
                PopupMenuItem<String>(
                  value: '3',
                  child: Text('Delete', style: TextStyle(color: AppColors.of(context).resolvedItemText)),
                ),
              ];
            },
            onSelected: (String value) async {
              switch (value) {
                case '1':
                  textController.text = widget.store.name;
                  canChangeName = true;
                  setState(() {});
                  break;
                case '2':
                  await Storage.saveStoreImage(widget.store);
                  setState(() {});
                  break;
                case '3':
                  widget.removeStore(widget.index);
                  break;
              }
            },
          ),
        ],
      ),
    );
  }
}
