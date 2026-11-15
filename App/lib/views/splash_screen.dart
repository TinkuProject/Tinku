import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/shared/notification/notification_controller.dart';
import '../providers/user_provider.dart';
import '../ui/themes/colors.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreen> {
  bool _showButton = false;
  bool _sessionHandled = false;
  late NotificationController notifC;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    notifC = context.read<NotificationController>();

    final userProvider = context.read<UserProvider>();

    if (userProvider.isLoading) return;
    if (_sessionHandled) return;
    _sessionHandled = true;

    _handleNavigation(userProvider);
  }

  Future<void> _handleNavigation(UserProvider userProvider) async {
    final navigator = Navigator.of(context);
    final user = userProvider.user;

    if (user != null) {
      await notifC.load();
      await notifC.initRealtime(user.id);

      if (!mounted) return;
      navigator.pushReplacementNamed('/home');
    } else {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      setState(() {
        _showButton = true;
      });
    }
  }

  void _handleStart() {
    final user = context.read<UserProvider>().user;

    if (user != null) {
      Navigator.pushNamed(context, '/home');
    } else {
      ZoomDrawer.of(context)?.toggle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<UserProvider>().isLoading;

    return Stack(
      children: [
        // Imagen de fondo
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/icons/cover.jpeg"),
              fit: BoxFit.cover,
            ),
          ),
        ),

        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: AppColors.pureWhite),
              onPressed: () => ZoomDrawer.of(context)?.toggle(),
            ),
          ),

          body: isLoading
              ? const Center(
            child: CircularProgressIndicator(color: AppColors.pureWhite),
          )
              : AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: _showButton ? 1.0 : 0.0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 220),
                child: ElevatedButton(
                  onPressed: _handleStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pureWhite,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Comenzar aventura",
                    style: TextStyle(fontSize: 16, color: AppColors.navyBlue),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}