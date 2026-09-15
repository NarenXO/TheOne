import 'package:flutter/material.dart';
import 'package:theone/features/communication/models/phrase_item.dart';

class EmergencyPhraseBar extends StatelessWidget {
  final List<PhraseItem> emergencyPhrases;
  final Function(PhraseItem) onPhraseTap;

  const EmergencyPhraseBar({
    super.key,
    required this.emergencyPhrases,
    required this.onPhraseTap,
  });

  @override
  Widget build(BuildContext context) {
    if (emergencyPhrases.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: emergencyPhrases.length,
        itemBuilder: (context, index) {
          final phrase = emergencyPhrases[index];
          return _EmergencyPhraseButton(
            phrase: phrase,
            onTap: () => onPhraseTap(phrase),
          );
        },
      ),
    );
  }
}

class _EmergencyPhraseButton extends StatelessWidget {
  final PhraseItem phrase;
  final VoidCallback onTap;

  const _EmergencyPhraseButton({
    required this.phrase,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(0, 64),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              phrase.textEn,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              phrase.textTa,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
