import 'package:flutter/material.dart';

class EntityManageImage extends StatelessWidget {
  final String imageUrl;

  const EntityManageImage({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    Widget fallback() {
      return Container(
        width: 85,
        height: 85,
        color: Colors.grey.shade300,
        child: const Icon(Icons.image),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              width: 85,
              height: 85,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback(),
            )
          : fallback(),
    );
  }
}
