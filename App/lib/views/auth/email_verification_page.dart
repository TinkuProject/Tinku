import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../components/utils.dart';
import '../../helpers/error_message_helper.dart';
import '../../providers/notification_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../ui/themes/colors.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({
    super.key,
    required this.email,
    required this.password,
    this.deliverySent = true,
  });

  final String email;
  final String password;
  final bool deliverySent;

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final _codeController = TextEditingController();
  Timer? _timer;
  int _resendSeconds = 0;
  bool _verifying = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    if (widget.deliverySent) _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendSeconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      showSnackbar('Ingresa el código de 6 dígitos', isError: true);
      return;
    }

    setState(() => _verifying = true);
    try {
      final auth = context.read<AuthService>();
      await auth.verifyEmailCode(email: widget.email, code: code);
      final session = await auth.login(
        email: widget.email,
        password: widget.password,
      );

      if (!mounted) return;
      await context.read<UserProvider>().setSession(
            user: session.profile,
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
          );
      if (!mounted) return;
      final notifications = context.read<NotificationProvider>();
      notifications.reset();
      await notifications.loadUnreadCount();

      if (!mounted) return;
      showSnackbar('Correo verificado correctamente');
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } catch (error) {
      if (mounted) showSnackbar(userFacingError(error), isError: true);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await context
          .read<AuthService>()
          .requestEmailVerificationCode(email: widget.email);
      if (!mounted) return;
      _startCountdown();
      showSnackbar('Te enviamos un código nuevo');
    } catch (error) {
      if (mounted) showSnackbar(userFacingError(error), isError: true);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Verificar correo')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  const Icon(
                    Icons.mark_email_read_outlined,
                    size: 64,
                    color: AppColors.darkBlue,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Revisa tu correo',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.deliverySent
                        ? 'Enviamos un código de 6 dígitos a ${widget.email}'
                        : 'Tu cuenta fue creada, pero no pudimos enviar el código. Presiona reenviar para intentarlo nuevamente.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _codeController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Código',
                      prefixIcon: Icon(Icons.password_outlined),
                      counterText: '',
                    ),
                    onSubmitted: (_) => _verifying ? null : _verify(),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _verifying ? null : _verify,
                    icon: _verifying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.verified_outlined),
                    label: const Text('Verificar y continuar'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: AppColors.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed:
                        _resending || _resendSeconds > 0 ? null : _resend,
                    child: Text(
                      _resending
                          ? 'Enviando...'
                          : _resendSeconds > 0
                              ? 'Reenviar en $_resendSeconds s'
                              : 'Reenviar código',
                    ),
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
