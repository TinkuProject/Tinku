import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../helpers/error_message_helper.dart';

class EmailChangeDialog extends StatefulWidget {
  const EmailChangeDialog({super.key, required this.auth, required this.email});
  final AuthService auth;
  final String email;

  @override
  State<EmailChangeDialog> createState() => _EmailChangeDialogState();
}

class _EmailChangeDialogState extends State<EmailChangeDialog> {
  final code = TextEditingController();
  bool busy = false;
  bool sent = false;
  String? error;

  Future<void> submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (!sent) {
        await widget.auth.requestEmailChange(widget.email);
        if (mounted) setState(() => sent = true);
      } else {
        await widget.auth.confirmEmailChange(widget.email, code.text.trim());
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) setState(() => error = userFacingError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Verificar nuevo correo'),
        content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sent
                    ? 'Ingresa el código enviado a ${widget.email}.'
                    : 'Enviaremos un código a ${widget.email} para confirmar el cambio.'),
                if (sent)
                  TextField(
                      controller: code,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                          labelText: 'Código de verificación',
                          errorText: error)),
                if (!sent && error != null) Text(error!),
              ],
            ))),
        actions: [
          TextButton(
              onPressed: busy ? null : () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: busy ? null : submit,
              child: Text(busy
                  ? 'Procesando...'
                  : sent
                      ? 'Confirmar'
                      : 'Enviar código')),
        ],
      );
}
