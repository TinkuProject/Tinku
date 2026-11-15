import 'package:flutter/material.dart';

class ReviewStars extends StatelessWidget {
  final double rating;
  final int max;
  final double size;
  final Color? color;
  final void Function(double value)? onTap;

  const ReviewStars({
    super.key,
    required this.rating,
    this.max = 5,
    this.size = 20,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? Colors.amber;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(max, (i) {
        final filled = i < rating;

        final icon = Icon(
          filled ? Icons.star : Icons.star_border,
          size: size,
          color: starColor,
        );

        if (onTap != null) {
          return IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: icon,
            onPressed: () => onTap!(i + 1.0),
          );
        }

        return icon;
      }),
    );
  }
}