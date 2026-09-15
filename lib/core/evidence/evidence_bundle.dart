import 'evidence.dart';

class EvidenceBundle {
  final List<Evidence> items;

  EvidenceBundle(this.items);

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get length => items.length;

  List<Evidence> get sortedByConfidence =>
      List<Evidence>.from(items)..sort((a, b) => b.confidence.compareTo(a.confidence));
}
