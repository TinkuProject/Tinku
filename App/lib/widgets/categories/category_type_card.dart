import 'package:flutter/material.dart';
import '../../ui/themes/colors.dart';

class CategoryTypeCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  final Color? color;
  final double width;
  final double height;

  const CategoryTypeCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.width = 140,
    this.height = 130,
  });

  @override
  State<CategoryTypeCard> createState() => _CategoryTypeCardState();
}

class _CategoryTypeCardState extends State<CategoryTypeCard> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.darkBlue;

    return GestureDetector(
      onTapDown: (_) => setState(() => pressed = true),
      onTapUp: (_) => setState(() => pressed = false),
      onTapCancel: () => setState(() => pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: pressed ? 0.96 : 1,
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color,
                color.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// ICONO CENTRADO
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 26,
                ),
              ),

              const SizedBox(height: 12),

              /// TEXTO CENTRADO
              Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}