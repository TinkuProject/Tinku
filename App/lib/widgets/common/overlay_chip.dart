import 'package:flutter/material.dart';
import '../../ui/themes/colors.dart';

class OverlayChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const OverlayChip({
    super.key,
    required this.icon,
    required this.text,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.textPrimary.withValues(alpha: 0.5);

    final fg = foregroundColor ?? Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
