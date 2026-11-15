import 'package:flutter/material.dart';
import '../../../ui/themes/colors.dart';

class ProductInfo extends StatelessWidget {
  final String? price;
  final String? tinkuPrice;
  final String? stock;

  const ProductInfo({
    super.key,
    this.price,
    this.tinkuPrice,
    this.stock,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_MetricItem>[];

    if (price != null) {
      items.add(
        _MetricItem(
          icon: Icons.payments_outlined,
          value: price!,
          label: "Precio",
        ),
      );
    }

    if (tinkuPrice != null) {
      items.add(
        _MetricItem(
          icon: Icons.local_offer_outlined,
          value: tinkuPrice!,
          label: "Precio Tinku",
        ),
      );
    }

    if (stock != null) {
      items.add(
        _MetricItem(
          icon: Icons.inventory_2_outlined,
          value: stock!,
          label: "Stock",
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 14,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: items,
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MetricItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width - 96;

    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth.clamp(130, 240).toDouble(),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey,
          ),

          const SizedBox(width: 8),

          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),

                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
