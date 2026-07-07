import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService instance = LanguageService._internal();
  LanguageService._internal();

  factory LanguageService() => instance;

  Map<String, dynamic> _strings = {};

  Future<void> load(String languageCode) async {
    final jsonString = await rootBundle.loadString('assets/language/$languageCode.jsonc');

    final cleaned = cleanJsonC(jsonString);
    _strings = json.decode(cleaned);

    notifyListeners();
  }

  String text(String key, [Map<String, String>? params]) {
    final parts = key.split('.');
    dynamic value = _strings;

    for (final part in parts) {
      value = value[part];
      if (value == null) return key;
    }

    String result = value.toString();

    if (params != null) {
      params.forEach((k, v) {
        result = result.replaceAll('{$k}', v);
      });
    }

    return result;
  }

  String cleanJsonC(String input) {
    return input.split('\n').where((line) => !line.trim().startsWith('//')).join('\n');
  }
}
