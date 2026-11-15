import 'package:flutter/material.dart';

class EntityManageMetrics extends StatelessWidget {
  final int? views;
  final double? rating;
  final String? date;

  const EntityManageMetrics({
    super.key,
    required this.views,
    this.rating,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    final hasRating = rating != null && rating! > 0;

    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20,
        runSpacing: 10,
        children: [
          if (views != null) ...[
            _Metric(Icons.visibility, "$views", "Vistas"),
          ],
          _Metric(
            hasRating ? Icons.star : Icons.star_border,
            hasRating ? rating!.toStringAsFixed(1) : "-",
            hasRating ? "Calificación" : "Sin reseñas",
          ),
          if (date != null) _Metric(Icons.calendar_today, date!, "Creado"),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _Metric(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
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
