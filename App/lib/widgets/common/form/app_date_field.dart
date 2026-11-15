import 'package:flutter/material.dart';
import '../../../ui/themes/colors.dart';

class AppDateField extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;
  final IconData icon;

  const AppDateField({
    super.key,
    required this.label,
    required this.onTap,
    this.value,
    this.icon = Icons.schedule,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;

    return Semantics(
      button: true,
      label: '$label: ${hasValue ? value : 'Seleccionar'}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.navyBlue.withValues(alpha: 0.5),
              ),
              color: AppColors.navyBlue.withValues(alpha: 0.06),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.navyBlue, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.navyBlue,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasValue ? value! : "Seleccionar",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: hasValue ? Colors.black : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.navyBlue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
