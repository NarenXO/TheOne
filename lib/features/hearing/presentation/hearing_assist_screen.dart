import 'package:flutter/material.dart';
import '../domain/models/models.dart';
import '../domain/services/services.dart';
import '../data/mock_hearing_services.dart';
import 'hearing_settings_sheet.dart';
import 'caption_history_sheet.dart';
import 'speaker_rename_dialog.dart';

class HearingAssistScreen extends StatefulWidget {
  final bool autoInitializeServices;

  const HearingAssistScreen({
    super.key,
    this.autoInitializeServices = true,
  });

  @override
  State<HearingAssistScreen> createState() => _HearingAssistScreenState();
}

class _HearingAssistScreenState extends State<HearingAssistScreen> {
  final CaptionBuffer _captionBuffer = CaptionBuffer();
  final CaptionHistoryService _historyService = CaptionHistoryService();
  final SpeakerTrackerService _speakerTracker = SpeakerTrackerService();

  final MockSpeechRecognitionService _mockSpeechService = MockSpeechRecognitionService();
  final MockSoundClassifierService _mockSoundService = MockSoundClassifierService();
  final MockSpeakerTrackerService _mockSpeakerService = MockSpeakerTrackerService();
  final MockToneDetectionService _mockToneService = MockToneDetectionService();

  HearingSettings _settings = HearingSettings();
  bool _isFrozen = false;
  bool _showRewind = false;
  bool _useMockServices = true;
  SoundEvent? _latestDangerSound;
  bool _showDangerAlert = true;

  final ScrollController _scrollController = ScrollController();
  final List<TranscriptSegment> _displaySegments = [];

  @override
  void initState() {
    super.initState();
    if (widget.autoInitializeServices) {
      _initializeServices();
    }
  }

  void _initializeServices() {
    if (_useMockServices) {
      _mockSpeechService.transcriptStream.listen((segment) {
        setState(() {
          _captionBuffer.addSegment(segment);
          _historyService.addSegment(segment);
          _speakerTracker.getOrCreateSpeaker(segment.speakerId);
          _speakerTracker.setCurrentSpeaker(segment.speakerId);
          if (!_isFrozen) {
            _displaySegments.add(segment);
            _scrollToBottom();
          }
        });
      });

      _mockSoundService.soundStream.listen((sound) {
        setState(() {
          if (sound.isDanger) {
            _latestDangerSound = sound;
            _showDangerAlert = true;
          }
        });
      });

      _mockSpeakerService.speakerChangeStream.listen((speakerId) {
        setState(() {
          _speakerTracker.setCurrentSpeaker(speakerId);
        });
      });

      _mockSpeechService.startListening();
      _mockSoundService.startClassification();
      _mockSpeakerService.startTracking();
      _mockToneService.startDetection();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleFreeze() {
    setState(() {
      _isFrozen = !_isFrozen;
      if (_isFrozen) {
        _mockSpeechService.freeze();
      } else {
        _mockSpeechService.resume();
        _displaySegments.clear();
        _displaySegments.addAll(_captionBuffer.getLiveStream());
        _scrollToBottom();
      }
    });
  }

  void _toggleRewind() {
    setState(() {
      _showRewind = !_showRewind;
      if (_showRewind) {
        _displaySegments.clear();
        _displaySegments.addAll(_captionBuffer.getRewindSnapshot());
      } else {
        _displaySegments.clear();
        _displaySegments.addAll(_captionBuffer.getLiveStream());
        _scrollToBottom();
      }
    });
  }

  void _dismissDangerAlert() {
    setState(() {
      _showDangerAlert = false;
    });
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => HearingSettingsSheet(
        settings: _settings,
        onSettingsChanged: (newSettings) {
          setState(() {
            _settings = newSettings;
          });
        },
      ),
    );
  }

  void _openHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CaptionHistorySheet(
        historyService: _historyService,
      ),
    );
  }

  void _openSpeakerRename() {
    final speakers = _speakerTracker.getAllSpeakers();
    if (speakers.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => SpeakerRenameDialog(
        speakers: speakers,
        onRename: (speakerId, newName) {
          setState(() {
            _speakerTracker.renameSpeaker(speakerId, newName);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final segments = _showRewind ? _captionBuffer.getRewindSnapshot() : _displaySegments;

    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      appBar: AppBar(
        title: const Text('Hearing Assist'),
        backgroundColor: _getAppBarColor(),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildTopBar(),
          if (_showDangerAlert && _latestDangerSound != null)
            _buildDangerAlertBanner(),
          Expanded(
            child: _buildCaptionView(segments),
          ),
          _buildVisualEvidenceCard(),
          _buildBottomActionBar(),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (_settings.contrastMode) {
      case ContrastMode.transparent:
        return Colors.white;
      case ContrastMode.dark:
        return Colors.black;
      case ContrastMode.highContrast:
        return Colors.black;
    }
  }

  Color _getAppBarColor() {
    switch (_settings.contrastMode) {
      case ContrastMode.transparent:
        return Colors.blue;
      case ContrastMode.dark:
        return Colors.grey[900]!;
      case ContrastMode.highContrast:
        return Colors.black;
    }
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: _getAppBarColor(),
      child: Row(
        children: [
          _buildStatusIndicator(),
          const SizedBox(width: 16),
          Expanded(
            child: _displaySegments.isEmpty
                ? const Text(
                    '...',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          _buildQuickActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final isActive = _mockSpeechService.isListening && !_isFrozen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? '[ MIC ACTIVE ]' : '[ PAUSED / SILENCE ]',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildQuickActionButtons() {
    return Row(
      children: [
        IconButton(
          icon: Icon(_isFrozen ? Icons.play_arrow : Icons.pause),
          onPressed: _toggleFreeze,
          tooltip: _isFrozen ? 'Resume' : 'Freeze',
        ),
        IconButton(
          icon: Icon(_showRewind ? Icons.history : Icons.history_toggle_off),
          onPressed: _toggleRewind,
          tooltip: _showRewind ? 'Live' : '30s Rewind',
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: _openSettings,
          tooltip: 'Settings',
        ),
      ],
    );
  }

  Widget _buildDangerAlertBanner() {
    final sound = _latestDangerSound!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              sound.formattedDescriptionWithConfidence,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _dismissDangerAlert,
          ),
        ],
      ),
    );
  }

  Widget _buildCaptionView(List<TranscriptSegment> segments) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: segments.length,
        itemBuilder: (context, index) {
          final segment = segments[index];
          return _buildCaptionSegment(segment);
        },
      ),
    );
  }

  Widget _buildCaptionSegment(TranscriptSegment segment) {
    final speaker = _speakerTracker.getSpeaker(segment.speakerId);
    final speakerColor = speaker != null ? Color(speaker.colorValue) : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getSegmentBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: speakerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSpeakerBadge(speaker, speakerColor),
          const SizedBox(height: 8),
          _buildCaptionText(segment),
          if (segment.tone != null && _settings.toneDetectionEnabled)
            _buildToneBadge(segment.tone!),
        ],
      ),
    );
  }

  Color _getSegmentBackgroundColor() {
    switch (_settings.contrastMode) {
      case ContrastMode.transparent:
        return Colors.grey[100]!;
      case ContrastMode.dark:
        return Colors.grey[800]!;
      case ContrastMode.highContrast:
        return Colors.white;
    }
  }

  Widget _buildSpeakerBadge(HearingSpeaker? speaker, Color speakerColor) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: speakerColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          speaker?.displayName ?? 'Unknown',
          style: TextStyle(
            color: _getTextColor(),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        if (speaker?.isCurrentSpeaker ?? false) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: speakerColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Speaking Now',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCaptionText(TranscriptSegment segment) {
    final fontSize = _settings.captionFontSize;
    final textColor = _getTextColor();

    if (segment.isLowConfidence) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.yellow.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                segment.text,
                style: TextStyle(
                  fontSize: fontSize,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${(segment.confidence * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      segment.text,
      style: TextStyle(
        fontSize: fontSize,
        color: textColor,
      ),
    );
  }

  Widget _buildToneBadge(ToneInference tone) {
    return GestureDetector(
      onTap: () => _showToneExplanation(tone),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tone.emoji,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 4),
            Text(
              tone.displayName,
              style: TextStyle(
                color: _getTextColor(),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showToneExplanation(ToneInference tone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(tone.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 8),
            Text(tone.displayName),
          ],
        ),
        content: Text(tone.explanationText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getTextColor() {
    switch (_settings.contrastMode) {
      case ContrastMode.transparent:
        return Colors.black;
      case ContrastMode.dark:
        return Colors.white;
      case ContrastMode.highContrast:
        return Colors.black;
    }
  }

  Widget _buildVisualEvidenceCard() {
    if (_displaySegments.isEmpty) return const SizedBox.shrink();

    final latestSegment = _displaySegments.last;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: const Text('Visual Evidence'),
        children: [
          _buildEvidenceRow('Source', 'Microphone'),
          _buildEvidenceRow('Type', 'Speech'),
          _buildEvidenceRow('Value', latestSegment.text),
          _buildEvidenceRow('Confidence', '${(latestSegment.confidence * 100).toStringAsFixed(1)}%'),
          _buildEvidenceRow('Verification', latestSegment.isLowConfidence ? 'Uncertain' : 'Verified'),
        ],
      ),
    );
  }

  Widget _buildEvidenceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getAppBarColor(),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _openHistory,
              icon: const Icon(Icons.history),
              label: const Text('History'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _openSpeakerRename,
              icon: const Icon(Icons.person),
              label: const Text('Rename Speakers'),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text('Mock: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Switch(
                  value: _useMockServices,
                  onChanged: (value) {
                    setState(() {
                      _useMockServices = value;
                      if (value) {
                        _initializeServices();
                      } else {
                        _mockSpeechService.stopListening();
                        _mockSoundService.stopClassification();
                        _mockSpeakerService.stopTracking();
                        _mockToneService.stopDetection();
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mockSpeechService.dispose();
    _mockSoundService.dispose();
    _mockSpeakerService.dispose();
    _mockToneService.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
