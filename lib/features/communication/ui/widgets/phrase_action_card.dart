import 'package:flutter/material.dart';
import 'package:theone/core/models/confidence_state.dart';
import 'package:theone/features/communication/models/phrase_item.dart';

class PhraseActionCard extends StatelessWidget {
  final PhraseItem phrase;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final bool showFavorite;

  const PhraseActionCard({
    super.key,
    required this.phrase,
    required this.onTap,
    this.onFavoriteToggle,
    this.showFavorite = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          phrase.textEn,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          phrase.textTa,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showFavorite && onFavoriteToggle != null)
                    IconButton(
                      icon: Icon(
                        phrase.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: phrase.isFavorite ? Colors.red : Colors.grey,
                      ),
                      onPressed: onFavoriteToggle,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              if (phrase.usageCount > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Used ${phrase.usageCount} time${phrase.usageCount == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
