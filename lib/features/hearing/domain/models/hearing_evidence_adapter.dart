import 'transcript_segment.dart';
import 'sound_event.dart';
import 'tone_inference.dart';

class HearingEvidenceAdapter {
  static Map<String, dynamic> fromTranscriptSegment(TranscriptSegment segment) {
    return {
      'source': 'microphone',
      'type': 'speech',
      'value': segment.text,
      'confidence': segment.confidence,
      'timestamp': segment.timestamp.toIso8601String(),
      'metadata': {
        'speakerId': segment.speakerId,
        'isPartial': segment.isPartial,
        'isLowConfidence': segment.isLowConfidence,
        'rawText': segment.rawText,
        if (segment.tone != null) 'tone': segment.tone!.toMap(),
      },
    };
  }

  static Map<String, dynamic> fromSoundEvent(SoundEvent event) {
    return {
      'source': 'soundClassification',
      'type': 'sound',
      'value': event.formattedDescription,
      'confidence': event.confidence,
      'timestamp': event.timestamp.toIso8601String(),
      'metadata': {
        'category': event.category.name,
        'label': event.label,
        'isDanger': event.isDanger,
      },
    };
  }

  static Map<String, dynamic> fromToneInference(ToneInference tone, String speakerId) {
    return {
      'source': 'soundClassification',
      'type': 'tone',
      'value': tone.explanationText,
      'confidence': tone.confidence,
      'metadata': {
        'toneType': tone.type.name,
        'speakerId': speakerId,
      },
    };
  }
}
