import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/evidence/evidence.dart';
import '../../core/models/evidence_source.dart';
import '../../core/models/evidence_type.dart';
import '../../core/services/impl/haptic_service_impl.dart';
import '../../core/services/impl/speech_input_service_impl.dart';
import '../../core/storage/session_storage.dart';

class CaptionLine {
  final String id;
  final String text;
  final double confidence;
  final String speakerLabel;
  final Color speakerColor;
  final String toneLabel;
  final IconData toneIcon;
  final DateTime timestamp;

  CaptionLine({
    required this.id,
    required this.text,
    required this.confidence,
    required this.speakerLabel,
    required this.speakerColor,
    required this.toneLabel,
    required this.toneIcon,
    required this.timestamp,
  });
}

class HearingScreen extends StatefulWidget {
  const HearingScreen({super.key});

  @override
  State<HearingScreen> createState() => _HearingScreenState();
}

class _HearingScreenState extends State<HearingScreen> {
  final SpeechInputServiceImpl _speechService = SpeechInputServiceImpl();
  final HapticServiceImpl _hapticService = HapticServiceImpl();
  final SessionStorage _sessionStorage = SessionStorage();

  final List<CaptionLine> _captions = [];
  final ScrollController _scrollController = ScrollController();

  bool _isListening = false;
  bool _isPaused = false;
  bool _isAmbientDangerActive = false;
  String? _dangerAlertMessage;

  int _currentSpeakerIndex = 1;
  final List<Color> _speakerColors = [
    Colors.deepPurple,
    Colors.teal,
    Colors.indigo,
    Colors.orange,
  ];

  @override
  void dispose() {
    _speechService.stop();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients && !_isPaused) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _startContinuousListening() async {
    if (_isListening) return;

    setState(() => _isListening = true);

    while (_isListening && mounted) {
      if (!_isPaused) {
        final speechResult = await _speechService.listen();
        if (speechResult.text.trim().isNotEmpty) {
          _processSpeechInput(speechResult.text, speechResult.confidence);
        }
      } else {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  void _stopListening() async {
    setState(() => _isListening = false);
    await _speechService.stop();
  }

  void _processSpeechInput(String text, double confidence) async {
    String tone = "Neutral";
    IconData toneIcon = Icons.sentiment_neutral;
    final lower = text.toLowerCase();
    
    if (lower.contains("!") || lower.contains("help") || lower.contains("stop") || lower.contains("danger") || lower.contains("fire") || lower.contains("emergency")) {
      tone = "Urgent";
      toneIcon = Icons.warning_amber_rounded;
      _triggerDangerSoundAlert("Urgent sound / shout detected: '$text'");
    } else if (lower.contains("hello") || lower.contains("thanks") || lower.contains("good") || lower.contains("vanakkam")) {
      tone = "Friendly";
      toneIcon = Icons.sentiment_satisfied_alt;
    }

    final newCaption = CaptionLine(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      confidence: confidence,
      speakerLabel: "Speaker $_currentSpeakerIndex",
      speakerColor: _speakerColors[(_currentSpeakerIndex - 1) % _speakerColors.length],
      toneLabel: tone,
      toneIcon: toneIcon,
      timestamp: DateTime.now(),
    );

    setState(() {
      _captions.add(newCaption);
      if (_captions.length % 3 == 0) {
        _currentSpeakerIndex = _currentSpeakerIndex == 1 ? 2 : 1;
      }
    });

    _scrollToBottom();

    final evidence = Evidence(
      source: EvidenceSource.microphone,
      type: EvidenceType.speech,
      value: text,
      confidence: confidence,
      metadata: {'tone': tone, 'speaker': "Speaker $_currentSpeakerIndex"},
    );

    await _sessionStorage.saveEvidence(evidence);
  }

  void _triggerDangerSoundAlert(String message) async {
    setState(() {
      _isAmbientDangerActive = true;
      _dangerAlertMessage = message;
    });

    await _hapticService.warning();

    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isAmbientDangerActive = false;
          _dangerAlertMessage = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hearing Assist"),
        actions: [
          IconButton(
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: () => setState(() => _isPaused = !_isPaused),
            tooltip: _isPaused ? "Resume Captions" : "Freeze / Pause Captions",
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () => setState(() => _captions.clear()),
            tooltip: "Clear Captions",
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isAmbientDangerActive && _dangerAlertMessage != null)
            Container(
              width: double.infinity,
              color: Colors.red[900],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dangerAlertMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isListening ? Colors.red[800] : Colors.teal[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isListening ? _stopListening : _startContinuousListening,
                    icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                    label: Text(
                      _isListening ? "Stop Captions" : "Start Live Captions",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _captions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.hearing, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _isListening
                              ? "Listening for speech..."
                              : "Tap 'Start Live Captions' to stream real-time spoken captions.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _captions.length,
                    itemBuilder: (context, index) {
                      final item = _captions[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: item.speakerColor.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: item.speakerColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      item.speakerLabel,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: item.speakerColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(item.toneIcon, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.toneLabel,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.text,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
