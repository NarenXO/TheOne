import 'package:theone/core/models/confidence_state.dart';
import 'package:flutter/material.dart';
import '../../models/sign_entry.dart';
import '../../models/sign_recognition_candidate.dart';
import '../../services/mock_communication_services.dart';
import '../widgets/confidence_badge.dart';
import '../widgets/mock_banner.dart';

class PracticeModeScreen extends StatefulWidget {
  final SignEntry sign;

  const PracticeModeScreen({
    super.key,
    required this.sign,
  });

  @override
  State<PracticeModeScreen> createState() => _PracticeModeScreenState();
}

class _PracticeModeScreenState extends State<PracticeModeScreen> {
  final MockSignRecognitionService _recognitionService = MockSignRecognitionService();
  SignRecognitionCandidate? _lastCandidate;
  bool _isPracticing = false;
  int _matchCount = 0;
  final List<String> _feedbackMessages = [];

  @override
  void dispose() {
    _recognitionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Practice: ${widget.sign.nameEn}'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          const MockBanner(message: 'DEMO MODE - Practice Tracking'),
          // Split view
          Expanded(
            child: Row(
              children: [
                // Reference sign (left side)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey.shade100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reference Sign',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.video_library,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.sign.nameEn,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.sign.nameTa,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.sign.description,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                // Camera tracking (right side)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.black,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Hand',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade700),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _isPracticing 
                                            ? Icons.camera_alt 
                                            : Icons.camera_front,
                                        size: 60,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _isPracticing ? 'Tracking...' : 'Start practicing',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Feedback chips overlay
                                if (_feedbackMessages.isNotEmpty)
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    right: 8,
                                    child: Column(
                                      children: _feedbackMessages.take(3).map((message) {
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 4),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getFeedbackColor(message),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            message,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Controls and stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Matches', _matchCount.toString(), Colors.green),
                    _buildStatItem('Target', widget.sign.nameEn, Colors.blue),
                  ],
                ),
                const SizedBox(height: 16),
                if (_lastCandidate != null) _buildCandidateRow(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isPracticing ? _stopPractice : _startPractice,
                        icon: Icon(_isPracticing ? Icons.stop : Icons.play_arrow),
                        label: Text(_isPracticing ? 'Stop Practice' : 'Start Practice'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isPracticing ? Colors.red : Colors.green,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCandidateRow() {
    final candidate = _lastCandidate!;
    
    return Row(
      children: [
        Expanded(
          child: Text(
            candidate.signName.isNotEmpty 
                ? 'Detected: ${candidate.signName}' 
                : 'Detecting...',
            style: const TextStyle(
              fontSize: 14,
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
    );
  }

  Color _getFeedbackColor(String message) {
    if (message.contains('Matched')) return Colors.green;
    if (message.contains('steady')) return Colors.orange;
    if (message.contains('Try again')) return Colors.red;
    return Colors.blue;
  }

  void _startPractice() async {
    setState(() {
      _isPracticing = true;
      _lastCandidate = null;
      _feedbackMessages.clear();
      _matchCount = 0;
    });

    await _recognitionService.startRecognition();

    _recognitionService.streamPredictions().listen((candidate) {
      if (mounted) {
        setState(() {
          _lastCandidate = candidate;
          
          // Generate feedback based on candidate
          if (candidate.signName == widget.sign.nameEn && candidate.confidence >= 0.7) {
            _matchCount++;
            _feedbackMessages.insert(0, 'Matched: ${(candidate.confidence * 100).toStringAsFixed(0)}%');
          } else if (candidate.feedbackPrompt != null) {
            _feedbackMessages.insert(0, candidate.feedbackPrompt!);
          } else if (candidate.confidence < 0.5) {
            _feedbackMessages.insert(0, 'Try again');
          } else {
            _feedbackMessages.insert(0, 'Hand detected');
          }
          
          if (_feedbackMessages.length > 5) {
            _feedbackMessages.removeLast();
          }
        });
      }
    });
  }

  void _stopPractice() async {
    await _recognitionService.stopRecognition();
    setState(() {
      _isPracticing = false;
    });
  }
}
