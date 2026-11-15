import 'package:flutter/material.dart';
import '../../../components/utils.dart';
import '../confirm_dialog.dart';

Future<void> confirmAndDelete({
  required BuildContext context,
  required String title,
  required String message,
  required Future<void> Function() onDelete,
  required String successMessage,
  String? errorMessage,
  Future<void> Function()? onAfterDelete,
}) async {
  final ok = await ConfirmDialog.showDelete(
    context: context,
    title: title,
    message: message,
  );

  if (!ok) return;

  try {
    await onDelete();

    if (onAfterDelete != null) {
      await onAfterDelete();
    }

    if (!context.mounted) return;

    showSnackbar(successMessage);
  } catch (_) {
    showSnackbar(errorMessage ?? "Error al eliminar", isError: true);
  }
}