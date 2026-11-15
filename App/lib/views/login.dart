import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:provider/provider.dart';
import '../components/utils.dart';
import '../helpers/error_message_helper.dart';
import '../providers/notification_provider.dart';
import '../providers/user_provider.dart';
import '../ui/themes/colors.dart';
import '../services/auth_service.dart';
import 'auth/email_verification_page.dart';
import 'auth/password_recovery_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _loadingLogin = false;
  bool _loadingGoogle = false;
  bool _obscureText = false;

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
              'Inicio de Sesión',
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
                  const Text(
                    'Email',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.mail_outline),
                      border: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.mediumBlue)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Contraseña',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: passwordController,
                    obscureText: !_obscureText,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                      border: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.mediumBlue)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _loadingLogin
                        ? null
                        : () async {
                            final input = emailController.text.trim();
                            final password = passwordController.text.trim();

                            if (input.isEmpty || password.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                tinkuSnackBar(
                                  "Por favor, completa todos los campos",
                                  isError: true,
                                ),
                              );
                              return;
                            }

                            final userProvider = context.read<UserProvider>();
                            final notifProv =
                                context.read<NotificationProvider>();
                            final navigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);

                            final isEmail = input.contains('@');

                            setState(() => _loadingLogin = true);

                            try {
                              final authService = context.read<AuthService>();

                              final authResponse = await authService.login(
                                email: isEmail ? input : null,
                                username: isEmail ? null : input,
                                password: password,
                              );

                              await userProvider.setSession(
                                user: authResponse.profile,
                                accessToken: authResponse.accessToken,
                                refreshToken: authResponse.refreshToken,
                              );

                              notifProv.reset();
                              await notifProv.loadUnreadCount();

                              if (!mounted) return;
                              navigator.pushReplacementNamed('/home');
                            } catch (e) {
                              if (e is ApiException &&
                                  e.message
                                      .toLowerCase()
                                      .contains('email not verified') &&
                                  mounted) {
                                if (isEmail) {
                                  navigator.push(
                                    MaterialPageRoute(
                                      builder: (_) => EmailVerificationPage(
                                        email: input,
                                        password: password,
                                        deliverySent: false,
                                      ),
                                    ),
                                  );
                                } else {
                                  messenger.showSnackBar(
                                    tinkuSnackBar(
                                      'Ingresa con tu email para verificar la cuenta',
                                      isError: true,
                                    ),
                                  );
                                }
                                return;
                              }
                              messenger.showSnackBar(
                                tinkuSnackBar(
                                  userFacingError(e),
                                  isError: true,
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _loadingLogin = false);
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
                    child: _loadingLogin
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.pureWhite,
                            ),
                          )
                        : const Text(
                            'INGRESAR',
                            style: TextStyle(
                                fontSize: 16, color: AppColors.pureWhite),
                          ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PasswordRecoveryPage(
                              initialEmail: emailController.text.trim(),
                            ),
                          ),
                        );
                      },
                      child: const Text('Olvidé mi contraseña'),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿No tienes una cuenta?'),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text('Regístrate',
                            style: TextStyle(color: AppColors.mediumBlue)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _loadingGoogle
                        ? null
                        : () async {
                            final userProvider = context.read<UserProvider>();
                            final notifProv =
                                context.read<NotificationProvider>();
                            final navigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);

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
                              notifProv.loadUnreadCount();

                              if (!mounted) return;
                              navigator.pushReplacementNamed('/home');
                            } catch (e) {
                              messenger.showSnackBar(
                                tinkuSnackBar(userFacingError(e),
                                    isError: true),
                              );
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
                          : 'Continuar con Google',
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
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
