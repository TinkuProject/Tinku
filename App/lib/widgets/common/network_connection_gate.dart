import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/network_status_service.dart';
import '../../ui/themes/colors.dart';

class NetworkConnectionGate extends StatelessWidget {
  const NetworkConnectionGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final network = context.watch<NetworkStatusService>();
    if (!network.isDisconnected) return child;

    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(child: child),
        NoConnectionScreen(
          isChecking: network.isChecking,
          onRetry: network.refresh,
        ),
      ],
    );
  }
}

class NoConnectionScreen extends StatelessWidget {
  const NoConnectionScreen({
    super.key,
    required this.onRetry,
    this.isChecking = false,
  });

  final Future<bool> Function() onRetry;
  final bool isChecking;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: AppColors.darkBlue.withValues(alpha: 0.09),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      color: AppColors.darkBlue,
                      size: 52,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Sin conexión a internet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Conéctate a una red Wi-Fi o activa tus datos móviles para continuar usando Tinku.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Semantics(
                    button: true,
                    label: 'Comprobar conexión a internet',
                    child: FilledButton.icon(
                      onPressed: isChecking ? null : onRetry,
                      icon: isChecking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.pureWhite,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded),
                      label: Text(
                        isChecking ? 'Comprobando…' : 'Volver a intentar',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: AppColors.darkBlue,
                        foregroundColor: AppColors.pureWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
