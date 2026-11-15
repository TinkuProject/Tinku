import 'package:flutter/material.dart';

import '../../../ui/themes/colors.dart';

class AppLoader extends StatefulWidget {
  final String message;
  final IconData icon;
  final bool fullscreen;

  const AppLoader({
    super.key,
    this.message = 'Cargando...',
    this.icon = Icons.hourglass_top,
    this.fullscreen = true,
  });

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _halo;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _halo = Tween(begin: 2.0, end: 12.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildAnimatedIcon() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.darkBlue.withValues(alpha: 0.08),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkBlue.withValues(
                  alpha: 0.2 * (1 - _opacity.value),
                ),
                blurRadius: _halo.value,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            size: 34,
            color: AppColors.darkBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Semantics(
      liveRegion: true,
      label: widget.message,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: _buildAnimatedIcon()),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.darkBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.fullscreen) {
      return Center(child: _buildContent());
    }

    return SizedBox.expand(
      child: ColoredBox(
        color: Color.alphaBlend(
          Colors.black.withValues(alpha: 0.03),
          Colors.white,
        ),
        child: Center(child: _buildContent()),
      ),
    );
  }
}
