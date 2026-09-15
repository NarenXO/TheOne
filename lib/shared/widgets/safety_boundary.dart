import 'package:flutter/material.dart';
import 'error_card.dart';

class SafetyBoundary extends StatefulWidget {
  final Widget child;
  final String moduleName;

  const SafetyBoundary({
    super.key,
    required this.child,
    required this.moduleName,
  });

  static Widget wrap(Widget child, String moduleName) {
    return SafetyBoundary(moduleName: moduleName, child: child);
  }

  @override
  State<SafetyBoundary> createState() => _SafetyBoundaryState();
}

class _SafetyBoundaryState extends State<SafetyBoundary> {
  bool _hasError = false;
  String _errorMessage = '';

  void _resetError() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: ErrorCard(
          title: '${widget.moduleName} Temporarily Unavailable',
          whatHappened: _errorMessage.isNotEmpty
              ? _errorMessage
              : 'An unexpected issue occurred in ${widget.moduleName}.',
          whatUserCanDo: 'You can continue using other modes or tap below to recover.',
          onRetry: _resetError,
          retryLabel: 'Reload Module',
        ),
      );
    }

    return widget.child;
  }
}
