import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _keyTextScale = 'settings_text_scale';
  static const String _keyHighContrast = 'settings_high_contrast';
  static const String _keyHaptics = 'settings_haptics_enabled';
  static const String _keyBatterySaver = 'settings_battery_saver';
  static const String _keySpeechRate = 'settings_speech_rate';
  static const String _keyPreferredMode = 'settings_preferred_mode';
  static const String _keyOnboardingComplete = 'settings_onboarding_complete';
  static const String _keyAutoSos = 'settings_auto_sos_critical';

  final SharedPreferences _prefs;

  SettingsService(this._prefs) {
    _load();
  }

  double _textScale = 1.0;
  bool _highContrast = false;
  bool _hapticsEnabled = true;
  bool _batterySaver = false;
  double _speechRate = 1.0;
  String? _preferredMode;
  bool _onboardingComplete = false;
  bool _autoSosCritical = false;

  double get textScale => _textScale;
  bool get highContrast => _highContrast;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get batterySaver => _batterySaver;
  double get speechRate => _speechRate;
  String? get preferredMode => _preferredMode;
  bool get onboardingComplete => _onboardingComplete;
  bool get autoSosCritical => _autoSosCritical;

  void _load() {
    _textScale = _prefs.getDouble(_keyTextScale) ?? 1.0;
    _highContrast = _prefs.getBool(_keyHighContrast) ?? false;
    _hapticsEnabled = _prefs.getBool(_keyHaptics) ?? true;
    _batterySaver = _prefs.getBool(_keyBatterySaver) ?? false;
    _speechRate = _prefs.getDouble(_keySpeechRate) ?? 1.0;
    _preferredMode = _prefs.getString(_keyPreferredMode);
    _onboardingComplete = _prefs.getBool(_keyOnboardingComplete) ?? false;
    _autoSosCritical = _prefs.getBool(_keyAutoSos) ?? false;
  }

  Future<void> setTextScale(double value) async {
    _textScale = value;
    await _prefs.setDouble(_keyTextScale, value);
    notifyListeners();
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    await _prefs.setBool(_keyHighContrast, value);
    notifyListeners();
  }

  Future<void> setHapticsEnabled(bool value) async {
    _hapticsEnabled = value;
    await _prefs.setBool(_keyHaptics, value);
    notifyListeners();
  }

  Future<void> setBatterySaver(bool value) async {
    _batterySaver = value;
    await _prefs.setBool(_keyBatterySaver, value);
    notifyListeners();
  }

  Future<void> setSpeechRate(double value) async {
    _speechRate = value;
    await _prefs.setDouble(_keySpeechRate, value);
    notifyListeners();
  }

  Future<void> setPreferredMode(String? mode) async {
    _preferredMode = mode;
    if (mode == null) {
      await _prefs.remove(_keyPreferredMode);
    } else {
      await _prefs.setString(_keyPreferredMode, mode);
    }
    notifyListeners();
  }

  Future<void> setOnboardingComplete(bool value) async {
    _onboardingComplete = value;
    await _prefs.setBool(_keyOnboardingComplete, value);
    notifyListeners();
  }

  Future<void> setAutoSosCritical(bool value) async {
    _autoSosCritical = value;
    await _prefs.setBool(_keyAutoSos, value);
    notifyListeners();
  }
}
