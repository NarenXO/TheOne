import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SensorIndicator extends StatelessWidget {
  final bool isCameraActive;
  final bool isMicActive;

  const SensorIndicator({
    super.key,
    this.isCameraActive = false,
    this.isMicActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBadge(
            icon: Icons.videocam,
            label: isCameraActive ? 'CAMERA ACTIVE' : 'CAMERA OFF',
            isActive: isCameraActive,
          ),
          Container(width: 1, height: 24, color: Colors.grey.withValues(alpha: 0.4)),
          _buildBadge(
            icon: Icons.mic,
            label: isMicActive ? 'MIC ACTIVE' : 'MIC OFF',
            isActive: isMicActive,
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    final color = isActive ? AppColors.danger : AppColors.success;
    return Semantics(
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
