import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:provider/provider.dart';
import '../core/enums.dart';
import '../helpers/role_utils.dart';
import '../ui/themes/colors.dart';
import '../providers/user_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/common/user_avatar.dart';
import 'drawer_item.dart';

class DrawerMenu extends StatefulWidget {
  const DrawerMenu({super.key});

  @override
  State<DrawerMenu> createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  String? _loadedUnreadForUser;

  void _ensureUnreadLoaded(String? userId) {
    if (userId == null) {
      _loadedUnreadForUser = null;
      return;
    }

    if (_loadedUnreadForUser == userId) return;
    _loadedUnreadForUser = userId;
    Future.microtask(() {
      if (!mounted) return;
      context.read<NotificationProvider>().loadUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    final isLogged = user != null;
    final role = user?.role;

    final isPartner = role == UserRole.partner;
    final isRegularUser = role == UserRole.user;

    _ensureUnreadLoaded(user?.id);

    // ✔ obtenemos el número de notificaciones no leídas
    final unread =
        isLogged ? context.watch<NotificationProvider>().unreadCount : 0;

    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 20),
          children: [
            // HEADER
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Row(
                children: [
                  const UserAvatar(radius: 26),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.username ?? "Invitado",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user?.email ?? "Accede para más opciones",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      if (isLogged)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            getRoleLabel(role),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text('Descubrir', style: TextStyle(color: Colors.white70)),
            ),
            DrawerItem(
                icon: Icons.route,
                title: 'Rutas y líneas',
                onTap: () => _navigate(context, '/transportRoutes')),

            const Divider(color: Colors.white24),

            // MI CUENTA
            if (isLogged) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child:
                    Text('Mi cuenta', style: TextStyle(color: Colors.white70)),
              ),
              if (isRegularUser)
                DrawerItem(
                  icon: Icons.workspace_premium,
                  title: 'Volverse socio',
                  onTap: () => _navigate(context, '/becomePartner'),
                ),
              if (isPartner)
                DrawerItem(
                  icon: Icons.fact_check_outlined,
                  title: 'Reclamar negocio',
                  onTap: () => _navigate(context, '/claimBusiness'),
                ),
              DrawerItem(
                icon: Icons.favorite,
                title: 'Favoritos',
                onTap: () => _navigate(context, '/favourites'),
              ),
              DrawerItem(
                icon: Icons.event_available,
                title: 'Calendario',
                onTap: () => _navigate(context, '/myCalendar'),
              ),
              DrawerItem(
                icon: Icons.notifications,
                title: 'Notificaciones',
                badgeCount: unread,
                onTap: () => _navigate(context, '/notifications'),
              ),
              const Divider(color: Colors.white24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text('Mi billetera',
                    style: TextStyle(color: Colors.white70)),
              ),
              DrawerItem(
                icon: Icons.account_balance_wallet,
                title: 'Saldo Disponible',
                onTap: () => _navigate(context, '/walletBalance'),
              ),
              DrawerItem(
                icon: Icons.ev_station,
                title: 'Recarga y almacenes',
                onTap: () => _navigate(context, '/chargingPoints'),
              ),
              const Divider(color: Colors.white24),
            ],

            // SOPORTE
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text('Soporte', style: TextStyle(color: Colors.white70)),
            ),
            DrawerItem(
                icon: Icons.help_outline,
                title: 'Ayuda',
                onTap: () => _navigate(context, '/help')),
            DrawerItem(
                icon: Icons.info_outline,
                title: 'Acerca de',
                onTap: () => _navigate(context, '/about')),

            const Divider(color: Colors.white24),

            // LOGIN / LOGOUT
            DrawerItem(
              icon: isLogged ? Icons.logout : Icons.login,
              title: isLogged ? 'Cerrar sesión' : 'Iniciar sesión',
              onTap: () async {
                final navigator = Navigator.of(context);
                final zoomDrawer = ZoomDrawer.of(context);
                final userProv = context.read<UserProvider>();
                final notificationProv = context.read<NotificationProvider>();

                zoomDrawer?.close();
                await Future.delayed(const Duration(milliseconds: 300));

                if (isLogged) {
                  await userProv.clear(logoutOnServer: true);
                  notificationProv.reset();

                  navigator.pushNamedAndRemoveUntil('/login', (route) => false);
                } else {
                  navigator.pushNamed('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String route) {
    final navigator = Navigator.of(context);
    final zoomDrawer = ZoomDrawer.of(context);

    zoomDrawer?.close();
    Future.delayed(const Duration(milliseconds: 300), () {
      navigator.pushNamed(route);
    });
  }
}
