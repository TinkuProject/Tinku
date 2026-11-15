import 'package:flutter/material.dart';

class AppCarousel extends StatelessWidget {
  final int itemCount;
  final double height;
  final double viewportFraction;
  final PageController controller;
  final Widget Function(BuildContext, int) itemBuilder;
  final EdgeInsetsGeometry padding;

  const AppCarousel({
    super.key,
    required this.itemCount,
    required this.height,
    required this.controller,
    required this.itemBuilder,
    this.viewportFraction = 0.9,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: SizedBox(
        height: height,
        child: PageView.builder(
          controller: controller,
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        ),
      ),
    );
  }
}