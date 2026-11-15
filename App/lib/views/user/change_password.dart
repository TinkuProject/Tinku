import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/utils.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../ui/themes/colors.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _loading = false;

  String? _validateCurrentPassword(String? v) {
    if ((v?.trim() ?? '').isEmpty) return 'Campo requerido';
    return null;
  }

  String? _validateNewPassword(String? v) {
    final value = v?.trim() ?? '';

    if (value.isEmpty) return 'Campo requerido';
    if (value.length < 8) return 'Debe tener mínimo 8 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Debe incluir una mayúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Debe incluir un número';
    }

    return null;
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      try {
        final decoded = jsonDecode(error.message);
        final message = decoded['error'] ?? decoded['message'];

        if (message == 'Invalid current password') {
          return 'La contraseña actual no es correcta';
        }

        if (message is String && message.isNotEmpty) {
          return message;
        }
      } catch (_) {
        return error.message;
      }
    }

    return 'No se pudo actualizar la contraseña';
  }

  Future<void> _changePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_newCtrl.text.trim() != _confirmCtrl.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar('Las contraseñas no coinciden', isError: true),
      );
      return;
    }

    if (_currentCtrl.text.trim() == _newCtrl.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar('La nueva contraseña debe ser diferente', isError: true),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await context.read<UserProvider>().authService.changePassword(
        currentPassword: _currentCtrl.text.trim(),
        newPassword: _newCtrl.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar('Contraseña actualizada'),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar(_errorMessage(e), isError: true),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decor(String label, bool obscure, Function() toggle) {
    return InputDecoration(
      labelText: label,
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
        onPressed: toggle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Cambiar contraseña'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _currentCtrl,
                obscureText: _obscureCurrent,
                decoration: _decor(
                  'Contraseña actual',
                  _obscureCurrent,
                  () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
                validator: _validateCurrentPassword,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _newCtrl,
                obscureText: _obscureNew,
                decoration: _decor(
                  'Nueva contraseña',
                  _obscureNew,
                  () => setState(() => _obscureNew = !_obscureNew),
                ),
                validator: _validateNewPassword,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                decoration: _decor(
                  'Confirmar nueva contraseña',
                  _obscureConfirm,
                  () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: _validateNewPassword,
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Actualizar contraseña',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
