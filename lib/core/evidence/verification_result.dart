import '../models/confidence_state.dart';
import 'evidence.dart';

class VerificationResult {
  final ConfidenceState state;
  final String message;
  final List<Evidence> supporting;
  final List<Evidence> conflicting;

  VerificationResult({
    required this.state,
    required this.message,
    this.supporting = const [],
    this.conflicting = const [],
  });

  @override
  String toString() =>
      'VerificationResult(state: ${state.name}, message: "$message", supporting: ${supporting.length}, conflicting: ${conflicting.length})';
}
