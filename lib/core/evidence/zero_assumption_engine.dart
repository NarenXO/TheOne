import '../models/confidence_state.dart';
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

    // Prefer OCR and speech for verification answers
    final primary = bundle.items.where((e) {
      return e.type.name == 'ocr' ||
          e.type.name == 'speech' ||
          e.type.name == 'object' ||
          e.type.name == 'obstacle';
    }).toList();

    final working = primary.isNotEmpty ? primary : bundle.items;

    // Normalize values
    String norm(String s) => s.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');

    // If query mentions a room/number, focus only matching evidence
    final q = query.toLowerCase();
    final roomMatch = RegExp(r'(room\s*)?(\d{2,4})').firstMatch(q);
    List<Evidence> focused = working;
    if (roomMatch != null) {
      final num = roomMatch.group(2)!;
      final roomFocused = working.where((e) {
        final v = norm(e.value);
        return v.contains(num) || v.contains('ROOM $num') || v.contains('ROOM$num');
      }).toList();
      if (roomFocused.isNotEmpty) focused = roomFocused;
    }

    // Group near-identical OCR lines carefully:
    // Only mark CONFLICT when two HIGH-confidence sources disagree on a KEY fact (room numbers etc.)
    final roomValues = <String, List<Evidence>>{};
    for (final e in focused) {
      final m = RegExp(r'\b(\d{2,4})\b').firstMatch(norm(e.value));
      if (m != null && (norm(e.value).contains('ROOM') || q.contains('room') || q.contains(m.group(1)!))) {
        roomValues.putIfAbsent(m.group(1)!, () => []).add(e);
      }
    }

    if (roomValues.length > 1) {
      // true conflict only if at least two different room numbers with conf >= 0.75
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

    // Otherwise pick best evidence by confidence
    focused.sort((a, b) => b.confidence.compareTo(a.confidence));
    final top = focused.first;

    // Boost OCR text confidence floor for recognized text
    final conf = top.confidence;

    if (EvidenceThresholds.isStrong(conf) || conf >= 0.80) {
      final result = VerificationResult(
        state: ConfidenceState.verified,
        message: "Verified. ${top.value}",
        supporting: focused,
      );
      AppLogger.i('ENGINE', 'Result state: ${result.state.name.toUpperCase()} -> "${result.message}"');
      return result;
    }
    if (conf >= 0.50) {
      final result = VerificationResult(
        state: ConfidenceState.uncertain,
        message: "I think I see ${top.value}, but confidence is moderate. Please rescan if needed.",
        supporting: focused,
      );
      AppLogger.i('ENGINE', 'Result state: ${result.state.name.toUpperCase()} -> "${result.message}"');
      return result;
    }

    // If we still have readable OCR text, report it instead of dead-end weak message
    final ocrText = focused.where((e) => e.type.name == 'ocr').map((e) => e.value).toList();
    if (ocrText.isNotEmpty) {
      final result = VerificationResult(
        state: ConfidenceState.uncertain,
        message: "I can read: ${ocrText.take(3).join(' | ')}. Please confirm.",
        supporting: focused,
      );
      AppLogger.i('ENGINE', 'Result state: ${result.state.name.toUpperCase()} -> "${result.message}"');
      return result;
    }

    final result = VerificationResult(
      state: ConfidenceState.insufficient,
      message: "Evidence too weak to verify. Please move closer and scan again.",
    );
    AppLogger.i('ENGINE', 'Result state: ${result.state.name.toUpperCase()} -> "${result.message}"');
    return result;
  }
}
