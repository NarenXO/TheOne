import 'package:flutter/material.dart';
import '../../../core/models/confidence_state.dart';

class ConfidenceBadge extends StatelessWidget {
  final ConfidenceState state;
  final double? confidence;
  final String? message;

  const ConfidenceBadge({
    super.key,
    required this.state,
    this.confidence,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            size: 16,
            color: _getTextColor(),
          ),
          const SizedBox(width: 6),
          Text(
            _getText(),
            style: TextStyle(
              color: _getTextColor(),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          if (confidence != null) ...[
            const SizedBox(width: 8),
            Text(
              '${(confidence! * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: _getTextColor(),
                fontWeight: FontWeight.normal,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (state) {
      case ConfidenceState.verified:
        return Colors.green.shade100;
      case ConfidenceState.uncertain:
        return Colors.orange.shade100;
      case ConfidenceState.insufficient:
        return Colors.red.shade100;
      case ConfidenceState.conflict:
        return Colors.purple.shade100;
    }
  }

  Color _getBorderColor() {
    switch (state) {
      case ConfidenceState.verified:
        return Colors.green.shade600;
      case ConfidenceState.uncertain:
        return Colors.orange.shade600;
      case ConfidenceState.insufficient:
        return Colors.red.shade600;
      case ConfidenceState.conflict:
        return Colors.purple.shade600;
    }
  }

  Color _getTextColor() {
    switch (state) {
      case ConfidenceState.verified:
        return Colors.green.shade800;
      case ConfidenceState.uncertain:
        return Colors.orange.shade800;
      case ConfidenceState.insufficient:
        return Colors.red.shade800;
      case ConfidenceState.conflict:
        return Colors.purple.shade800;
    }
  }

  IconData _getIcon() {
    switch (state) {
      case ConfidenceState.verified:
        return Icons.check_circle;
      case ConfidenceState.uncertain:
        return Icons.help_outline;
      case ConfidenceState.insufficient:
        return Icons.error_outline;
      case ConfidenceState.conflict:
        return Icons.warning_amber;
    }
  }

  String _getText() {
    if (message != null && message!.isNotEmpty) {
      return message!;
    }
    
    switch (state) {
      case ConfidenceState.verified:
        return 'Verified';
      case ConfidenceState.uncertain:
        return 'Uncertain';
      case ConfidenceState.insufficient:
        return 'Insufficient';
      case ConfidenceState.conflict:
        return 'Conflict';
    }
  }
}