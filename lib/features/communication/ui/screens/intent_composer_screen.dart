import 'package:flutter/material.dart';

import '../../models/intent_result.dart';
import '../../services/intent_parser_service.dart';
import '../widgets/confidence_badge.dart';
import '../widgets/mock_banner.dart';

class IntentComposerScreen extends StatefulWidget {
  const IntentComposerScreen({super.key});

  @override
  State<IntentComposerScreen> createState() => _IntentComposerScreenState();
}

class _IntentComposerScreenState extends State<IntentComposerScreen> {
  final _textController = TextEditingController();
  final _intentParser = IntentParserService();
  IntentResult? _lastResult;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intent Composer'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          const MockBanner(message: 'DEMO MODE - Deterministic Intent Parser'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Type your message (Tanglish/English/Tamil):',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'e.g., "medium chai venum" or "registration enga irukku"',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _handleParse,
                    ),
                  ),
                  onSubmitted: (_) => _handleParse(),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _handleParse,
                  icon: const Icon(Icons.translate),
                  label: const Text('Parse Intent'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
          if (_lastResult != null) _buildResultCard(),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _lastResult!;
    
    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ConfidenceBadge(
                    state: result.state,
                    confidence: result.confidence,
                  ),
                  const Spacer(),
                  Chip(
                    label: Text(
                      result.intent.toString().split('.').last.toUpperCase(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.blue.shade100,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Generated Sentence:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.generatedEn,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.generatedTa,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (result.target != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Target: ${result.target}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // In real app, this would trigger TTS
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Speaking: ${result.generatedEn}'),
                    ),
                  );
                },
                icon: const Icon(Icons.volume_up),
                label: const Text('Speak Result'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleParse() {
    final input = _textController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text')),
      );
      return;
    }

    final result = _intentParser.parse(input);
    setState(() {
      _lastResult = result;
    });
  }
}
