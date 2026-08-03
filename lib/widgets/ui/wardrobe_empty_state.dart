import 'package:flutter/material.dart';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';

class WardrobeEmptyState extends StatelessWidget {
  const WardrobeEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.checkroom,
            size: 64,
            color: AppTheme.glitchMagenta.withAlpha(130),
          ),
          const SizedBox(height: 12),
          Text(
            'Your wardrobe is empty',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Add items to see them here',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
