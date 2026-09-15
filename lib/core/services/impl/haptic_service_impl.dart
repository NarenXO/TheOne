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

  @override
  Future<void> vibratePhrase(String phrase) async {
    if (!(await _hasVibrator())) return;
    final lower = phrase.toLowerCase().trim();

    if (lower.contains("yes") || lower == "ok" || lower.contains("agree")) {
      Vibration.vibrate(pattern: [0, 60]); // 1 short pulse
    } else if (lower.contains("no") || lower.contains("stop") || lower.contains("deny")) {
      Vibration.vibrate(pattern: [0, 60, 60, 60]); // 2 sharp pulses
    } else if (lower.contains("name") || lower.contains("calling")) {
      Vibration.vibrate(pattern: [0, 80, 50, 80]); // double tap
    } else if (lower.contains("thank") || lower.contains("nandri")) {
      Vibration.vibrate(pattern: [0, 100, 80, 100]); // heartbeat rhythm
    } else if (lower.contains("excuse") || lower.contains("attention")) {
      Vibration.vibrate(pattern: [0, 40, 40, 40, 40, 40]); // triple tick
    } else if (lower.contains("danger") || lower.contains("alarm") || lower.contains("fire")) {
      Vibration.vibrate(pattern: [0, 400, 100, 400]); // long warning buzz
    } else {
      Vibration.vibrate(duration: 70);
    }
  }
}
