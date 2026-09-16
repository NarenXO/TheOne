import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import '../../core/evidence/evidence.dart';
import '../../core/models/evidence_source.dart';
import '../../core/models/evidence_type.dart';
import '../../core/services/impl/haptic_service_impl.dart';
import '../../core/services/impl/speech_input_service_impl.dart';
import '../../core/services/impl/tts_service_impl.dart';
import '../../core/storage/preferences_service.dart';
import '../../core/storage/session_storage.dart';
import '../../core/utils/app_logger.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_settings_drawer.dart';

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
  bool _isAmbientDangerActive = false;
  String? _dangerAlertMessage;
  String _activePartialText = "";

  int _currentSpeakerIndex = 1;
  final List<Color> _speakerColors = [
    AppColors.primary,
    AppColors.accent,
    AppColors.info,
    AppColors.success,
  ];

  String _savedUserName = "Naren";

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _initPermissionsAndStartListening();
  }

  Future<void> _initPermissionsAndStartListening() async {
    await Permission.microphone.request();
    if (mounted) {
      _startContinuousListening();
    }
  }

  void _loadUserName() async {
    final name = await PreferencesService.getUserName();
    if (mounted) setState(() => _savedUserName = name);
  }

  @override
  void dispose() {
    _speechService.stop();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _startContinuousListening() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) setState(() => _isListening = false);
      return;
    }

    await _speechService.stop();
    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;
    setState(() {
      _isListening = true;
      _activePartialText = "";
    });

    _runCaptionStreamLoop();
  }

  void _runCaptionStreamLoop() async {
    while (_isListening && mounted) {
      if (!TtsServiceImpl.isSpeaking) {
        await _speechService.startCaptionStream(
          onPartial: (partialText) {
            if (mounted && _isListening) {
              setState(() => _activePartialText = partialText);
              _scrollToBottom();
            }
          },
          onFinal: (finalText, confidence) {
            if (mounted && _isListening && finalText.trim().isNotEmpty) {
              setState(() => _activePartialText = "");
              _processSpeechInput(finalText, confidence);
            }
          },
        );
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  void _stopListening() async {
    setState(() {
      _isListening = false;
      _activePartialText = "";
    });
    await _speechService.stop();
  }

  void _processSpeechInput(String text, double confidence) async {
    final lowerText = text.toLowerCase();
    String tone = "Neutral";
    IconData toneIcon = Icons.sentiment_neutral;

    final urgentKeywords = [
      "help", "stop", "danger", "fire", "alarm", "run", "careful",
      "watch out", "emergency", "shout", "urgent", "fast", "hurry", "no", "don't"
    ];
    final inquisitiveKeywords = [
      "?", "where", "what", "when", "why", "who", "how", "enga",
      "eppo", "edhu", "en", "yaai", "which", "could you"
    ];
    final friendlyKeywords = [
      "thanks", "thank you", "hello", "hi", "good", "please",
      "nandri", "vanakkam", "welcome", "nice", "great"
    ];

    if (urgentKeywords.any((k) => lowerText.contains(k)) || lowerText.contains("!")) {
      tone = "Urgent";
      toneIcon = Icons.warning_amber_rounded;
      _triggerDangerSoundAlert("Urgent alert detected in speech: '$text'");
    } else if (inquisitiveKeywords.any((k) => lowerText.contains(k))) {
      tone = "Inquisitive";
      toneIcon = Icons.help_outline;
    } else if (friendlyKeywords.any((k) => lowerText.contains(k))) {
      tone = "Friendly";
      toneIcon = Icons.sentiment_satisfied_alt;
    }

    // Check if live audio contains user's name
    if (_savedUserName.isNotEmpty && lowerText.contains(_savedUserName.toLowerCase())) {
      AppLogger.w('HEARING', 'NAME CALLED DETECTED: "$text" contains "$_savedUserName"');
      // Double-pulse vibration for name called
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(pattern: [0, 80, 50, 80]);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("📳 Name Called Alert: Someone said '$_savedUserName'"),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
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

    AppLogger.i('HEARING', 'Caption line generated: "$text" (Speaker $_currentSpeakerIndex, Tone: $tone)');

    setState(() {
      _captions.add(newCaption);
      // Alternate speaker heuristically on longer pauses
      if (_captions.length % 3 == 0) {
        _currentSpeakerIndex = _currentSpeakerIndex == 1 ? 2 : 1;
      }
    });

    _scrollToBottom();

    // Light haptic on non-empty captions
    if (text.isNotEmpty) {
      await _hapticService.uncertain();
    }

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
    AppLogger.w('HEARING', 'AMBIENT DANGER DETECTED: $message');
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

  Widget _buildHapticChip(String label, String phrase) {
    return ActionChip(
      avatar: const Icon(Icons.vibration, size: 16, color: AppColors.primary),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      backgroundColor: const Color(0xFFE8EEF7),
      onPressed: () async {
        await _hapticService.vibratePhrase(phrase);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Vibrating: '$label' pattern"),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD5E3F8),
      appBar: AppBar(
        title: const Text("HEARING ASSIST"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => AppSettingsDrawer.show(context),
            tooltip: "Settings",
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
              color: AppColors.danger,
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
          // Active Mic Status Indicator Bar with Tap to Restart
          GestureDetector(
            onTap: _startContinuousListening,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              decoration: BoxDecoration(
                color: _isListening ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _isListening ? Colors.green : Colors.red, width: 2),
              ),
              child: Row(
                children: [
                  Icon(
                    _isListening ? Icons.mic : Icons.mic_off,
                    color: _isListening ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isListening ? "🟢 Mic Active - Listening..." : "🔴 Mic Paused - Tap to Retry",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _isListening ? Colors.green.shade900 : Colors.red.shade900,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    color: _isListening ? Colors.green.shade900 : Colors.red.shade900,
                    tooltip: "Restart Mic",
                    onPressed: _startContinuousListening,
                  ),
                ],
              ),
            ),
          ),
          // Control Toolbar
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isListening ? AppColors.danger : AppColors.primary,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: _isListening ? _stopListening : _startContinuousListening,
                        icon: Icon(_isListening ? Icons.mic_off : Icons.mic, color: Colors.white),
                        label: Text(
                          _isListening ? "STOP CAPTIONS" : "START LIVE CAPTIONS",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _captions.clear()),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text("CLEAR CAPTIONS"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          ),
          // Haptic Vibration Vocabulary
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.vibration, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      "HAPTIC VIBRATION VOCABULARY",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildHapticChip("YES", "yes"),
                    _buildHapticChip("NO", "no"),
                    _buildHapticChip("NAME CALLED", "name"),
                    _buildHapticChip("THANK YOU", "thank"),
                    _buildHapticChip("EXCUSE ME", "excuse"),
                    _buildHapticChip("DANGER", "danger"),
                  ],
                ),
              ],
            ),
          ),
          // Caption Feed List
          Expanded(
            child: (_captions.isEmpty && _activePartialText.isEmpty)
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        "Start live captions to transcribe speech in real time.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _captions.length + (_activePartialText.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < _captions.length) {
                        final item = _captions[index];
                        final isLowConfidence = item.confidence < 0.70;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isLowConfidence ? AppColors.warning : AppColors.border,
                              width: isLowConfidence ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: item.speakerColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: item.speakerColor, width: 1),
                                    ),
                                    child: Text(
                                      item.speakerLabel,
                                      style: TextStyle(
                                        color: item.speakerColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(item.toneIcon, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.toneLabel,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  Text(
                                    "${(item.confidence * 100).toStringAsFixed(0)}%",
                                    style: TextStyle(
                                      color: isLowConfidence ? AppColors.warning : AppColors.textSecondary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.text,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (isLowConfidence)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    "⚠️ Low confidence transcription",
                                    style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w800),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }

                      // Active Partial Live Streaming Card
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.primary, width: 1),
                                  ),
                                  child: const Text(
                                    "LISTENING...",
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.mic, size: 16, color: AppColors.primary),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _activePartialText,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontStyle: FontStyle.italic,
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
    );
  }
}
