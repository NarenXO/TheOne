import 'package:torch_light/torch_light.dart';
import '../torch_service.dart';

class TorchServiceImpl implements TorchService {
  @override
  Future<bool> isAvailable() async {
    try {
      return await TorchLight.isTorchAvailable();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> turnOn() async {
    try {
      if (await isAvailable()) {
        await TorchLight.enableTorch();
      }
    } catch (_) {}
  }

  @override
  Future<void> turnOff() async {
    try {
      if (await isAvailable()) {
        await TorchLight.disableTorch();
      }
    } catch (_) {}
  }
}
