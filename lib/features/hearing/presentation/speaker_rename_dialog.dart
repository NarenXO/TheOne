import 'package:flutter/material.dart';
import '../domain/models/hearing_speaker.dart';

class SpeakerRenameDialog extends StatefulWidget {
  final List<HearingSpeaker> speakers;
  final Function(String, String) onRename;

  const SpeakerRenameDialog({
    super.key,
    required this.speakers,
    required this.onRename,
  });

  @override
  State<SpeakerRenameDialog> createState() => _SpeakerRenameDialogState();
}

class _SpeakerRenameDialogState extends State<SpeakerRenameDialog> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final speaker in widget.speakers) {
      _controllers[speaker.id] = TextEditingController(text: speaker.customName);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename Speakers'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.speakers.length,
          itemBuilder: (context, index) {
            final speaker = widget.speakers[index];
            return _buildSpeakerRenameRow(speaker);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveRenames,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildSpeakerRenameRow(HearingSpeaker speaker) {
    final controller = _controllers[speaker.id]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Color(speaker.colorValue),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  speaker.defaultLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Enter custom name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _saveRenames() {
    for (final speaker in widget.speakers) {
      final controller = _controllers[speaker.id]!;
      final newName = controller.text.trim();
      if (newName.isNotEmpty) {
        widget.onRename(speaker.id, newName);
      }
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Speaker names updated')),
    );
  }
}
