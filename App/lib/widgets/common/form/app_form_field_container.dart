import 'package:flutter/material.dart';
import '../../../ui/themes/colors.dart';

class AppFormFieldContainer extends StatelessWidget {
  final String label;
  final Widget child;

  const AppFormFieldContainer({
    super.key,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 6),

        // 🔥 SOLO AQUÍ VIVE EL ESTILO
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.navyBlue.withValues(alpha: 0.06),
            border: Border.all(
              color: AppColors.navyBlue.withValues(alpha: 0.35),
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}