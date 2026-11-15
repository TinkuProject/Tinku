import 'package:flutter/material.dart';

Future<void> openFilter<T>(
    BuildContext context,
    String title,
    Map<T, String> items,
    T current,
    ValueChanged<T> onChanged,
    ) async {
  final selected = await showModalBottomSheet<T>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: items.entries.map((e) {
                final isSelected = e.key == current;

                return ListTile(
                  title: Text(e.value),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () => Navigator.pop(context, e.key),
                );
              }).toList(),
            ),
          ),
        ],
      );
    },
  );

  if (selected != null) {
    onChanged(selected);
  }
}