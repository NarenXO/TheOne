import 'package:flutter/material.dart';

class MockBanner extends StatelessWidget {
  final String message;

  const MockBanner({
    super.key,
    this.message = 'DEMO / MOCK MODE',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.amber.shade600,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
