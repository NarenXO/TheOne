import 'package:flutter/material.dart';
import 'package:theone/core/models/confidence_state.dart';
import 'package:theone/core/services/speech_input_service.dart';
import '../../services/translation_service.dart';
import '../widgets/confidence_badge.dart';
import '../widgets/mock_banner.dart';

class SpokenReplyScreen extends StatefulWidget {
  const SpokenReplyScreen({super.key});

  @override
  State<SpokenReplyScreen> createState() => _SpokenReplyScreenState();
}

class _SpokenReplyScreenState extends State<SpokenReplyScreen> {
  final _translationService = TranslationService([]);
  SpeechResult? _lastSpeechResult;
  String _translatedText = '';
  bool _isListening = false;
  bool _showTamil = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spoken Reply'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          const MockBanner(message: 'DEMO MODE - Mock Speech Service'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _isListening ? null : _handleListen,
                  icon: _isListening
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.mic),
                  label: Text(_isListening ? 'Listening...' : 'Start Listening'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: _isListening ? Colors.grey : Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                if (_lastSpeechResult != null) _buildTranscriptCard(),
              ],
            ),
          ),
          if (_translatedText.isNotEmpty) _buildTranslationCard(),
        ],
      ),
    );
  }

  Widget _buildTranscriptCard() {
    final result = _lastSpeechResult!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ConfidenceBadge(
                  state: result.confidence >= 0.8 
                      ? ConfidenceState.verified 
                      : ConfidenceState.uncertain,
                  confidence: result.confidence,
                ),
                const Spacer(),
                Chip(
                  label: Text(result.languageCode),
                  backgroundColor: Colors.blue.shade100,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Transcript:',
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
              child: Text(
                result.text,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleTranslate(result.text, result.languageCode),
                    icon: const Icon(Icons.translate),
                    label: const Text('Translate'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // In real app, this would trigger TTS
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Speaking: ${result.text}')),
                      );
                    },
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Speak'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationCard() {
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
                  const Text(
                    'Translation:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _showTamil,
                    onChanged: (value) {
                      setState(() {
                        _showTamil = value;
                      });
                    },
                  ),
                  Text(_showTamil ? 'Tamil' : 'English'),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: Text(
                  _showTamil ? _translatedText : _lastSpeechResult!.text,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Speaking: $_translatedText')),
                  );
                },
                icon: const Icon(Icons.volume_up),
                label: const Text('Speak Translation'),
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

  void _handleListen() {
    setState(() {
      _isListening = true;
      _lastSpeechResult = null;
      _translatedText = '';
    });

    // Simulate speech recognition
    Future.delayed(const Duration(seconds: 3), () {
      final mockResult = SpeechResult(
        text: 'Thank you very much for your help',
        confidence: 0.92,
        languageCode: 'en-US',
      );

      setState(() {
        _lastSpeechResult = mockResult;
        _isListening = false;
      });
    });
  }

  void _handleTranslate(String text, String languageCode) {
    final targetLang = languageCode == 'en-US' ? 'ta' : 'en';
    final result = _translationService.translate(text, fromLanguage: 'en', toLanguage: targetLang);
    
    setState(() {
      _translatedText = result.translatedText;
      _showTamil = targetLang == 'ta';
    });
  }
}
