import 'package:flutter/material.dart';
import '../../ui/themes/colors.dart';

class FilteredEmptyState extends StatelessWidget {
  final VoidCallback? onAction;
  final String title;
  final String subtitle;
  final String actionText;
  final IconData icon;

  const FilteredEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.onAction,
    this.actionText = "Limpiar filtros",
    this.icon = Icons.filter_alt_off,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),

            const SizedBox(height: 12),

            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            if (onAction != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.darkBlue,
                ),
                child: Text(actionText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}