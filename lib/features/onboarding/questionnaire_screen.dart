import 'package:flutter/material.dart';
import '../../shared/widgets/big_button.dart';
import 'recommendation_screen.dart';

class QuestionnaireScreen extends StatelessWidget {
  const QuestionnaireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What type of assistance would help you most?',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'We will recommend a starting mode. You can switch modes at any time.',
                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    BigButton(
                      label: 'Visual Assistance',
                      icon: Icons.remove_red_eye,
                      backgroundColor: Colors.indigo[700],
                      onPressed: () => _recommend(context, 'Vision Assist'),
                    ),
                    const SizedBox(height: 16),
                    BigButton(
                      label: 'Hearing Assistance',
                      icon: Icons.hearing,
                      backgroundColor: Colors.teal[700],
                      onPressed: () => _recommend(context, 'Hearing Assist'),
                    ),
                    const SizedBox(height: 16),
                    BigButton(
                      label: 'Communication Assistance',
                      icon: Icons.record_voice_over,
                      backgroundColor: Colors.deepOrange[700],
                      onPressed: () => _recommend(context, 'Communication Assist'),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => _recommend(context, null),
                      child: const Text(
                        "I'll choose myself later",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _recommend(BuildContext context, String? mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecommendationScreen(recommendedMode: mode),
      ),
    );
  }
}
