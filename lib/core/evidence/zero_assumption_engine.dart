import '../models/confidence_state.dart';
import 'evidence.dart';
import 'evidence_bundle.dart';
import 'evidence_thresholds.dart';
import 'verification_result.dart';

class ZeroAssumptionEngine {
  VerificationResult verify({
    required String query,
    required EvidenceBundle bundle,
  }) {
    if (bundle.isEmpty) {
      return VerificationResult(
        state: ConfidenceState.insufficient,
        message: "I can't verify that from what I can see or hear. Please rescan.",
      );
    }

    final grouped = <String, List<Evidence>>{};
    for (final e in bundle.items) {
      final key = e.value.trim().toUpperCase();
      grouped.putIfAbsent(key, () => []).add(e);
    }

    if (grouped.length > 1) {
      final values = grouped.keys.toList();
      return VerificationResult(
        state: ConfidenceState.conflict,
        message: "I found conflicting information: ${values.join(' vs ')}. Please rescan or verify.",
        conflicting: bundle.items,
      );
    }

    final sorted = bundle.sortedByConfidence;
    final top = sorted.first;

    if (EvidenceThresholds.isStrong(top.confidence)) {
      return VerificationResult(
        state: ConfidenceState.verified,
        message: "Verified. ${top.value}",
        supporting: sorted,
      );
    }
    if (EvidenceThresholds.isUncertain(top.confidence)) {
      return VerificationResult(
        state: ConfidenceState.uncertain,
        message: "I think I see ${top.value}, but confidence is low. Please rescan.",
        supporting: sorted,
      );
    }
    return VerificationResult(
      state: ConfidenceState.insufficient,
      message: "Evidence too weak to verify. Please rescan.",
    );
  }
}
