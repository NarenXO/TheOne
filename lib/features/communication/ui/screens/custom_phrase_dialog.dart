import 'package:flutter/material.dart';
import '../../models/phrase_item.dart';

class CustomPhraseDialog extends StatefulWidget {
  final Function(PhraseItem) onPhraseCreated;

  const CustomPhraseDialog({
    super.key,
    required this.onPhraseCreated,
  });

  @override
  State<CustomPhraseDialog> createState() => _CustomPhraseDialogState();
}

class _CustomPhraseDialogState extends State<CustomPhraseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _textEnController = TextEditingController();
  final _textTaController = TextEditingController();
  final _keywordsController = TextEditingController();
  String _selectedCategory = 'custom';

  final List<String> _categories = [
    'custom',
    'emergency',
    'food',
    'greetings',
    'social',
  ];

  @override
  void dispose() {
    _textEnController.dispose();
    _textTaController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Custom Phrase'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _textEnController,
                decoration: const InputDecoration(
                  labelText: 'English Text',
                  hintText: 'Enter phrase in English',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter English text';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _textTaController,
                decoration: const InputDecoration(
                  labelText: 'Tamil Text (Optional)',
                  hintText: 'Enter phrase in Tamil',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    initialValue: category,
                    child: Text(category.capitalize()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _keywordsController,
                decoration: const InputDecoration(
                  labelText: 'Keywords (Optional)',
                  hintText: 'Enter keywords separated by commas',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleCreate,
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _handleCreate() {
    if (_formKey.currentState!.validate()) {
      final keywords = _keywordsController.text
          .split(',')
          .map((k) => k.trim())
          .where((k) => k.isNotEmpty)
          .toList();

      final phrase = PhraseItem(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        category: _selectedCategory,
        textEn: _textEnController.text.trim(),
        textTa: _textTaController.text.trim().isEmpty 
            ? _textEnController.text.trim() 
            : _textTaController.text.trim(),
        keywords: keywords,
        isCustom: true,
      );

      widget.onPhraseCreated(phrase);
      Navigator.pop(context);
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

