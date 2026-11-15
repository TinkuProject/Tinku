import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../components/utils.dart';
import '../../helpers/error_message_helper.dart';
import '../../services/auth_service.dart';
import '../../ui/themes/colors.dart';

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  late final TextEditingController _emailController;
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repeatController = TextEditingController();
  bool _codeRequested = false;
  bool _loading = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  Future<void> _requestCode() async {
    final email = _emailController.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      showSnackbar('Ingresa un email válido', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await context
          .read<AuthService>()
          .requestPasswordRecoveryCode(email: email);
      if (!mounted) return;
      setState(() => _codeRequested = true);
      showSnackbar('Si la cuenta existe, recibirás un código por correo');
    } catch (error) {
      if (mounted) showSnackbar(userFacingError(error), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    if (_codeController.text.trim().length != 6) {
      showSnackbar('Ingresa el código de 6 dígitos', isError: true);
      return;
    }
    if (password.length < 8 ||
        !RegExp(r'[A-Z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password)) {
      showSnackbar(
        'La contraseña debe tener 8 caracteres, una mayúscula y un número',
        isError: true,
      );
      return;
    }
    if (password != _repeatController.text) {
      showSnackbar('Las contraseñas no coinciden', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<AuthService>().resetPasswordWithCode(
            email: _emailController.text.trim(),
            code: _codeController.text.trim(),
            newPassword: password,
          );
      if (!mounted) return;
      showSnackbar('Contraseña actualizada. Ya puedes iniciar sesión');
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) showSnackbar(userFacingError(error), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _repeatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  const Icon(
                    Icons.lock_reset_outlined,
                    size: 64,
                    color: AppColors.darkBlue,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    enabled: !_codeRequested,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  if (_codeRequested) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Código de recuperación',
                        prefixIcon: Icon(Icons.password_outlined),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: 'Nueva contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _showPassword = !_showPassword,
                          ),
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _repeatController,
                      obscureText: !_showPassword,
                      decoration: const InputDecoration(
                        labelText: 'Repetir contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _loading
                        ? null
                        : _codeRequested
                            ? _resetPassword
                            : _requestCode,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _codeRequested
                                ? Icons.check_circle_outline
                                : Icons.send_outlined,
                          ),
                    label: Text(
                      _codeRequested
                          ? 'Actualizar contraseña'
                          : 'Enviar código',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: AppColors.darkBlue,
                    ),
                  ),
                  if (_codeRequested)
                    TextButton(
                      onPressed: _loading ? null : _requestCode,
                      child: const Text('Reenviar código'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
