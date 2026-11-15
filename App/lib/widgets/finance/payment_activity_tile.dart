import 'package:flutter/material.dart';

import '../../models/payment_activity_item.dart';
import '../../ui/themes/colors.dart';
import '../../utils/date/date_formatter.dart';

class PaymentActivityTile extends StatelessWidget {
  final PaymentActivityItem item;
  final VoidCallback? onTap;

  const PaymentActivityTile({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormatter.formDateTime(item.createdAt);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: item.iconColor.withValues(alpha: 0.15),
        child: Icon(item.icon, color: item.iconColor),
      ),
      title: Text(
        item.title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '$dateText • ${item.statusLabel}',
        style: TextStyle(
          color: item.isPending ? Colors.orange : AppColors.textSecondary,
        ),
      ),
      trailing: Text(
        item.amountLabel,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: item.amountColor,
        ),
      ),
    );
  }
}
