import '../../../../core/evidence/evidence.dart';
import '../../../../core/models/evidence_source.dart';
import '../../../../core/models/evidence_type.dart';
import 'transcript_segment.dart';
import 'sound_event.dart';
import 'tone_inference.dart';

class HearingEvidenceAdapter {
  static Evidence fromTranscriptSegment(TranscriptSegment segment) {
    return Evidence(
      source: EvidenceSource.microphone,
      type: EvidenceType.speech,
      value: segment.text,
      confidence: segment.confidence,
      timestamp: segment.timestamp,
      metadata: {
        'speakerId': segment.speakerId,
        'isPartial': segment.isPartial,
        'isLowConfidence': segment.isLowConfidence,
        'rawText': segment.rawText,
        if (segment.tone != null) 'tone': segment.tone!.toMap(),
      },
    );
  }

  static Evidence fromSoundEvent(SoundEvent event) {
    return Evidence(
      source: EvidenceSource.soundClassification,
      type: EvidenceType.sound,
      value: event.formattedDescription,
      confidence: event.confidence,
      timestamp: event.timestamp,
      metadata: {
        'category': event.category.name,
        'label': event.label,
        'isDanger': event.isDanger,
      },
    );
  }

  static Evidence fromToneInference(ToneInference tone, String speakerId) {
    return Evidence(
      source: EvidenceSource.soundClassification,
      type: EvidenceType.tone,
      value: tone.explanationText,
      confidence: tone.confidence,
      metadata: {
        'toneType': tone.type.name,
        'speakerId': speakerId,
      },
    );
  }
}
