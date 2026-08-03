import 'package:flutter/material.dart';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';

class WardrobeErrorState extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onRetry;

  const WardrobeErrorState({
    super.key,
    required this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: AppTheme.error,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            "Something went wrong",
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                foregroundColor: AppTheme.textPrimary,
              ),
            )
          ]
        ],
      ),
    );
  }
}
