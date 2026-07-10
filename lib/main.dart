import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_list/my_widgets/language_service.dart';
import 'package:shopping_list/my_widgets/theme_manager.dart';
import 'package:shopping_list/pages/all_items_list.dart';
import 'package:shopping_list/pages/color_picker.dart';
import 'package:shopping_list/pages/item_list.dart';
import 'package:shopping_list/pages/settings.dart';
import 'package:shopping_list/pages/store_list.dart';
import 'package:shopping_list/storage/local_storage.dart';

final language = LanguageService();
// TODO update semantic labels
// TODO make showcase of features
// TODO add fab to all item list
// TODO add near location notification
// TODO update color picker for better user experience
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeManager = ThemeManager();
  final languageService = LanguageService();

  await languageService.load(await Storage.loadLanguage());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeManager),
        ChangeNotifierProvider.value(value: languageService),
      ],
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
