import 'package:flutter/material.dart';

import '../../ui/themes/colors.dart';
import '../common/overlay_actions.dart';
import '../common/overlay_chip.dart';

class BoostCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final IconData icon;
  final Map boost;
  final Map? tx;
  final VoidCallback onDelete;

  const BoostCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.icon,
    required this.boost,
    required this.tx,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final start = DateTime.parse(boost["start_date"]);
    final end = DateTime.parse(boost["end_date"]);

    final startText = "${start.day}/${start.month}";
    final endText = "${end.day}/${end.month}";

    final status = boost["status"];

    String statusText;
    Color statusColor;

    switch (status) {
      case 1:
        statusText = "Activo";
        statusColor = Colors.green;
        break;
      case 0:
        statusText = "Pendiente";
        statusColor = Colors.orange;
        break;
      case 2:
        statusText = "Finalizado";
        statusColor = Colors.grey;
        break;
      default:
        statusText = "Desconocido";
        statusColor = Colors.black54;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Positioned.fill(
                child: imageUrl != null
                    ? Image.network(imageUrl!, fit: BoxFit.cover)
                    : Container(
                  color: AppColors.darkBlue.withValues(alpha: 0.08),
                  child: Center(
                    child: Icon(icon, size: 36, color: AppColors.darkBlue),
                  ),
                ),
              ),

              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.75),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              /// STATUS
              Positioned(
                top: 10,
                left: 10,
                child: _statusChip(statusText, statusColor),
              ),

              /// FECHAS
              Positioned(
                top: 10,
                right: 10,
                child: OverlayChip(
                  icon: Icons.date_range,
                  text: "$startText → $endText",
                ),
              ),

              /// INFO
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 6),

                    if (tx != null)
                      _priceChip("${tx!["amount"]} Tinkus"),

                    Row(
                      children: [
                        OverlayActionButton(
                          icon: Icons.delete,
                          label: "Eliminar",
                          color: Colors.red.shade200,
                          onTap: onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _priceChip(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
