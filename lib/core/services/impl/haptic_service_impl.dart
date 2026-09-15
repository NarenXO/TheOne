import 'package:vibration/vibration.dart';
import '../haptic_service.dart';

class HapticServiceImpl implements HapticService {
  Future<bool> _hasVibrator() async {
    return await Vibration.hasVibrator();
  }

  @override
  Future<void> verified() async {
    if (await _hasVibrator()) {
      Vibration.vibrate(duration: 80);
    }
  }

  @override
  Future<void> uncertain() async {
    if (await _hasVibrator()) {
      Vibration.vibrate(pattern: [0, 60, 80, 60]);
    }
  }

  @override
  Future<void> conflict() async {
    if (await _hasVibrator()) {
      Vibration.vibrate(pattern: [0, 80, 80, 80, 80, 80]);
    }
  }

  @override
  Future<void> warning() async {
    if (await _hasVibrator()) {
      Vibration.vibrate(pattern: [0, 300, 100, 80]);
    }
  }

  @override
  Future<void> obstacleProximity(double proximity01) async {
    if (!(await _hasVibrator())) return;
    final gap = (200 - (proximity01.clamp(0.0, 1.0) * 180)).toInt();
    Vibration.vibrate(pattern: [0, 60, gap, 60, gap, 60]);
  }
}
