import '../models/confidence_state.dart';
import '../models/evidence_type.dart';
import '../utils/app_logger.dart';
import 'evidence.dart';
import 'evidence_bundle.dart';
import 'evidence_thresholds.dart';
import 'verification_result.dart';

class ZeroAssumptionEngine {
  VerificationResult verify({
    required String query,
    required EvidenceBundle bundle,
  }) {
    AppLogger.i('ENGINE', 'Evaluating query: "$query" with ${bundle.length} evidence items');

    if (bundle.isEmpty) {
      final result = VerificationResult(
        state: ConfidenceState.insufficient,
        message: "I can't verify that from what I can see or hear. Please scan again.",
      );
      AppLogger.i('ENGINE', 'Result state: ${result.state.name.toUpperCase()} -> "${result.message}"');
      return result;
    }

    // Normalize values
    String norm(String s) => s.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');

    final q = query.toLowerCase();

    // Check for room conflict between strong sources
    final roomValues = <String, List<Evidence>>{};
    for (final e in bundle.items) {
      final m = RegExp(r'\b(\d{2,4})\b').firstMatch(norm(e.value));
      if (m != null && (norm(e.value).contains('ROOM') || q.contains('room') || q.contains(m.group(1)!))) {
        roomValues.putIfAbsent(m.group(1)!, () => []).add(e);
      }
    }

    if (roomValues.length > 1) {
      final strongRooms = roomValues.entries.where((e) {
        return e.value.any((x) => x.confidence >= 0.75);
      }).toList();
      if (strongRooms.length > 1) {
        final labels = strongRooms.map((e) => 'ROOM ${e.key}').join(' vs ');
        final result = VerificationResult(
          state: ConfidenceState.conflict,
          message: "I found conflicting information: $labels. Please rescan or verify.",
          conflicting: strongRooms.expand((e) => e.value).toList(),
        );
        AppLogger.i('ENGINE', 'Result state: ${result.state.name.toUpperCase()} -> "${result.message}"');
        return result;
      }
    }

    // Extract Image Labels & OCR text values
    final labels = bundle.items
        .where((e) => e.type == EvidenceType.object || e.type == EvidenceType.obstacle)
        .map((e) => e.value)
        .toSet()
        .toList();

    final ocrLines = bundle.items
        .where((e) => e.type == EvidenceType.ocr)
        .map((e) => e.value)
        .toSet()
        .toList();

    // Sort evidence by confidence
    final sorted = List<Evidence>.from(bundle.items)..sort((a, b) => b.confidence.compareTo(a.confidence));
    final top = sorted.first;
    final conf = top.confidence;

    // Determine state
    ConfidenceState state = ConfidenceState.insufficient;
    if (EvidenceThresholds.isStrong(conf) || conf >= 0.80) {
      state = ConfidenceState.verified;
    } else if (conf >= 0.50) {
      state = ConfidenceState.uncertain;
    }

    // Construct natural description answer
    String answer = "";

    // Color/Clothing query
    if (q.contains("color") || q.contains("colour") || q.contains("shirt") || q.contains("pant") || q.contains("dress")) {
      if (labels.isNotEmpty) {
        answer = "I can see ${labels.take(3).join(', ')}.";
      }
    }

    if (answer.isEmpty && (labels.isNotEmpty || ocrLines.isNotEmpty)) {
      answer = "In front of you, ";
      if (labels.isNotEmpty) {
        answer += "I can see ${labels.take(3).join(', ')}. ";
      }
      if (ocrLines.isNotEmpty) {
        answer += "The sign reads: ${ocrLines.take(2).join(' ')}.";
      }
      answer = answer.trim();
    }

    if (answer.isEmpty) {
      answer = "I can't verify what is in front of you. Please move closer and scan again.";
    }

    if (state == ConfidenceState.uncertain) {
      answer = "I think $answer, but confidence is moderate. Please rescan if needed.";
    } else if (state == ConfidenceState.verified && !answer.startsWith("Verified")) {
      answer = "Verified. $answer";
    }

    final result = VerificationResult(
      state: state,
      message: answer,
      supporting: sorted,
    );
    AppLogger.i('ENGINE', 'Result state: ${result.state.name.toUpperCase()} -> "${result.message}"');
    return result;
  }
}
