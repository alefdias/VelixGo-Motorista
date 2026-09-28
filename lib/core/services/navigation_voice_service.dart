import 'package:flutter_tts/flutter_tts.dart';

class NavigationVoiceService {
  static final NavigationVoiceService _instance = NavigationVoiceService._internal();
  factory NavigationVoiceService() => _instance;
  NavigationVoiceService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isVoiceEnabled = true;
  String _lastSpoken = '';
  DateTime? _lastSpokenAt;

  bool get isVoiceEnabled => _isVoiceEnabled;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _tts.setLanguage('pt-BR');
      await _tts.setSpeechRate(0.52);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _isInitialized = true;
    } catch (_) {}
  }

  void toggleVoice() {
    _isVoiceEnabled = !_isVoiceEnabled;
    if (!_isVoiceEnabled) {
      stop();
    } else {
      speak('Navegação por voz ativada');
    }
  }

  Future<void> speak(String text) async {
    if (!_isVoiceEnabled) return;
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    // Evita repetir a mesma instrução se foi falada há menos de 10 segundos
    if (_lastSpoken == cleanText && _lastSpokenAt != null) {
      final diff = DateTime.now().difference(_lastSpokenAt!).inSeconds;
      if (diff < 10) return;
    }

    _lastSpoken = cleanText;
    _lastSpokenAt = DateTime.now();

    await initialize();
    try {
      await _tts.speak(cleanText);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
