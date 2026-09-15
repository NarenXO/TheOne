import 'evidence.dart';

class RelevanceEngine {
  static const Map<String, List<String>> _keywordMap = {
    'exit': ['exit', 'வெளியேறு', 'way out'],
    'door': ['door', 'கதவு'],
    'room': ['room', 'அறை', 'classroom'],
    'toilet': ['toilet', 'restroom', 'washroom', 'கழிவறை'],
    'lift': ['lift', 'elevator'],
    'stairs': ['stairs', 'staircase', 'படிக்கட்டு'],
    'registration': ['registration', 'reg', 'பதிவு'],
    'entrance': ['entrance', 'entry', 'நுழைவு'],
  };

  List<Evidence> rank({required String query, required List<Evidence> evidence}) {
    final q = query.toLowerCase();
    final matched = <Evidence>[];
    final others = <Evidence>[];

    for (final e in evidence) {
      final v = e.value.toLowerCase();
      bool relevant = false;
      for (final entry in _keywordMap.entries) {
        if (q.contains(entry.key)) {
          for (final kw in entry.value) {
            if (v.contains(kw.toLowerCase())) { relevant = true; break; }
          }
        }
        if (relevant) break;
      }
      (relevant ? matched : others).add(e);
    }

    matched.sort((a, b) => b.confidence.compareTo(a.confidence));
    others.sort((a, b) => b.confidence.compareTo(a.confidence));
    return [...matched, ...others];
  }
}
