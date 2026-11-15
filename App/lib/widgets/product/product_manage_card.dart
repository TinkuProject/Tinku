import 'package:flutter/material.dart';
import 'product_info.dart';

import '../../../ui/themes/colors.dart';
import '../common/entity_manage/entity_manage_image.dart';
import '../common/entity_manage/entity_manage_actions.dart';
import '../common/entity_manage/entity_manage_header.dart';

class ProductManageCard extends StatelessWidget {
  final String title;

  final String? category;
  final String? business;
  final String? description;

  final String imageUrl;

  final String statusLabel;
  final Color statusColor;
  final IconData statusIcon;
  final String? statusSubtitle;

  final String? price;
  final String? tinkuPrice;
  final String? stock;

  final Widget? extraContent;

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductManageCard({
    super.key,
    required this.title,
    this.category,
    this.business,
    this.description,
    required this.imageUrl,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
    this.statusSubtitle,
    this.price,
    this.tinkuPrice,
    this.stock,
    this.extraContent,
    this.onEdit,
    this.onDelete,
  });

  bool get _showDivider =>
      extraContent != null ||
          description != null ||
          price != null ||
          tinkuPrice != null ||
          stock != null ||
          onEdit != null ||
          onDelete != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TOP
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EntityManageImage(
                  imageUrl: imageUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EntityManageHeader(
                        title: title,
                        statusLabel: statusLabel,
                        statusColor: statusColor,
                        statusIcon: statusIcon,
                        subtitle: statusSubtitle,
                      ),
                      if (category != null || business != null) ...[
                        const SizedBox(height: 6),
                        _ProductManageInfo(
                          category: category,
                          business: business,
                        ),
                      ],
                      if (description != null && description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            /// EXTRA CONTENT
            if (extraContent != null) ...[
              const SizedBox(height: 12),
              extraContent!,
            ],

            /// DIVIDER
            if (_showDivider)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 1,
                color: Colors.grey.withValues(alpha: 0.2),
              ),

            /// PRODUCT METRICS
            if (price != null || tinkuPrice != null || stock != null)
              ProductInfo(
                price: price,
                tinkuPrice: tinkuPrice,
                stock: stock,
              ),

            /// ACTIONS
            if (onEdit != null || onDelete != null) ...[
              const SizedBox(height: 12),
              EntityManageActions(
                onEdit: onEdit,
                onDelete: onDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductManageInfo extends StatelessWidget {
  final String? category;
  final String? business;

  const _ProductManageInfo({
    required this.category,
    required this.business,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    if (category != null) {
      items.add(
        _MiniInfoChip(
          icon: Icons.category_outlined,
          label: category!,
        ),
      );
    }

    if (business != null) {
      items.add(
        _MiniInfoChip(
          icon: Icons.storefront_outlined,
          label: business!,
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items,
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniInfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width - 118;

    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth.clamp(160, 420).toDouble(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.darkBlue,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
