import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_list/my_widgets/theme_manager.dart';
import 'package:shopping_list/pages/all_items_list.dart';
import 'package:shopping_list/pages/color_picker.dart';
import 'pages/item_list.dart';
import 'pages/settings.dart';
import 'pages/store_list.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeManager = ThemeManager();

  runApp(
    ChangeNotifierProvider.value(
      value: themeManager,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = context.watch<ThemeManager>();

    return MaterialApp(
      title: 'Shopping list',
      theme: themeManager.lightTheme,
      darkTheme: themeManager.darkTheme,
      themeMode: themeManager.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const StoreList(),
        '/ItemList': (context) => const ItemList(),
        '/Settings': (context) => const Settings(),
        '/AllItemsList': (context) => const AllItemsList(),
        '/ColorPicker': (context) => const ColorPicker(),
      },
    );
  }
}
