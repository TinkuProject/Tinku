import 'package:flutter/material.dart';

import '../../../ui/themes/colors.dart';
import 'info_pill.dart';

class ManagePeriodCostInfo extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final double amount;
  final String amountSuffix;

  const ManagePeriodCostInfo({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.amount,
    this.amountSuffix = "Bs",
  });

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final days = endDate.difference(startDate).inDays + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            InfoPill(
              icon: Icons.play_arrow_rounded,
              label: "Inicio",
              value: _formatDate(startDate),
              color: AppColors.darkBlue,
            ),
            InfoPill(
              icon: Icons.flag_rounded,
              label: "Fin",
              value: _formatDate(endDate),
              color: AppColors.darkBlue,
            ),
            InfoPill(
              icon: Icons.timelapse_rounded,
              label: "Duración",
              value: "$days días",
              color: Colors.orange,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                size: 16,
                color: Colors.green,
              ),
              const SizedBox(width: 6),
              const Text(
                "Costo total",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              const Spacer(),
              Text(
                "${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)} $amountSuffix",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
