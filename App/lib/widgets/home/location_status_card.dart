import 'package:flutter/material.dart';
import '../../ui/themes/colors.dart';

class LocationStatusCard extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const LocationStatusCard({
    super.key,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (enabled) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_off, color: AppColors.mustard),

            const SizedBox(width: 10),

            const Expanded(
              child: Text(
                'Activa tu ubicación para ver lugares cercanos',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            TextButton(
              onPressed: onTap,
              child: const Text('Activar'),
            )
          ],
        ),
      ),
    );
  }
}