import 'package:flutter/material.dart';

class AccessibleButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? height;
  final bool enabled;

  const AccessibleButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.height,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? 58.0; // Minimum 58dp for accessibility
    final effectiveBackgroundColor = backgroundColor ?? 
        (enabled ? Theme.of(context).primaryColor : Colors.grey.shade400);
    final effectiveForegroundColor = foregroundColor ?? Colors.white;

    return SizedBox(
      height: effectiveHeight,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBackgroundColor,
          foregroundColor: effectiveForegroundColor,
          disabledBackgroundColor: Colors.grey.shade400,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: Size(double.infinity, effectiveHeight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}