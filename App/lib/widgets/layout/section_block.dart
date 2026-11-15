import 'package:flutter/material.dart';
import '../../ui/themes/colors.dart';

class SectionBlock extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  const SectionBlock({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.action,
    this.padding = const EdgeInsets.only(bottom: 24),
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: AppColors.darkBlue),
                const SizedBox(width: 6),
              ],

              Expanded(
                child: Text(
                  title,
                  style: textStyle,
                ),
              ),

              if (action != null) action!,
            ],
          ),

          const SizedBox(height: 12),

          child,
        ],
      ),
    );
  }
}