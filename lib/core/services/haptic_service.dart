abstract class HapticService {
  Future<void> verified();
  Future<void> uncertain();
  Future<void> conflict();
  Future<void> warning();
  Future<void> obstacleProximity(double proximity01);
  Future<void> vibratePhrase(String phrase);
}
