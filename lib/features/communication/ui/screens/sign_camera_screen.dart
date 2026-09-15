import 'package:theone/core/models/confidence_state.dart';
import 'package:flutter/material.dart';
import '../../models/sign_recognition_candidate.dart';
import '../../services/mock_communication_services.dart';
import '../widgets/confidence_badge.dart';
import '../widgets/mock_banner.dart';

class SignCameraScreen extends StatefulWidget {
  const SignCameraScreen({super.key});

  @override
  State<SignCameraScreen> createState() => _SignCameraScreenState();
}

class _SignCameraScreenState extends State<SignCameraScreen> {
  final MockSignRecognitionService _recognitionService = MockSignRecognitionService();
  SignRecognitionCandidate? _lastCandidate;
  bool _isRecognizing = false;
  final List<String> _feedbackHistory = [];

  @override
  void dispose() {
    _recognitionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Recognition'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          const MockBanner(message: 'DEMO MODE - Mock Hand Tracking'),
          // Camera preview placeholder
          Expanded(
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  // Camera placeholder
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 80,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isRecognizing ? 'Tracking hand...' : 'Camera preview',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Feedback overlay
                  if (_feedbackHistory.isNotEmpty)
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _feedbackHistory.take(3).map((feedback) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                feedback,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Recognition controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isRecognizing ? _stopRecognition : _startRecognition,
                        icon: Icon(_isRecognizing ? Icons.stop : Icons.play_arrow),
                        label: Text(_isRecognizing ? 'Stop' : 'Start Recognition'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRecognizing ? Colors.red : Colors.green,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_lastCandidate != null) ...[
                  const SizedBox(height: 16),
                  _buildCandidateCard(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateCard() {
    final candidate = _lastCandidate!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    candidate.signName.isNotEmpty 
                        ? 'Detected: ${candidate.signName}' 
                        : 'No sign detected',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (candidate.confidence > 0)
                  ConfidenceBadge(
                    state: candidate.confidence >= 0.7 
                        ? ConfidenceState.verified 
                        : ConfidenceState.uncertain,
                    confidence: candidate.confidence,
                  ),
              ],
            ),
            if (candidate.feedbackPrompt != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        candidate.feedbackPrompt!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _startRecognition() async {
    setState(() {
      _isRecognizing = true;
      _lastCandidate = null;
      _feedbackHistory.clear();
    });

    await _recognitionService.startRecognition();

    _recognitionService.streamPredictions().listen((candidate) {
      if (mounted) {
        setState(() {
          _lastCandidate = candidate;
          if (candidate.feedbackPrompt != null) {
            _feedbackHistory.insert(0, candidate.feedbackPrompt!);
            if (_feedbackHistory.length > 5) {
              _feedbackHistory.removeLast();
            }
          }
        });
      }
    });
  }

  void _stopRecognition() async {
    await _recognitionService.stopRecognition();
    setState(() {
      _isRecognizing = false;
    });
  }
}
