import 'package:flutter/material.dart';

Future<int?> showBusinessSelectorDialog({
  required BuildContext context,
  required Map<int, String> businessItems,
  Set<int> disabledIds = const {},
  String disabledLabel = 'No aprobado',
  String title = "Seleccionar negocio",
}) {
  final list = businessItems.entries
      .where((e) => e.key != 0)
      .map((e) => {"id": e.key, "name": e.value})
      .toList();

  if (list.isEmpty) {
    return Future.value(null);
  }

  return showDialog<int>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(title),
      children: list.map((b) {
        final id = b["id"] as int;
        final name = b["name"] as String;
        final disabled = disabledIds.contains(id);

        return SimpleDialogOption(
          onPressed: disabled ? null : () => Navigator.pop(ctx, id),
          child: Opacity(
            opacity: disabled ? 0.45 : 1,
            child: Row(
              children: [
                Expanded(child: Text(name)),
                if (disabled)
                  Text(
                    disabledLabel,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    ),
  );
}
