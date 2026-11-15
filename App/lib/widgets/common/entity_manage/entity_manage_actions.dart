import 'package:flutter/material.dart';

import '../../../ui/themes/colors.dart';

class EntityManageActions extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EntityManageActions({
    super.key,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (onEdit == null && onDelete == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final stackActions = constraints.maxWidth < 260 || textScale > 1.4;
        final actions = <Widget>[
          if (onEdit != null)
            OutlinedButton.icon(
              onPressed: onEdit,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: AppColors.darkBlue.withValues(alpha: 0.3),
                ),
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(
                Icons.edit,
                color: AppColors.darkBlue,
                size: 16,
              ),
              label: const Text(
                "Editar",
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.darkBlue,
                ),
              ),
            ),
          if (onDelete != null)
            OutlinedButton.icon(
              onPressed: onDelete,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Colors.red.withValues(alpha: 0.4),
                ),
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(
                Icons.delete,
                size: 16,
                color: Colors.red,
              ),
              label: const Text(
                "Eliminar",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red,
                ),
              ),
            ),
        ];

        if (stackActions) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < actions.length; index++) ...[
                actions[index],
                if (index < actions.length - 1) const SizedBox(height: 8),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var index = 0; index < actions.length; index++) ...[
              Expanded(child: actions[index]),
              if (index < actions.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }
}
