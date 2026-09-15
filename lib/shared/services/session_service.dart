import 'package:flutter/foundation.dart';

class SessionService extends ChangeNotifier {
  final List<Map<String, dynamic>> _sessionLogs = [];

  List<Map<String, dynamic>> get sessionLogs => List.unmodifiable(_sessionLogs);
  int get count => _sessionLogs.length;

  void addEvent(String type, String detail) {
    _sessionLogs.add({
      'type': type,
      'detail': detail,
      'timestamp': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  void clearSession() {
    _sessionLogs.clear();
    notifyListeners();
  }
}
