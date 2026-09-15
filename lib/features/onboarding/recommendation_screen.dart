import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/services/settings_service.dart';
import '../../shared/widgets/big_button.dart';
import '../../shared/widgets/app_shell.dart';

class RecommendationScreen extends StatelessWidget {
  final String? recommendedMode;

  const RecommendationScreen({super.key, this.recommendedMode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mode = recommendedMode ?? 'Vision Assist';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 20),
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      size: 50,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Recommendation',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Based on your preference, we recommend:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getModeIcon(mode),
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          mode,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'You can switch modes or customize this anytime in Settings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              Column(
                children: [
                  BigButton(
                    label: 'Use $mode',
                    icon: Icons.check,
                    onPressed: () => _finishOnboarding(context, mode),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _finishOnboarding(context, null),
                    child: const Text(
                      'Choose another mode',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getModeIcon(String mode) {
    switch (mode) {
      case 'Vision Assist':
        return Icons.remove_red_eye;
      case 'Hearing Assist':
        return Icons.hearing;
      case 'Communication Assist':
        return Icons.record_voice_over;
      default:
        return Icons.accessibility;
    }
  }

  void _finishOnboarding(BuildContext context, String? chosenMode) async {
    final settings = Provider.of<SettingsService>(context, listen: false);
    await settings.setPreferredMode(chosenMode);
    await settings.setOnboardingComplete(true);

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AppShell()),
        (route) => false,
      );
    }
  }
}
