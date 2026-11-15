import 'package:flutter/material.dart';
import '../../ui/themes/colors.dart';
import '../common/legend_item.dart';

class TransportLineLegend extends StatelessWidget {
  final Color outboundColor;
  final Color returnColor;

  const TransportLineLegend({
    super.key,
    required this.outboundColor,
    required this.returnColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: [
          LegendItem(
            color: outboundColor.withValues(alpha: 0.7),
            label: "Ida (color fuerte)",
          ),
          LegendItem(
            color: returnColor.withValues(alpha: 0.3),
            label: "Vuelta (color claro)",
          ),
        ],
      ),
    );
  }
}