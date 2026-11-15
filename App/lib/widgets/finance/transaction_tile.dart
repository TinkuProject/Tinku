import 'package:flutter/material.dart';
import '../../models/financial_transaction_model.dart';
import '../../extensions/financial_transaction_extension.dart';
import '../../ui/themes/colors.dart';

class TransactionTile extends StatelessWidget {
  final FinancialTransactionModel tx;

  const TransactionTile({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: tx.color.withValues(alpha: 0.15),
        child: Icon(tx.icon, color: tx.color),
      ),
      title: Text(
        tx.description ?? tx.purposeLabel,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        tx.subtitleText,
        style: TextStyle(
          color: tx.isPending
              ? Colors.orange
              : AppColors.textSecondary,
        ),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            tx.formattedAmount,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: tx.color,
            ),
          ),
          Text(
            tx.typeLabel,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}