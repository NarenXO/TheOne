import 'package:flutter_test/flutter_test.dart';
import 'package:theone/core/evidence/evidence.dart';
import 'package:theone/core/evidence/evidence_bundle.dart';
import 'package:theone/core/evidence/zero_assumption_engine.dart';
import 'package:theone/core/models/confidence_state.dart';
import 'package:theone/core/models/evidence_source.dart';
import 'package:theone/core/models/evidence_type.dart';

void main() {
  final engine = ZeroAssumptionEngine();

  test('insufficient when empty', () {
    final r = engine.verify(query: 'x', bundle: EvidenceBundle([]));
    expect(r.state, ConfidenceState.insufficient);
  });

  test('verified with strong evidence', () {
    final r = engine.verify(query: 'Is this Room 204?', bundle: EvidenceBundle([
      Evidence(source: EvidenceSource.camera, type: EvidenceType.ocr, value: 'ROOM 204', confidence: 0.98),
    ]));
    expect(r.state, ConfidenceState.verified);
  });

  test('uncertain with weak evidence', () {
    final r = engine.verify(query: 'x', bundle: EvidenceBundle([
      Evidence(source: EvidenceSource.camera, type: EvidenceType.ocr, value: 'ROOM 204', confidence: 0.70),
    ]));
    expect(r.state, ConfidenceState.uncertain);
  });

  test('conflict when sources disagree', () {
    final r = engine.verify(query: 'x', bundle: EvidenceBundle([
      Evidence(source: EvidenceSource.camera, type: EvidenceType.ocr, value: 'ROOM 204', confidence: 0.98),
      Evidence(source: EvidenceSource.microphone, type: EvidenceType.speech, value: 'ROOM 302', confidence: 0.9),
    ]));
    expect(r.state, ConfidenceState.conflict);
  });
}
