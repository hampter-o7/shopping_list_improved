import 'package:flutter/material.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:shopping_list/classes/colors.dart';

import '../classes/store.dart';
import '../storage/local_storage.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late Function updateStoreList;

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    Map args = ModalRoute.of(context)!.settings.arguments as Map;
    updateStoreList = args['updateStoreList'];
  }

  void showSnackbar(String message, bool isDelete) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        persist: false,
        action: SnackBarAction(
          label: 'Yes',
          onPressed: () async {
            if (isDelete) {
              Storage.deleteAll();
              List<Store> storeList = [];
              updateStoreList(storeList);
            } else {
              await Storage.importNewData();
              List<Store> storeList = await Storage.loadAllStores();
              Storage.printAllSavedData();
              updateStoreList(storeList);
            }
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SettingsThemeData theme = SettingsThemeData(
      settingsListBackground: AppColors.of(context).background,
      settingsSectionBackground: AppColors.of(context).resolvedItemBackground,
      settingsTileTextColor: AppColors.of(context).resolvedItemText,
      leadingIconsColor: AppColors.of(context).resolvedItemText,
    );
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text('SETTINGS', style: TextStyle(color: AppColors.of(context).resolvedTitleText)),
        centerTitle: true,
        backgroundColor: AppColors.of(context).resolvedTitleBackground,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.of(context).resolvedTitleText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SettingsList(
        lightTheme: theme,
        darkTheme: theme,
        sections: [
          SettingsSection(
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.delete),
                title: const Text('Delete everything'),
                onPressed: (value) {
                  showSnackbar(
                    'Are you sure you want to delete all the data?',
                    true,
                  );
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.file_upload_outlined),
                title: const Text('Export data'),
                onPressed: (value) {
                  Storage.exportAllData();
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.file_download_outlined),
                title: const Text('Import data'),
                onPressed: (value) async {
                  showSnackbar(
                    'Are you sure you want to delete all current data and import new data?',
                    false,
                  );
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.color_lens),
                title: const Text('Change color theme'),
                onPressed: (context) async {
                  Navigator.pushNamed(context, '/ColorPicker');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
