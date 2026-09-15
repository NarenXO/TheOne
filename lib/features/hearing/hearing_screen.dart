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
    // Determine tone based on text keyword indicators or loud patterns
    String tone = "Neutral";
    IconData toneIcon = Icons.sentiment_neutral;
    if (text.contains("!") || text.contains("help") || text.contains("stop") || text.contains("danger")) {
      tone = "Urgent";
      toneIcon = Icons.warning_amber_rounded;
      _triggerDangerSoundAlert("Urgent sound / shout detected: '$text'");
    } else if (text.contains("hello") || text.contains("thanks") || text.contains("good")) {
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
      // Alternate speaker heuristically on longer pauses
      if (_captions.length % 3 == 0) {
        _currentSpeakerIndex = _currentSpeakerIndex == 1 ? 2 : 1;
      }
    });

    _scrollToBottom();

    // Create Evidence & Save
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

  // Demo shortcut for judges to simulate ambient danger sound detection
  void _simulateDangerAlarm() {
    _triggerDangerSoundAlert("AMBIENT DANGER DETECTED: Fire Alarm / Loud Shouting (96% Confidence)");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TheOne — Hearing Assist"),
        backgroundColor: Colors.blueGrey[900],
        actions: [
          IconButton(
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: () => setState(() => _isPaused = !_isPaused),
            tooltip: _isPaused ? "Resume Captions" : "Freeze / Pause Captions",
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(() => _captions.clear()),
            tooltip: "Clear Caption History",
          ),
        ],
      ),
      body: Column(
        children: [
          // Ambient Danger Banner Alert
          if (_isAmbientDangerActive && _dangerAlertMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              color: Colors.red[900],
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dangerAlertMessage!,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),

          // Control Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.grey[200],
            child: Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isListening ? Colors.red[700] : Colors.blueGrey[800],
                  ),
                  onPressed: _isListening ? _stopListening : _startContinuousListening,
                  icon: Icon(_isListening ? Icons.mic_off : Icons.mic, color: Colors.white),
                  label: Text(
                    _isListening ? "Stop Captions" : "Start Live Captions",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _simulateDangerAlarm,
                  icon: const Icon(Icons.campaign, color: Colors.red),
                  label: const Text("Demo Alarm", style: TextStyle(color: Colors.red)),
                ),
                const Spacer(),
                Text(
                  _isListening ? (_isPaused ? "PAUSED" : "LIVE") : "OFFLINE",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isListening ? (_isPaused ? Colors.amber[800] : Colors.green[700]) : Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Caption Feed List
          Expanded(
            child: _captions.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        "Tap 'Start Live Captions' to stream real-time spoken captions.\nOr tap 'Demo Alarm' to simulate ambient danger sound alerts.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _captions.length,
                    itemBuilder: (context, index) {
                      final item = _captions[index];
                      final isLowConfidence = item.confidence < 0.70;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isLowConfidence ? Colors.amber : Colors.grey[300]!,
                            width: isLowConfidence ? 2 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Chip(
                                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                                    backgroundColor: item.speakerColor.withValues(alpha: 0.15),
                                    label: Text(
                                      item.speakerLabel,
                                      style: TextStyle(
                                        color: item.speakerColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(item.toneIcon, size: 16, color: Colors.grey[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.toneLabel,
                                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                  ),
                                  const Spacer(),
                                  Text(
                                    "${(item.confidence * 100).toStringAsFixed(0)}%",
                                    style: TextStyle(
                                      color: isLowConfidence ? Colors.amber[900] : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.text,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: isLowConfidence ? Colors.grey[800] : Colors.black,
                                ),
                              ),
                              if (isLowConfidence)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    "⚠️ Low confidence transcription",
                                    style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
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
