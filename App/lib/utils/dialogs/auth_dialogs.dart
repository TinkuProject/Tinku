import 'package:flutter/material.dart';

class AuthDialogs {
  static Future<void> showLoginRequired(
      BuildContext context, {
        VoidCallback? onConfirm,
      }) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Acceso requerido'),
        content: const Text(
          'Debe iniciar sesión para continuar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm?.call();
            },
            child: const Text('Iniciar sesión'),
          ),
        ],
      ),
    );
  }
}