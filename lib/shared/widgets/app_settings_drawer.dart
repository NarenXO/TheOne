import 'package:flutter/material.dart';
import '../../core/services/impl/tts_service_impl.dart';
import '../../core/storage/preferences_service.dart';
import '../../core/storage/session_storage.dart';
import '../theme/app_theme.dart';

class AppSettingsDrawer extends StatefulWidget {
  final VoidCallback? onSettingsChanged;

  const AppSettingsDrawer({super.key, this.onSettingsChanged});

  static void show(BuildContext context, {VoidCallback? onSettingsChanged}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppSettingsDrawer(onSettingsChanged: onSettingsChanged),
    );
  }

  @override
  State<AppSettingsDrawer> createState() => _AppSettingsDrawerState();
}

class _AppSettingsDrawerState extends State<AppSettingsDrawer> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _sosController = TextEditingController();
  final SessionStorage _sessionStorage = SessionStorage();
  final TtsServiceImpl _ttsService = TtsServiceImpl();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final name = await PreferencesService.getUserName();
    final sos = await PreferencesService.getSosContact();
    if (mounted) {
      setState(() {
        _nameController.text = name;
        _sosController.text = sos;
      });
    }
  }

  void _saveSettings() async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await PreferencesService.completeOnboarding(
      _nameController.text.trim(),
      await PreferencesService.getUserMode(),
    );
    await PreferencesService.setSosContact(_sosController.text.trim());
    await _ttsService.speak("Settings saved. Name updated to ${_nameController.text}.");
    if (widget.onSettingsChanged != null) widget.onSettingsChanged!();
    if (!mounted) return;
    Navigator.pop(context);
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text("Settings saved successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.settings, color: AppColors.primary, size: 28),
              const SizedBox(width: 10),
              const Text("TheOne Settings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: "Your Name (for 'Name Called' vibration)",
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sosController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: "Emergency Contact Phone Number",
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text("SAVE SETTINGS"),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              await _sessionStorage.clearSession();
              navigator.pop();
              messenger.showSnackBar(
                const SnackBar(content: Text("SQLite session history cleared")),
              );
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text("CLEAR SESSION MEMORY"),
          ),
        ],
      ),
    );
  }
}
