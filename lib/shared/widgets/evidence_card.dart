import 'package:flutter/material.dart';
import '../../core/evidence/evidence.dart';
import '../../core/models/confidence_state.dart';

class EvidenceCard extends StatelessWidget {
  final Evidence evidence;
  final ConfidenceState state;

  const EvidenceCard({
    super.key,
    required this.evidence,
    required this.state,
  });

  Color _getStateColor() {
    switch (state) {
      case ConfidenceState.verified:
        return Colors.green;
      case ConfidenceState.uncertain:
        return Colors.amber;
      case ConfidenceState.insufficient:
        return Colors.orange;
      case ConfidenceState.conflict:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateColor = _getStateColor();
    final confidencePct = (evidence.confidence * 100).toStringAsFixed(0);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: stateColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  backgroundColor: stateColor.withValues(alpha: 0.15),
                  side: BorderSide(color: stateColor),
                  label: Text(
                    state.name.toUpperCase(),
                    style: TextStyle(
                      color: stateColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  '$confidencePct% Confidence',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              evidence.value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.sensors, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Source: ${evidence.source.name} (${evidence.type.name})',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
