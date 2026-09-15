import 'package:flutter/material.dart';
import '../../core/storage/preferences_service.dart';
import '../../core/storage/session_storage.dart';
import '../theme/app_theme.dart';

class AppSettingsDrawer extends StatelessWidget {
  const AppSettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFD5E3F8),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Icon(Icons.settings, size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              "Settings",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("User Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const SizedBox(height: 16),
                    FutureBuilder<String>(
                      future: PreferencesService.getUserName(),
                      builder: (context, snapshot) {
                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text("Your Name"),
                          subtitle: Text(snapshot.data ?? 'Loading...'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditNameDialog(context, snapshot.data ?? ''),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    FutureBuilder<String>(
                      future: PreferencesService.getUserMode(),
                      builder: (context, snapshot) {
                        return ListTile(
                          leading: const Icon(Icons.visibility),
                          title: const Text("Primary Mode"),
                          subtitle: Text(snapshot.data ?? 'Loading...'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showModeSelector(context, snapshot.data ?? 'vision'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Emergency", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.danger)),
                    const SizedBox(height: 16),
                    FutureBuilder<String>(
                      future: PreferencesService.getSosContact(),
                      builder: (context, snapshot) {
                        return ListTile(
                          leading: const Icon(Icons.phone, color: AppColors.danger),
                          title: const Text("SOS Contact"),
                          subtitle: Text(snapshot.data ?? '911'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditSosDialog(context, snapshot.data ?? '911'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text("Clear Session Data"),
                subtitle: const Text("Remove all evidence and captions"),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await SessionStorage().clearSession();
                  if (context.mounted) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text("Session data cleared")),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Your Name"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await PreferencesService.completeOnboarding(controller.text, await PreferencesService.getUserMode());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showEditSosDialog(BuildContext context, String currentContact) {
    final controller = TextEditingController(text: currentContact);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit SOS Contact"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await PreferencesService.setSosContact(controller.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showModeSelector(BuildContext context, String currentMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Primary Mode"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Vision Assist"),
              trailing: currentMode == 'vision' ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () async {
                await PreferencesService.completeOnboarding(await PreferencesService.getUserName(), 'vision');
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("Hearing Assist"),
              trailing: currentMode == 'hearing' ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () async {
                await PreferencesService.completeOnboarding(await PreferencesService.getUserName(), 'hearing');
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("Communication Assist"),
              trailing: currentMode == 'communication' ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () async {
                await PreferencesService.completeOnboarding(await PreferencesService.getUserName(), 'communication');
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
