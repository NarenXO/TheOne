import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyContact {
  final String name;
  final String phoneNumber;

  const EmergencyContact({required this.name, required this.phoneNumber});
}

class EmergencyContactStore extends ChangeNotifier {
  static const String _keyName = 'emergency_contact_name';
  static const String _keyPhone = 'emergency_contact_phone';

  final SharedPreferences _prefs;
  EmergencyContact? _contact;

  EmergencyContactStore(this._prefs) {
    _load();
  }

  EmergencyContact? get contact => _contact;
  bool get hasContact => _contact != null && _contact!.phoneNumber.isNotEmpty;

  void _load() {
    final name = _prefs.getString(_keyName);
    final phone = _prefs.getString(_keyPhone);
    if (phone != null && phone.isNotEmpty) {
      _contact = EmergencyContact(name: name ?? 'Emergency Contact', phoneNumber: phone);
    } else {
      _contact = null;
    }
  }

  static bool validatePhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return clean.length >= 3 && clean.length <= 15 && RegExp(r'^\+?[0-9]+$').hasMatch(clean);
  }

  Future<bool> saveContact({required String name, required String phoneNumber}) async {
    if (!validatePhone(phoneNumber)) return false;
    final cleanName = name.trim().isEmpty ? 'Emergency Contact' : name.trim();
    final cleanPhone = phoneNumber.trim();
    await _prefs.setString(_keyName, cleanName);
    await _prefs.setString(_keyPhone, cleanPhone);
    _contact = EmergencyContact(name: cleanName, phoneNumber: cleanPhone);
    notifyListeners();
    return true;
  }

  Future<void> clearContact() async {
    await _prefs.remove(_keyName);
    await _prefs.remove(_keyPhone);
    _contact = null;
    notifyListeners();
  }
}
