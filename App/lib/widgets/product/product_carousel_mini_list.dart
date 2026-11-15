import 'package:flutter/material.dart';

import '../../controllers/product/product_carousel_controller.dart';
import '../../models/product_model.dart';
import 'product_card.dart';

class ProductCarouselMiniList extends StatefulWidget {
  final List<ProductModel> products;
  final ProductCarouselController controller;

  const ProductCarouselMiniList({
    super.key,
    required this.products,
    required this.controller,
  });

  @override
  State<ProductCarouselMiniList> createState() =>
      _ProductCarouselMiniListState();
}

class _ProductCarouselMiniListState extends State<ProductCarouselMiniList> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.84);
  }

  @override
  void didUpdateWidget(covariant ProductCarouselMiniList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.products.length != widget.products.length &&
        widget.products.isNotEmpty) {
      final maxIndex = widget.products.length - 1;
      if (widget.controller.currentPage > maxIndex) {
        widget.controller.setCurrentPage(maxIndex);
        if (_pageController.hasClients) {
          _pageController.jumpToPage(maxIndex);
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        if (widget.controller.loading) {
          return const SizedBox(
            height: 300,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (widget.products.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            SizedBox(
              height: 500,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.products.length,
                onPageChanged: widget.controller.setCurrentPage,
                itemBuilder: (context, index) {
                  final product = widget.products[index];

                  return ProductCard(
                    product: product,
                    controller: widget.controller,
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.products.asMap().entries.map((entry) {
                final isActive = widget.controller.currentPage == entry.key;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isActive ? 10 : 8,
                  height: isActive ? 10 : 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? const Color(0xFF0078B7)
                        : const Color(0xFFBDBDBD),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}