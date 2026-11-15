import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../ui/themes/colors.dart';
import '../services/auth_service.dart';
import '../components/utils.dart';
import '../providers/user_provider.dart';
import '../helpers/error_message_helper.dart';
import 'auth/email_verification_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatPasswordController =
      TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  bool _passwordVisible = false;
  bool _repeatPasswordVisible = false;
  bool _loadingGoogle = false;
  bool _loadingRegister = false;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _repeatPasswordError;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    repeatPasswordController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.darkBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.pureWhite),
          onPressed: () {
            ZoomDrawer.of(context)?.toggle();
          },
        ),
      ),
      backgroundColor: AppColors.pureWhite,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 150,
              decoration: const BoxDecoration(
                color: AppColors.darkBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              alignment: Alignment.center,
              child: const Text(
                'TINKU',
                style: TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Registrarme',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nombre de usuario', style: _labelStyle()),
                  const SizedBox(height: 5),
                  _textField(
                    usernameController,
                    Icons.person_outline,
                    errorText: _usernameError,
                    onChanged: (_) => _clearError('username'),
                  ),
                  const SizedBox(height: 20),
                  Text('Email', style: _labelStyle()),
                  const SizedBox(height: 5),
                  _textField(
                    emailController,
                    Icons.mail_outline,
                    errorText: _emailError,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => _clearError('email'),
                  ),
                  const SizedBox(height: 20),
                  Text('Contraseña', style: _labelStyle()),
                  const SizedBox(height: 5),
                  _passwordField(
                    passwordController,
                    _passwordVisible,
                    () {
                      setState(() => _passwordVisible = !_passwordVisible);
                    },
                    errorText: _passwordError,
                    onChanged: (_) => _clearError('password'),
                  ),
                  const SizedBox(height: 20),
                  Text('Confirmar contraseña', style: _labelStyle()),
                  const SizedBox(height: 5),
                  _passwordField(
                    repeatPasswordController,
                    _repeatPasswordVisible,
                    () {
                      setState(() =>
                          _repeatPasswordVisible = !_repeatPasswordVisible);
                    },
                    errorText: _repeatPasswordError,
                    onChanged: (_) => _clearError('repeatPassword'),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _loadingRegister
                        ? null
                        : () async {
                            final navigator = Navigator.of(context);

                            final email = emailController.text.trim();
                            final password = passwordController.text.trim();
                            final repeatPassword =
                                repeatPasswordController.text.trim();
                            final username = usernameController.text.trim();

                            if (!_validateForm(
                              username: username,
                              email: email,
                              password: password,
                              repeatPassword: repeatPassword,
                            )) {
                              return;
                            }

                            setState(() => _loadingRegister = true);
                            try {
                              final authService = context.read<AuthService>();

                              final result = await authService.register(
                                username: username,
                                email: email,
                                password: password,
                              );

                              if (!mounted) return;
                              navigator.pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => EmailVerificationPage(
                                    email: result.email,
                                    password: password,
                                    deliverySent: result.deliverySent,
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              showSnackbar(userFacingError(e), isError: true);
                            } finally {
                              if (mounted) {
                                setState(() => _loadingRegister = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkBlue,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                    child: _loadingRegister
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.pureWhite,
                            ),
                          )
                        : const Text(
                            'REGISTRARME',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.pureWhite,
                            ),
                          ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: _loadingGoogle
                        ? null
                        : () async {
                            final navigator = Navigator.of(context);
                            final userProvider = context.read<UserProvider>();
                            final notifProv =
                                context.read<NotificationProvider>();

                            setState(() => _loadingGoogle = true);

                            try {
                              final authService = context.read<AuthService>();

                              final authResponse = await authService
                                  .loginWithGoogle(forceAccountSelection: true);

                              await userProvider.setSession(
                                user: authResponse.profile,
                                accessToken: authResponse.accessToken,
                                refreshToken: authResponse.refreshToken,
                              );

                              notifProv.reset();
                              await notifProv.loadUnreadCount();

                              if (!mounted) return;
                              showSnackbar("Registro con Google exitoso");
                              navigator.pushReplacementNamed('/search');
                            } catch (e) {
                              if (!mounted) return;
                              showSnackbar(userFacingError(e), isError: true);
                            } finally {
                              if (mounted) {
                                setState(() => _loadingGoogle = false);
                              }
                            }
                          },
                    icon: _loadingGoogle
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.g_mobiledata, size: 28),
                    label: Text(
                      _loadingGoogle
                          ? 'Conectando con Google…'
                          : 'Registrarme con Google',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿Ya tienes una cuenta?'),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        child: const Text('Iniciar Sesión',
                            style: TextStyle(color: AppColors.mediumBlue)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _labelStyle() =>
      const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBlue);

  Widget _textField(
    TextEditingController controller,
    IconData icon, {
    String? errorText,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        errorText: errorText,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.mediumBlue),
        ),
      ),
    );
  }

  Widget _passwordField(
    TextEditingController controller,
    bool visible,
    VoidCallback toggleVisibility, {
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: !visible,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
          onPressed: toggleVisibility,
        ),
        errorText: errorText,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.mediumBlue),
        ),
      ),
    );
  }

  bool _validateForm({
    required String username,
    required String email,
    required String password,
    required String repeatPassword,
  }) {
    String? usernameError;
    String? emailError;
    String? passwordError;
    String? repeatPasswordError;

    if (username.isEmpty) {
      usernameError = 'Ingresa un nombre de usuario';
    } else if (username.length < 3) {
      usernameError = 'El usuario debe tener al menos 3 caracteres';
    } else if (username.length > 20) {
      usernameError = 'El usuario no puede superar 20 caracteres';
    } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      usernameError = 'Usa sólo letras, números y guion bajo';
    }

    if (email.isEmpty) {
      emailError = 'Ingresa tu email';
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      emailError = 'Ingresa un email válido';
    }

    if (password.isEmpty) {
      passwordError = 'Ingresa una contraseña';
    } else if (password.length < 8) {
      passwordError = 'Debe tener al menos 8 caracteres';
    } else if (!RegExp(r'[A-Z]').hasMatch(password)) {
      passwordError = 'Debe incluir al menos una mayúscula';
    } else if (!RegExp(r'[0-9]').hasMatch(password)) {
      passwordError = 'Debe incluir al menos un número';
    }

    if (repeatPassword.isEmpty) {
      repeatPasswordError = 'Confirma tu contraseña';
    } else if (password != repeatPassword) {
      repeatPasswordError = 'Las contraseñas no coinciden';
    }

    setState(() {
      _usernameError = usernameError;
      _emailError = emailError;
      _passwordError = passwordError;
      _repeatPasswordError = repeatPasswordError;
    });

    final isValid = [
      usernameError,
      emailError,
      passwordError,
      repeatPasswordError,
    ].every((error) => error == null);

    if (!isValid) {
      showSnackbar('Revisa los campos marcados', isError: true);
    }

    return isValid;
  }

  void _clearError(String field) {
    setState(() {
      switch (field) {
        case 'username':
          _usernameError = null;
          break;
        case 'email':
          _emailError = null;
          break;
        case 'password':
          _passwordError = null;
          _repeatPasswordError = null;
          break;
        case 'repeatPassword':
          _repeatPasswordError = null;
          break;
      }
    });
  }
}
