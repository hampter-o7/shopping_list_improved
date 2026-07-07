import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_settings_ui/flutter_settings_ui.dart';
import 'package:provider/provider.dart';
import 'package:shopping_list/classes/colors.dart';
import 'package:shopping_list/classes/store.dart';
import 'package:shopping_list/main.dart';
import 'package:shopping_list/my_widgets/language_service.dart';
import 'package:shopping_list/my_widgets/theme_manager.dart';
import 'package:shopping_list/storage/local_storage.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  List<String> languageFiles = [];
  late Function updateStoreList;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Map args = ModalRoute.of(context)!.settings.arguments as Map;
    updateStoreList = args['updateStoreList'];
    loadLanguageFiles();
  }

  Future<void> loadLanguageFiles() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final files = manifest.listAssets().where((key) => key.startsWith('assets/language/') && key.endsWith('.jsonc')).toList();
    languageFiles = files;
  }

  String formatLanguageName(String path) {
    final fileName = path.split('/').last.replaceAll('.jsonc', '');
    return fileName[0].toUpperCase() + fileName.substring(1);
  }

  Future<void> showConfirmationDialog(String message, bool isDelete) async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          content: Text(message),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.read<LanguageService>().text("actions.cancel")),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                ThemeManager themeManager = context.read<ThemeManager>();
                if (isDelete) {
                  await Storage.deleteAll();
                } else {
                  await Storage.importNewData();
                  Storage.printAllSavedData();
                }
                themeManager.setTheme(AppTheme.values[await Storage.loadThemeMode()]);
                themeManager.setCustomPalette(await Storage.loadCustomTheme());
                List<Store> storeList = await Storage.loadAllStores();
                updateStoreList(storeList);
              },
              child: Text(context.read<LanguageService>().text("actions.yes")),
            ),
          ],
        );
      },
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
      appBar: AppBar(
        title: Text(context.read<LanguageService>().text("settings.title").toUpperCase()),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
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
                title: Text(context.read<LanguageService>().text("settings.deleteEverything")),
                onPressed: (value) {
                  showConfirmationDialog(context.read<LanguageService>().text("settings.deleteEverythingConfirm"), true);
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.file_upload_outlined),
                title: Text(context.read<LanguageService>().text("settings.export")),
                onPressed: (value) {
                  Storage.exportAllData();
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.file_download_outlined),
                title: Text(context.read<LanguageService>().text("settings.import")),
                onPressed: (value) {
                  showConfirmationDialog(context.read<LanguageService>().text("settings.importConfirm"), false);
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.color_lens),
                title: Text(context.read<LanguageService>().text("settings.colorTheme")),
                onPressed: (context) => Navigator.pushNamed(context, '/ColorPicker'),
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.language),
                title: Text(context.read<LanguageService>().text("settings.language")),
                onPressed: (context) async {
                  final result = await showDialog<String>(
                    context: context,
                    builder: (_) {
                      return SimpleDialog(
                        children: languageFiles.map((path) {
                          final name = formatLanguageName(path);
                          final value = path.split('/').last.replaceAll('.jsonc', '');
                          return SimpleDialogOption(
                            child: Text(name),
                            onPressed: () => Navigator.pop(context, value),
                          );
                        }).toList(),
                      );
                    },
                  );
                  if (result != null) {
                    await language.load(result);
                    Storage.saveLanguage(result);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
