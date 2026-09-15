import 'package:flutter/material.dart';
import 'package:theone/core/models/confidence_state.dart';
import 'package:theone/core/services/ocr_service.dart';
import '../../models/intent_result.dart';
import '../../services/menu_matcher_service.dart';
import '../widgets/confidence_badge.dart';
import '../widgets/mock_banner.dart';

class MenuOcrAssistScreen extends StatefulWidget {
  const MenuOcrAssistScreen({super.key});

  @override
  State<MenuOcrAssistScreen> createState() => _MenuOcrAssistScreenState();
}

class _MenuOcrAssistScreenState extends State<MenuOcrAssistScreen> {
  final _menuMatcher = MenuMatcherService();
  List<OcrResult> _ocrResults = [];
  IntentResult? _lastResult;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu OCR Assist'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          const MockBanner(message: 'DEMO MODE - Mock OCR Service'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _handleSimulateOcr,
                  icon: _isProcessing 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.camera_alt),
                  label: Text(_isProcessing ? 'Scanning...' : 'Scan Menu'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Detected Text (${_ocrResults.length} items):',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _ocrResults.isEmpty
                      ? Center(
                          child: Text(
                            'No text detected yet',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _ocrResults.length,
                          itemBuilder: (context, index) {
                            final result = _ocrResults[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Text(
                                    result.text,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${(result.confidence * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
              ConfidenceBadge(
                state: result.state,
                confidence: result.confidence,
              ),
              const SizedBox(height: 16),
              const Text(
                'Suggested Phrase:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
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
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Speaking: ${result.generatedEn}'),
                    ),
                  );
                },
                icon: const Icon(Icons.volume_up),
                label: const Text('Speak Phrase'),
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

  void _handleSimulateOcr() {
    setState(() {
      _isProcessing = true;
      _ocrResults = [];
      _lastResult = null;
    });

    // Simulate OCR processing delay
    Future.delayed(const Duration(seconds: 2), () {
      // Mock OCR results
      final mockResults = [
        OcrResult(text: 'HOT', confidence: 0.95),
        OcrResult(text: 'COFFEE', confidence: 0.92),
        OcrResult(text: 'LARGE', confidence: 0.88),
        OcrResult(text: 'MENU', confidence: 0.85),
      ];

      final result = _menuMatcher.generatePhraseFromOcr(mockResults);

      setState(() {
        _ocrResults = mockResults;
        _lastResult = result;
        _isProcessing = false;
      });
    });
  }
}
