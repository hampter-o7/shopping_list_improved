import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopping_list/classes/colors.dart';

import '../classes/item.dart';
import '../classes/store.dart';

class Storage {
  static const String itemKeyPrefix = 'item_';
  static const String storeKeyPrefix = 'store_';
  static const String alphaOrderKey = 'alphaOrder';
  static const String themeModeKey = 'themeMode';
  static const String costumeThemeKey = 'costumeTheme';
  static const String customThemeKey = 'customTheme';
  static const String languageKey = 'language';

  static Future<void> saveLanguage(String language) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(languageKey, language);
  }

  static Future<String> loadLanguage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? language = prefs.getString(languageKey);
    if (language == null) {
      return "english";
    }
    return language;
  }

  static Future<void> saveAlphaOrder(bool alphaOrder, int number) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('$alphaOrderKey$number', alphaOrder.toString());
  }

  static Future<bool> loadAlphaOrder(int number) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? alphaOrderString = prefs.getString('$alphaOrderKey$number');
    if (alphaOrderString == null) {
      return false;
    }
    return alphaOrderString.toLowerCase() == 'true';
  }

  static Future<void> saveThemeMode(int number) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(themeModeKey, number);
  }

  static Future<int> loadThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    int? themeMode = prefs.getInt(themeModeKey);
    if (themeMode == null) {
      return 1;
    }
    return themeMode;
  }

  static Future<void> saveCostumeTheme(ColorPalette colorPalette) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(customThemeKey, jsonEncode(colorPalette.toJson()));
  }

  static Future<ColorPalette?> loadCostumeTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? customColorPalette = prefs.getString(customThemeKey);
    if (customColorPalette != null) {
      return ColorPalette.fromJson(jsonDecode(customColorPalette) as Map<String, dynamic>);
    }
    String? costumeColorPalette = prefs.getString(costumeThemeKey);
    if (costumeColorPalette != null) {
      return ColorPalette.fromJson(jsonDecode(costumeColorPalette) as Map<String, dynamic>);
    }
    return null;
  }

  static Future<void> deleteCostumeTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(costumeThemeKey);
  }

  static Future<void> saveAllStores(List<Store> stores) async {
    for (Store store in stores) {
      saveStore(store);
    }
  }

  static Future<void> saveStore(Store store) async {
    final String key = '$storeKeyPrefix${store.id}';
    final value = {
      'name': store.name,
      'id': store.id,
      'order': store.order,
      'imageLocation': store.imageLocation,
      'storeItemList': store.storeItemList
    };
    final valueJson = json.encode(value);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, valueJson);
  }

  static Future<void> saveStoreImage(Store store) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    int lastId = 0;
    if (store.imageLocation != '') {
      int dirLength = directory.path.length;
      lastId = int.parse(store.imageLocation.substring(dirLength + 9, dirLength + 9 + 8));
      if (File(store.imageLocation).existsSync()) {
        File(store.imageLocation).deleteSync();
      }
    }
    late int newId;
    do {
      newId = generateRandomIdNumber(8);
    } while (newId == lastId);

    final String imagePath = '${directory.path}/${store.id}${newId}Image.png';
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final image = File(pickedFile.path);
      await image.copy(imagePath);
      store.imageLocation = imagePath;
      Storage.saveStore(store);
    }
  }

  static Future<void> deleteAllImages() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final imagesDirectory = Directory(directory.path);

    if (imagesDirectory.existsSync()) {
      final List<FileSystemEntity> files = imagesDirectory.listSync();

      for (final FileSystemEntity file in files) {
        if (file is File && file.path.endsWith('.png')) {
          file.deleteSync();
        }
      }
    }
  }

  static Future<List<Store>> loadAllStores() async {
    List<Store> stores = [];
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(storeKeyPrefix));
    for (String key in keys) {
      Store? loadedStore = await loadStore(key);
      if (loadedStore != null) stores.add(loadedStore);
    }
    stores.sort((a, b) => a.order.compareTo(b.order));
    return stores;
  }

  static Future<Store?> loadStore(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final valueJson = prefs.getString(key);
    if (valueJson != null) {
      final value = json.decode(valueJson);
      final store = Store(
        name: value['name'],
        id: value['id'],
        order: value['order'],
        imageLocation: value['imageLocation'],
        storeItemList: List<int>.from(value['storeItemList']),
      );
      return store;
    }
    return null;
  }

  static Future<void> saveAllItems(List<Item> items) async {
    for (Item item in items) {
      saveItem(item);
    }
  }

  static Future<void> saveItem(Item item) async {
    final key = '$itemKeyPrefix${item.id}';
    final value = {
      'name': item.name,
      'id': item.id,
      'isChecked': item.isChecked,
      'storeList': item.storeList,
      'isOneTimeItem': item.isOneTimeItem,
    };
    final valueJson = json.encode(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, valueJson);
  }

  static Future<List<Item>> loadAllItems() async {
    List<Item> items = [];
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(itemKeyPrefix));
    for (String key in keys) {
      Item? loadedStore = await loadItem(key);
      if (loadedStore != null) items.add(loadedStore);
    }
    return items;
  }

  static Future<Item?> checkIfItemExists(String name) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(itemKeyPrefix));
    for (String key in keys) {
      Item? loadedItem = await loadItem(key);
      if (loadedItem != null && loadedItem.name == name) return loadedItem;
    }
    return null;
  }

  static Future<List<Item>> loadAllStoreItems(List<int> listOfIds) async {
    List<Item> items = [];
    for (int id in listOfIds) {
      Item? loadedItem = await loadItem('$itemKeyPrefix$id');
      if (loadedItem != null) items.add(loadedItem);
    }
    return items;
  }

  static Future<Item?> loadItem(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final valueJson = prefs.getString(key);
    if (valueJson != null) {
      final value = json.decode(valueJson);
      final item = Item(
        name: value['name'],
        id: value['id'],
        isChecked: value['isChecked'],
        storeList: List<int>.from(value['storeList']),
        isOneTimeItem: value['isOneTimeItem'] ?? false,
      );
      return item;
    }
    return null;
  }

  static Future<int> generateIdNumber(bool isStore) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
          (key) => key.startsWith(storeKeyPrefix) && isStore || key.startsWith(itemKeyPrefix) && !isStore,
        );
    late int newId;
    do {
      newId = generateRandomIdNumber(8);
    } while (keys.contains('${isStore ? storeKeyPrefix : itemKeyPrefix}$newId'));
    return newId;
  }

  static int generateRandomIdNumber(int n) {
    final int min = pow(10, n - 1) as int;
    final int max = pow(10, n) - 1 as int;

    final Random random = Random();
    final int randomNumber = min + random.nextInt(max - min + 1);

    return randomNumber;
  }

  static Future<void> printAllSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
          (key) => key.startsWith(storeKeyPrefix) || key.startsWith(itemKeyPrefix),
        );
    debugPrint('STORES:');
    for (final key in keys) {
      if (key.startsWith(storeKeyPrefix)) {
        Store? store = await loadStore(key);
        if (store != null) {
          debugPrint('name: ${store.name}, id: ${store.id}, order: ${store.order}, itemList: ${store.storeItemList.toString()}');
        }
      }
    }
    debugPrint('ITEMS:');
    for (final key in keys) {
      if (key.startsWith(itemKeyPrefix)) {
        Item? item = await loadItem(key);
        if (item != null) {
          debugPrint('name: ${item.name}, id: ${item.id}, storeList: ${item.storeList.toString()}, isOneTimeItem: ${item.isOneTimeItem}');
        }
      }
    }
  }

  static Future<void> exportAllData() async {
    List<String> allJsonItems = [];
    List<String> allJsonStores = [];
    List<String> allAlphaOrder = ['false', 'false'];
    int themeMode = 1;
    String language = 'english';
    ColorPalette? customTheme;

    final prefs = await SharedPreferences.getInstance();

    try {
      bool alphaOrder1 = await loadAlphaOrder(1);
      bool alphaOrder2 = await loadAlphaOrder(2);
      allAlphaOrder = [alphaOrder1.toString(), alphaOrder2.toString()];
    } catch (e) {
      debugPrint('ERROR exporting alphaOrder: $e');
    }

    try {
      themeMode = await loadThemeMode();
    } catch (e) {
      debugPrint('ERROR exporting themeMode: $e');
    }

    try {
      language = await loadLanguage();
    } catch (e) {
      debugPrint('ERROR exporting language: $e');
    }

    try {
      customTheme = await loadCostumeTheme();
    } catch (e) {
      debugPrint('ERROR exporting customTheme: $e');
    }

    try {
      final keys = prefs.getKeys().where(
            (key) => key.startsWith(storeKeyPrefix) || key.startsWith(itemKeyPrefix),
          );
      for (String key in keys) {
        try {
          if (key.contains(itemKeyPrefix)) {
            Item? item = await loadItem(key);
            if (item != null) {
              final value = {
                'name': item.name,
                'id': item.id,
                'isChecked': item.isChecked,
                'storeList': item.storeList,
                'isOneTimeItem': item.isOneTimeItem,
              };
              allJsonItems.add(json.encode(value));
            }
          } else {
            Store? store = await loadStore(key);
            if (store != null) {
              final value = {
                'name': store.name,
                'id': store.id,
                'order': store.order,
                'imageLocation': store.imageLocation,
                'storeItemList': store.storeItemList,
              };
              allJsonStores.add(json.encode(value));
            }
          }
        } catch (e) {
          debugPrint('ERROR exporting key $key: $e');
        }
      }
    } catch (e) {
      debugPrint('ERROR reading keys for export: $e');
    }

    final allData = {
      'stores': allJsonStores,
      'items': allJsonItems,
      'alphaOrder': allAlphaOrder,
      'themeMode': themeMode,
      'language': language,
      'customTheme': customTheme,
    };

    try {
      final String? directoryPath = await FilePicker.getDirectoryPath();

      if (directoryPath != null) {
        final directory = Directory(directoryPath);

        if (await directory.exists()) {
          final file = File('${directory.path}/combined_data${generateRandomIdNumber(8)}.json');
          final encodedData = jsonEncode(allData);
          await file.writeAsString(encodedData);
        }
      }
    } catch (e) {
      debugPrint('ERROR writing export file: $e');
    }
  }

  static Future<void> importNewData() async {
    try {
      deleteAll();
    } catch (e) {
      debugPrint('ERROR clearing existing data before import: $e');
    }

    String? filePath;

    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.isNotEmpty) {
        filePath = result.files.first.path;
      }
    } catch (e) {
      debugPrint('ERROR picking import file: $e');
      return;
    }

    if (filePath == null) return;

    Map<String, dynamic> data;
    try {
      String jsonData = await File(filePath).readAsString();
      data = json.decode(jsonData);
    } catch (e) {
      debugPrint('ERROR reading/parsing import file: $e');
      return;
    }

    try {
      if (data['stores'] != null) {
        List<Store> stores = [];
        for (final storeJson in (data['stores'] as List)) {
          try {
            Map<String, dynamic> storeData = json.decode(storeJson);
            stores.add(Store(
              name: storeData['name'],
              id: storeData['id'],
              order: storeData['order'],
              imageLocation: '',
              storeItemList: List<int>.from(storeData['storeItemList']),
            ));
          } catch (e) {
            debugPrint('ERROR importing a store: $e');
          }
        }
        saveAllStores(stores);
      }
    } catch (e) {
      debugPrint('ERROR importing stores: $e');
    }

    try {
      if (data['items'] != null) {
        List<Item> items = [];
        for (final itemJson in (data['items'] as List)) {
          try {
            Map<String, dynamic> itemData = json.decode(itemJson);
            items.add(Item(
              name: itemData['name'],
              id: itemData['id'],
              isChecked: itemData['isChecked'],
              storeList: List<int>.from(itemData['storeList']),
              isOneTimeItem: itemData['isOneTimeItem'] ?? false,
            ));
          } catch (e) {
            debugPrint('ERROR importing an item: $e');
          }
        }
        saveAllItems(items);
      }
    } catch (e) {
      debugPrint('ERROR importing items: $e');
    }

    try {
      if (data['alphaOrder'] != null) {
        List<bool> alphaOrderList = List<bool>.from(
          (data['alphaOrder'] as List).map((v) => json.decode(v) as bool),
        );
        if (alphaOrderList.isNotEmpty) saveAlphaOrder(alphaOrderList[0], 1);
        if (alphaOrderList.length > 1) saveAlphaOrder(alphaOrderList[1], 2);
      }
    } catch (e) {
      debugPrint('ERROR importing alphaOrder: $e');
    }

    try {
      if (data['language'] != null) {
        saveLanguage(data['language'] as String);
      }
    } catch (e) {
      debugPrint('ERROR importing language: $e');
    }

    try {
      if (data['themeMode'] != null) {
        saveThemeMode(data['themeMode'] as int);
      }
    } catch (e) {
      debugPrint('ERROR importing themeMode: $e');
    }

    try {
      if (data['customTheme'] != null) {
        ColorPalette customTheme = ColorPalette.fromJson(data['customTheme'] as Map<String, dynamic>);
        saveCostumeTheme(customTheme);
      }
    } catch (e) {
      debugPrint('ERROR importing customTheme: $e');
    }
  }

  static Future<void> deleteStore(int id) async {
    Store? store = await loadStore('$storeKeyPrefix$id');
    if (store != null) {
      List<Item> items = await loadAllStoreItems(store.storeItemList);
      for (Item item in items) {
        deleteItem(item.id, store.id);
      }
      if (store.imageLocation != '') {
        if (File(store.imageLocation).existsSync()) {
          File(store.imageLocation).deleteSync();
        }
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$storeKeyPrefix$id');
  }

  static Future<void> deleteItem(int id, int storeId) async {
    Item? item = await loadItem('$itemKeyPrefix$id');
    Store? store = await loadStore('$storeKeyPrefix$storeId');
    if (item != null) {
      item.storeList.remove(storeId);
      await Storage.saveItem(item);
      if (item.storeList.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('$itemKeyPrefix$id');
      }
    }
    if (store != null) {
      store.storeItemList.remove(id);
      saveStore(store);
    }
  }

  static Future<void> deleteItemFromAllStores(int id) async {
    Item? item = await loadItem('$itemKeyPrefix$id');
    if (item != null) {
      for (int storeId in item.storeList) {
        await deleteItem(id, storeId);
      }
    }
  }

  static Future<void> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
          (key) => key.startsWith(storeKeyPrefix) || key.startsWith(itemKeyPrefix) || key.startsWith(alphaOrderKey),
        );
    for (final key in keys) {
      if (key.contains(storeKeyPrefix)) {
        Store? store = await loadStore(key);
        if (store != null && store.imageLocation != '' && File(store.imageLocation).existsSync()) {
          File(store.imageLocation).deleteSync();
        }
      }
      await prefs.remove(key);
    }
  }
}
