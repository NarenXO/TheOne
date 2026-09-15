import 'package:flutter/foundation.dart';

class DemoItem {
  final String title;
  final String source;
  final String value;
  final double confidence;
  final String state;

  const DemoItem({
    required this.title,
    required this.source,
    required this.value,
    required this.confidence,
    required this.state,
  });
}

class DemoModeService extends ChangeNotifier {
  static const List<DemoItem> sampleEvidence = [
    DemoItem(
      title: 'Vision Assist Demo',
      source: 'Camera (OCR)',
      value: 'ROOM 204',
      confidence: 0.98,
      state: 'VERIFIED',
    ),
    DemoItem(
      title: 'Hearing Assist Demo',
      source: 'Microphone (YAMNet)',
      value: 'Possible Vehicle Horn Detected',
      confidence: 0.91,
      state: 'UNCERTAIN',
    ),
    DemoItem(
      title: 'Communication Assist Demo',
      source: 'Context Recommendation',
      value: 'I would like a medium chai, please.',
      confidence: 0.95,
      state: 'VERIFIED',
    ),
  ];
}
