import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  // TODO implement other language recognition
  SpeechService._internal();
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;

  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  Function(String errorMsg)? _onErrorCallback;

  bool get isListening => _speech.isListening;

  Future<bool> initSpeech() async {
    if (_isInitialized) return true;

    var status = await Permission.microphone.status;

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }
      if (!status.isGranted) return false;
    }

    _isInitialized = await _speech.initialize(
      onError: (error) {
        debugPrint('Speech error: $error');
        _onErrorCallback?.call(error.errorMsg);
      },
      onStatus: (status) => debugPrint('Speech status: $status'),
    );
    return _isInitialized;
  }

  Future<void> startListening(Function(String) onResult, {Function(String errorMsg)? onError, String? localeId}) async {
    _onErrorCallback = onError;

    if (!_isInitialized) {
      bool ok = await initSpeech();
      if (!ok) return;
    }
    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
      listenOptions: SpeechListenOptions(localeId: localeId),
    );
  }

  void stopListening() => _speech.stop();
}
