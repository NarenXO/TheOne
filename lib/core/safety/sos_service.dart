import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';

class SosService {
  final Battery _battery = Battery();

  Future<String?> generateSosMessage() async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      bool serviceEnabled = await _isLocationServicePermissionGranted();
      
      Position? position;
      if (serviceEnabled) {
        position = await Geolocator.getLastKnownPosition();
      }

      final locStr = position != null
          ? "Lat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}"
          : "Location unavailable";

      return "EMERGENCY AUTO-SOS [TheOne App]\nDevice shutting down (Battery: $batteryLevel%).\nLast Location: $locStr";
    } catch (e) {
      return "EMERGENCY AUTO-SOS [TheOne App]\nDevice battery low. Location unavailable.";
    }
  }

  Future<bool> _isLocationServicePermissionGranted() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
  }
}
