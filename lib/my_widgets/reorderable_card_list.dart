import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shopping_list/classes/item.dart';
import 'package:shopping_list/classes/store.dart';
import 'package:shopping_list/my_widgets/item_card.dart';
import 'package:shopping_list/my_widgets/scroll_card.dart';
import 'package:shopping_list/my_widgets/store_card.dart';
import 'package:shopping_list/storage/local_storage.dart';

class ReorderableCardList<T> extends StatefulWidget {
  final List<T> list;
  final Store? store;
  final Function()? updateProgressBar;
  final Function? removeStore;

  const ReorderableCardList({
    super.key,
    required this.list,
    this.store,
    this.updateProgressBar,
    this.removeStore,
  });

  @override
  State<ReorderableCardList> createState() => _ReorderableCardListState();
}

class _ReorderableCardListState<T> extends State<ReorderableCardList> {
  @override
  Widget build(BuildContext context) {
    if (widget.list.isEmpty || widget.store == null) {
      widget.list.sort((a, b) => a.order.compareTo(b.order));
    } else {
      widget.list.sort((a, b) {
        final indexA = widget.store!.storeItemList.indexOf(a.id);
        final indexB = widget.store!.storeItemList.indexOf(b.id);
        return indexA.compareTo(indexB);
      });
    }

    final List<Widget> cards = <Widget>[
      for (int index = 0; index < widget.list.length; index++)
        widget.list[index] is Store
            ? StoreCard(
                key: ValueKey('store-${(widget.list[index] as Store).id}'),
                store: widget.list[index],
                index: index,
                removeStore: widget.removeStore!,
              )
            : ItemCard(
                key: ValueKey('item-${(widget.list[index] as Item).id}'),
                isAllItemCard: false,
                item: widget.list[index],
                list: widget.list as List<Item>,
                update: widget.updateProgressBar!,
                store: widget.store,
              )
    ];

    final draggableCards = [for (int i = 0; i < cards.length; i++) ReorderableDelayedDragStartListener(key: cards[i].key, index: i, child: cards[i])];

    const scrollCard = KeyedSubtree(key: Key('emptyCard'), child: ScrollCard());

    final children = [...draggableCards, scrollCard];

    Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
      return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double animValue = Curves.easeInOut.transform(animation.value);
          final double scale = lerpDouble(1, 1.02, animValue)!;
          return Transform.scale(scale: scale, child: child);
        },
        child: child,
      );
    }

    return ReorderableListView(
      buildDefaultDragHandles: false,
      proxyDecorator: proxyDecorator,
      onReorderItem: (int oldIndex, int newIndex) {
        final item = widget.list.removeAt(oldIndex);
        widget.list.insert(newIndex, item);

        List<int> idList = [];
        for (int i = 0; i < widget.list.length; i++) {
          if (widget.list[i] is Store) {
            (widget.list[i] as Store).order = i;
            Storage.saveStore(widget.list[i]);
          } else if (widget.list[i] is Item) {
            idList.add(widget.list[i].id);
          }
        }
        if (widget.list.isNotEmpty && widget.store != null) {
          widget.store!.storeItemList = idList;
          Storage.saveStore(widget.store!);
        }

        setState(() {});
      },
      children: children,
    );
  }
}
