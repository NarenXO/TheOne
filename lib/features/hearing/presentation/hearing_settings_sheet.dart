// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../domain/models/hearing_settings.dart';

class HearingSettingsSheet extends StatefulWidget {
  final HearingSettings settings;
  final Function(HearingSettings) onSettingsChanged;

  const HearingSettingsSheet({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<HearingSettingsSheet> createState() => _HearingSettingsSheetState();
}

class _HearingSettingsSheetState extends State<HearingSettingsSheet> {
  late HearingSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Hearing Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCaptionSizeSelector(),
          const SizedBox(height: 24),
          _buildContrastModeSelector(),
          const SizedBox(height: 24),
          _buildToggleSection(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCaptionSizeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Caption Size',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...CaptionSize.values.map((size) {
          return RadioListTile<CaptionSize>(
            title: Text(_getCaptionSizeLabel(size)),
            subtitle: Text('${_settings.captionFontSize.toInt()}sp'),
            value: size,
            groupValue: _settings.captionSize,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _settings = _settings.copyWith(captionSize: value);
                  widget.onSettingsChanged(_settings);
                });
              }
            },
          );
        }),
      ],
    );
  }

  String _getCaptionSizeLabel(CaptionSize size) {
    switch (size) {
      case CaptionSize.small:
        return 'Small';
      case CaptionSize.medium:
        return 'Medium';
      case CaptionSize.large:
        return 'Large';
      case CaptionSize.extraLarge:
        return 'Extra Large';
    }
  }

  Widget _buildContrastModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contrast Mode',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...ContrastMode.values.map((mode) {
          return RadioListTile<ContrastMode>(
            title: Text(_getContrastModeLabel(mode)),
            value: mode,
            groupValue: _settings.contrastMode,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _settings = _settings.copyWith(contrastMode: value);
                  widget.onSettingsChanged(_settings);
                });
              }
            },
          );
        }),
      ],
    );
  }

  String _getContrastModeLabel(ContrastMode mode) {
    switch (mode) {
      case ContrastMode.transparent:
        return 'Transparent';
      case ContrastMode.dark:
        return 'Dark';
      case ContrastMode.highContrast:
        return 'High Contrast';
    }
  }

  Widget _buildToggleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Features',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Sound Alerts'),
          subtitle: const Text('Show alerts for danger sounds'),
          value: _settings.soundAlertsEnabled,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(soundAlertsEnabled: value);
              widget.onSettingsChanged(_settings);
            });
          },
        ),
        SwitchListTile(
          title: const Text('Tone Detection'),
          subtitle: const Text('Detect and display tone indicators'),
          value: _settings.toneDetectionEnabled,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(toneDetectionEnabled: value);
              widget.onSettingsChanged(_settings);
            });
          },
        ),
        SwitchListTile(
          title: const Text('Speaker Tracking'),
          subtitle: const Text('Track and identify different speakers'),
          value: _settings.speakerTrackingEnabled,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(speakerTrackingEnabled: value);
              widget.onSettingsChanged(_settings);
            });
          },
        ),
        SwitchListTile(
          title: const Text('Haptic Alerts'),
          subtitle: const Text('Vibrate for important events'),
          value: _settings.hapticAlertsEnabled,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(hapticAlertsEnabled: value);
              widget.onSettingsChanged(_settings);
            });
          },
        ),
      ],
    );
  }
}
