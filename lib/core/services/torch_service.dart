abstract class TorchService {
  Future<void> turnOn();
  Future<void> turnOff();
  Future<bool> isAvailable();
}
