import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/enums.dart';
import '../../ui/themes/colors.dart';
import '../../views/user/edit_profile.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';
import '../../widgets/common/user_avatar.dart';

class UserOverviewPage extends StatefulWidget {
  const UserOverviewPage({super.key});

  @override
  State<UserOverviewPage> createState() => _UserOverviewPageState();
}

class _UserOverviewPageState extends State<UserOverviewPage> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    if (user == null) {
      return const Scaffold(
        body: AppLoader(message: 'Cargando perfil...'),
      );
    }

    final isRegularUser = user.role == UserRole.user;
    final isAdmin = user.role == UserRole.admin || user.role == UserRole.master;

    void navigate(BuildContext context, String route) {
      Navigator.pushNamed(context, route);
    }

    final fullName = ('${user.firstName ?? ''} ${user.lastName ?? ''}').trim();
    final displayName = fullName.isEmpty ? (user.username) : fullName;

    return Scaffold(
      appBar: CustomAppBar(
        title: isRegularUser ? 'Mi Perfil' : 'Gestionar Servicios',
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 220),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [AppColors.darkBlue, AppColors.mediumBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: .08),
                    blurRadius: 14,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: Stack(
              children: [
                // Decoración
                Positioned(
                    right: -28,
                    top: -28,
                    child: _circle(140, Colors.white.withValues(alpha: .08))),
                Positioned(
                    left: -22,
                    bottom: -22,
                    child: _circle(110, Colors.white.withValues(alpha: .06))),

                // Contenido
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar + nombre + email
                    Row(
                      children: [
                        const UserAvatar(radius: 44),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                user.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Botones responsivos: 2 por fila si hay espacio; si no, se apilan
                    LayoutBuilder(
                      builder: (context, c) {
                        final isNarrow = c.maxWidth < 380; // umbral para apilar
                        if (isNarrow) {
                          return Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: _HeroActionButton(
                                  icon: Icons.edit,
                                  label: 'Editar perfil',
                                  onPressed: _editProfile,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: _HeroActionButton(
                                  icon: Icons.lock_reset,
                                  label: 'Cambiar contraseña',
                                  onPressed: () => Navigator.pushNamed(
                                      context, '/changePassword'),
                                ),
                              ),
                            ],
                          );
                        }

                        // 2 por fila
                        return Row(
                          children: [
                            Expanded(
                              child: _HeroActionButton(
                                icon: Icons.edit,
                                label: 'Editar perfil',
                                onPressed: _editProfile,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _HeroActionButton(
                                icon: Icons.lock_reset,
                                label: 'Cambiar contraseña',
                                onPressed: () => Navigator.pushNamed(
                                    context, '/changePassword'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (!isRegularUser) ...[
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Presencia',
              icon: Icons.store_mall_directory_outlined,
              child: _TwoPerRow(children: [
                _buildTile(context, Icons.store, 'Negocios',
                    () => navigate(context, '/myBusinesses'), Colors.green),
                _buildTile(context, Icons.event, 'Eventos',
                    () => navigate(context, '/myEvents'), Colors.deepOrange),
                _buildTile(context, Icons.design_services, 'Servicios',
                    () => navigate(context, '/myServices'), Colors.purple),
                _buildTile(context, Icons.trending_up, 'Impulsos',
                    () => navigate(context, '/myNews'), Colors.deepOrange),
              ]),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Catálogo y ventas',
              icon: Icons.shopping_bag_outlined,
              child: _TwoPerRow(children: [
                _buildTile(
                    context,
                    Icons.local_offer_outlined,
                    'Promociones',
                    () => navigate(context, '/myPromotions'),
                    Colors.blueAccent),
                _buildTile(context, Icons.inventory_2_rounded, 'Productos',
                    () => navigate(context, '/myProducts'), Colors.teal),
                _buildTile(
                    context,
                    Icons.sell_outlined,
                    'Ventas',
                    () => navigate(context, '/myMarketplace'),
                    AppColors.darkBlue),
                _buildTile(context, Icons.warehouse_outlined, 'Almacenes',
                    () => navigate(context, '/warehouses'), AppColors.emerald),
              ]),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: 'Confianza',
              icon: Icons.verified_user_outlined,
              child: _TwoPerRow(children: [
                _buildTile(
                    context,
                    Icons.reviews_outlined,
                    'Reseñas',
                    () => navigate(context, '/manageReviews'),
                    AppColors.darkBlue),
                _buildTile(
                    context,
                    Icons.verified_user_outlined,
                    'Certificaciones',
                    () => navigate(context, '/myCertifications'),
                    Colors.indigo),
              ]),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Administración',
                icon: Icons.admin_panel_settings_outlined,
                child: _TwoPerRow(children: [
                  _buildTile(
                    context,
                    Icons.fact_check_outlined,
                    'Negocios pendientes',
                    () => navigate(context, '/adminPendingBusinesses'),
                    AppColors.darkBlue,
                  ),
                  _buildTile(
                    context,
                    Icons.event_available_outlined,
                    'Eventos pendientes',
                    () => navigate(context, '/adminPendingEvents'),
                    Colors.deepOrange,
                  ),
                  _buildTile(
                    context,
                    Icons.warehouse_outlined,
                    'Almacenes pendientes',
                    () => navigate(context, '/adminPendingWarehouses'),
                    AppColors.emerald,
                  ),
                  _buildTile(
                    context,
                    Icons.assignment_turned_in_outlined,
                    'Reclamos',
                    () => navigate(context, '/adminBusinessClaims'),
                    AppColors.mustard,
                  ),
                  _buildTile(
                    context,
                    Icons.place,
                    'Lugares turísticos',
                    () => navigate(context, '/touristPlaces'),
                    Colors.teal,
                  ),
                  _buildTile(
                    context,
                    Icons.currency_exchange,
                    'Retiros pendientes',
                    () => navigate(context, '/adminCashoutRequests'),
                    AppColors.darkBlue,
                  ),
                ]),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, IconData icon, String label,
      VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 112),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }

  Future<void> _editProfile() async {
    final navigator = Navigator.of(context);
    final userProvider = context.read<UserProvider>();
    final authService = userProvider.authService;

    final result = await navigator.push(
      MaterialPageRoute(builder: (_) => const EditProfile()),
    );

    if (result == null) return;

    final refreshedUser = await authService.getCurrentUser();
    if (refreshedUser == null) return;

    if (!mounted) return;

    userProvider.updateLocally(refreshedUser);
    setState(() {});
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppColors.darkBlue),
            const SizedBox(width: 8),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TwoPerRow extends StatelessWidget {
  final List<Widget> children;
  static const double gap = 20;

  const _TwoPerRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final useSingleColumn = c.maxWidth < 300 || textScale > 1.35;

      if (useSingleColumn) {
        return Column(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index < children.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      }

      final cellW = (c.maxWidth - gap) / 2;
      final rows = <Widget>[];

      for (int i = 0; i < children.length; i += 2) {
        final left = SizedBox(width: cellW, child: children[i]);
        final hasRight = i + 1 < children.length;
        final right = hasRight
            ? SizedBox(width: cellW, child: children[i + 1])
            : const SizedBox.shrink();

        rows.add(Padding(
          padding: EdgeInsets.only(bottom: i + 2 < children.length ? gap : 0),
          child: Row(
            children: [
              left,
              const SizedBox(width: gap),
              if (hasRight) right,
            ],
          ),
        ));
      }

      return Column(children: rows);
    });
  }
}

class _HeroActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _HeroActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: .6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label, overflow: TextOverflow.ellipsis),
    );
  }
}
