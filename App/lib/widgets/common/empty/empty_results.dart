import 'package:flutter/material.dart';

class EmptyResults extends StatelessWidget {
  final String title;
  final String subtitle;

  const EmptyResults({
    super.key,
    this.title = "No encontramos nada",
    this.subtitle = "Intenta cambiar los filtros o la búsqueda",
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.search_off,
              size: 50,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}