import 'package:flutter/material.dart';
import '../../core/evidence/evidence.dart';
import '../../core/models/confidence_state.dart';
import '../theme/app_theme.dart';

class EvidenceCard extends StatelessWidget {
  final Evidence evidence;
  final ConfidenceState state;

  const EvidenceCard({
    super.key,
    required this.evidence,
    required this.state,
  });

  Color _stateColor() {
    switch (state) {
      case ConfidenceState.verified:
        return AppColors.success;
      case ConfidenceState.uncertain:
        return AppColors.warning;
      case ConfidenceState.insufficient:
        return AppColors.textSecondary;
      case ConfidenceState.conflict:
        return AppColors.danger;
    }
  }

  IconData _stateIcon() {
    switch (state) {
      case ConfidenceState.verified:
        return Icons.verified;
      case ConfidenceState.uncertain:
        return Icons.help_outline;
      case ConfidenceState.insufficient:
        return Icons.visibility_off;
      case ConfidenceState.conflict:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _stateColor();
    final pct = (evidence.confidence * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_stateIcon(), color: c, size: 18),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  state.name.toUpperCase(),
                  style: TextStyle(
                    color: c,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            evidence.value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Source: ${evidence.source.name}  •  Type: ${evidence.type.name}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
