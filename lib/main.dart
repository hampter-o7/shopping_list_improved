import 'package:flutter/material.dart';
import 'package:shopping_list/pages/all_items_list.dart';
import 'pages/item_list.dart';
import 'pages/settings.dart';
import 'pages/store_list.dart';

void main() {
  runApp(
    MaterialApp(
      // showSemanticsDebugger: true,
      title: 'Shopping list',
      themeMode: ThemeMode.system,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      initialRoute: '/',
      routes: {
        '/': (context) => const StoreList(),
        '/ItemList': (context) => const ItemList(),
        '/Settings': (context) => const Settings(),
        '/AllItemsList': (context) => const AllItemsList(),
      },
    ),
  );
}
