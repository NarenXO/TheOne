import 'package:flutter/material.dart';
import '../../models/phrase_item.dart';
import '../widgets/emergency_phrase_bar.dart';
import '../widgets/phrase_action_card.dart';
import '../widgets/category_tab_bar.dart';

class PhraseBoardScreen extends StatefulWidget {
  const PhraseBoardScreen({super.key});

  @override
  State<PhraseBoardScreen> createState() => _PhraseBoardScreenState();
}

class _PhraseBoardScreenState extends State<PhraseBoardScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Emergency',
    'Food',
    'Greetings',
    'Social',
    'Custom',
    'Favorites',
    'Recent',
  ];

  // Mock data - in real app, this would come from repository
  final List<PhraseItem> _mockPhrases = [
    PhraseItem(
      id: 'em_1',
      category: 'emergency',
      textEn: 'I need help immediately.',
      textTa: 'எனக்கு உடனே உதவி தேவை.',
      keywords: ['help', 'emergency'],
    ),
    PhraseItem(
      id: 'fd_1',
      category: 'food',
      textEn: 'I would like a medium chai, please.',
      textTa: 'எனக்கு ஒரு மீடியம் சாய் வேண்டும்.',
      keywords: ['chai', 'tea'],
    ),
    PhraseItem(
      id: 'gr_1',
      category: 'greetings',
      textEn: 'Hello, good morning.',
      textTa: 'வணக்கம், காலை வணக்கம்.',
      keywords: ['hello', 'vanakkam'],
    ),
  ];

  List<PhraseItem> get _filteredPhrases {
    switch (_selectedCategory) {
      case 'All':
        return _mockPhrases;
      case 'Emergency':
        return _mockPhrases.where((p) => p.category == 'emergency').toList();
      case 'Food':
        return _mockPhrases.where((p) => p.category == 'food').toList();
      case 'Greetings':
        return _mockPhrases.where((p) => p.category == 'greetings').toList();
      case 'Social':
        return _mockPhrases.where((p) => p.category == 'social').toList();
      case 'Custom':
        return _mockPhrases.where((p) => p.isCustom).toList();
      case 'Favorites':
        return _mockPhrases.where((p) => p.isFavorite).toList();
      case 'Recent':
        return _mockPhrases.where((p) => p.lastUsedAt != null).toList()
          ..sort((a, b) => b.lastUsedAt!.compareTo(a.lastUsedAt!));
      default:
        return _mockPhrases;
    }
  }

  List<PhraseItem> get _emergencyPhrases {
    return _mockPhrases.where((p) => p.category == 'emergency').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phrase Board'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          EmergencyPhraseBar(
            emergencyPhrases: _emergencyPhrases,
            onPhraseTap: _handlePhraseTap,
          ),
          CategoryTabBar(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onCategorySelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
          ),
          Expanded(
            child: _filteredPhrases.isEmpty
                ? Center(
                    child: Text(
                      'No phrases in $_selectedCategory',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filteredPhrases.length,
                    itemBuilder: (context, index) {
                      final phrase = _filteredPhrases[index];
                      return PhraseActionCard(
                        phrase: phrase,
                        onTap: () => _handlePhraseTap(phrase),
                        onFavoriteToggle: () => _handleFavoriteToggle(phrase),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAddCustomPhrase,
        backgroundColor: Colors.blue.shade700,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _handlePhraseTap(PhraseItem phrase) {
    // In real app, this would trigger TTS
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Speaking: ${phrase.textEn}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleFavoriteToggle(PhraseItem phrase) {
    setState(() {
      phrase.isFavorite = !phrase.isFavorite;
    });
  }

  void _handleAddCustomPhrase() {
    // In real app, this would show custom phrase dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Custom phrase dialog would open here'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}