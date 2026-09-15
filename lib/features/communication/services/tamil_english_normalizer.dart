class TamilEnglishNormalizer {
  static const Map<String, String> tanglishToEnglish = {
    'enga': 'where',
    'irukku': 'is',
    'venum': 'want',
    'kekkanum': 'ask',
    'saapadu': 'food',
    'kaasu': 'money',
    'evvalavu': 'how much',
    'vilai': 'price',
    'udhavi': 'help',
    'nandri': 'thanks',
    'vanakkam': 'hello',
    'illa': 'no',
    'aama': 'yes',
    'irunga': 'please',
    'kudunga': 'give',
    'marubadiyum': 'again',
    'porunga': 'wait',
    'thanni': 'water',
    'kaapi': 'coffee',
    'koode': 'stay',
    'puriyala': 'not understand',
    'pesunga': 'speak',
  };

  static String normalize(String input) {
    final normalized = input.toLowerCase().trim();
    final words = normalized.split(RegExp(r'\s+'));
    
    final normalizedWords = words.map((word) {
      // Remove common suffixes
      var cleanWord = word.replaceAll(RegExp(r'[.,!?;:]$'), '');
      
      // Map Tanglish to English
      if (tanglishToEnglish.containsKey(cleanWord)) {
        return tanglishToEnglish[cleanWord]!;
      }
      
      return cleanWord;
    }).toList();
    
    return normalizedWords.join(' ');
  }

  static List<String> extractKeywords(String input) {
    final normalized = normalize(input);
    return normalized.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  }

  static bool containsLocationKeywords(String input) {
    final keywords = extractKeywords(input);
    final locationKeywords = ['where', 'enga', 'location', 'address', 'desk', 'counter', 'irukku'];
    return keywords.any((kw) => locationKeywords.contains(kw));
  }

  static bool containsFoodKeywords(String input) {
    final keywords = extractKeywords(input);
    final foodKeywords = ['venum', 'kudunga', 'chai', 'coffee', 'tea', 'order', 'want', 'saapadu', 'kaapi'];
    return keywords.any((kw) => foodKeywords.contains(kw));
  }

  static bool containsPriceKeywords(String input) {
    final keywords = extractKeywords(input);
    final priceKeywords = ['evvalavu', 'cost', 'price', 'vilai', 'rate', 'kaasu'];
    return keywords.any((kw) => priceKeywords.contains(kw));
  }

  static bool containsHelpKeywords(String input) {
    final keywords = extractKeywords(input);
    final helpKeywords = ['help', 'udhavi', 'assist', 'emergency', 'save'];
    return keywords.any((kw) => helpKeywords.contains(kw));
  }

  static bool containsGreetingKeywords(String input) {
    final keywords = extractKeywords(input);
    final greetingKeywords = ['hello', 'hi', 'vanakkam', 'morning', 'good'];
    return keywords.any((kw) => greetingKeywords.contains(kw));
  }

  static bool containsThanksKeywords(String input) {
    final keywords = extractKeywords(input);
    final thanksKeywords = ['thank', 'thanks', 'nandri'];
    return keywords.any((kw) => thanksKeywords.contains(kw));
  }

  static bool containsRepeatKeywords(String input) {
    final keywords = extractKeywords(input);
    final repeatKeywords = ['repeat', 'again', 'marubadiyum', 'puriyala'];
    return keywords.any((kw) => repeatKeywords.contains(kw));
  }

  static bool containsWaitKeywords(String input) {
    final keywords = extractKeywords(input);
    final waitKeywords = ['wait', 'moment', 'porunga', 'irunga'];
    return keywords.any((kw) => waitKeywords.contains(kw));
  }

  static bool containsDirectionKeywords(String input) {
    final keywords = extractKeywords(input);
    final directionKeywords = ['left', 'right', 'direction', 'idathu', 'valathu'];
    return keywords.any((kw) => directionKeywords.contains(kw));
  }
}