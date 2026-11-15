import 'package:flutter/material.dart';
import '../../../ui/themes/colors.dart';

class AnimatedRefreshIcon extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final double size;
  final Color? color;
  final String tooltip;

  const AnimatedRefreshIcon({
    super.key,
    required this.onTap,
    this.icon = Icons.refresh,
    this.size = 22,
    this.color,
    this.tooltip = 'Actualizar',
  });

  @override
  State<AnimatedRefreshIcon> createState() => _AnimatedRefreshIconState();
}

class _AnimatedRefreshIconState extends State<AnimatedRefreshIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isAnimating = false;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_isAnimating) return;

    _isAnimating = true;

    widget.onTap();
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.textSecondary;

    return Semantics(
      button: true,
      label: widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: _handleTap,
            child: SizedBox(
              width: 48,
              height: 48,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _controller.value * 6.28319,
                    child: child,
                  );
                },
                child: Icon(
                  widget.icon,
                  size: widget.size,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
