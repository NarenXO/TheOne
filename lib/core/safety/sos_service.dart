import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class SosService {
  final Battery _battery = Battery();

  /// Emergency contact number. User can change later in settings.
  /// Keep as editable constant for hackathon.
  static const String emergencyContact = '911'; // CHANGE to real contact for demo

  Future<bool> _ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<String> generateSosMessage() async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      String locStr = 'Location unavailable';

      if (await _ensureLocationPermission()) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        ).catchError((_) async =>
            await Geolocator.getLastKnownPosition() ??
            Position(
              longitude: 0,
              latitude: 0,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              altitudeAccuracy: 0,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
            ));

        if (position.latitude != 0 || position.longitude != 0) {
          locStr =
              'https://maps.google.com/?q=${position.latitude},${position.longitude}';
        }
      }

      return 'EMERGENCY AUTO-SOS [TheOne]\nBattery: $batteryLevel%\nLocation: $locStr\nNeed help immediately.';
    } catch (_) {
      return 'EMERGENCY AUTO-SOS [TheOne]\nBattery critical. Location unavailable. Need help immediately.';
    }
  }

  /// Opens native SMS app prefilled with emergency message.
  /// This is real SMS flow (user confirms send on Android).
  Future<bool> sendSosSms({String? contact}) async {
    final message = await generateSosMessage();
    final number = contact ?? emergencyContact;
    final uri = Uri.parse(
      'sms:$number?body=${Uri.encodeComponent(message)}',
    );
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }
    return false;
  }
}
