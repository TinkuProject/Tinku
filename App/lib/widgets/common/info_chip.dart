import 'package:flutter/material.dart';
import '../../ui/themes/colors.dart';

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;

  const InfoChip({
    super.key,
    required this.icon,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.surfaceSoft;
    final txtColor = textColor ?? AppColors.textPrimary;
    final icColor = iconColor ?? AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: icColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: txtColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}