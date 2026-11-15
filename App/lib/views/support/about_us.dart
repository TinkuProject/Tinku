import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../ui/themes/colors.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';
import 'package:flutter/services.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String _appVersion = '1.0.0';
  static const String _appName = 'Tinku';
  static const String _contactEmail = 'soporte@tinku.app';
  static const String _termsUrl = 'https://umaunivalle.wordpress.com/2025/06/26/terminos-y-condiciones-de-uso-de-tinku/';

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _copyEmail(BuildContext context, String email) async {
    await Clipboard.setData(ClipboardData(text: email));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureWhite,
      appBar: const CustomAppBar(title: 'Acerca de'),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          // HERO
          Container(
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [AppColors.darkBlue, AppColors.mediumBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha:.08),
                    ),
                  ),
                ),
                Positioned(
                  left: -20,
                  bottom: -20,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha:.06),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.explore, color: Colors.white, size: 34),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _appName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Explora negocios, eventos, lugares, pagos y asistencia en un solo lugar.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha:.25)),
                    ),
                    child: const Text(
                      'Versión 1.0.0',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Misión
          const _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(icon: Icons.info_outline, title: 'Sobre la app'),
                SizedBox(height: 10),
                Text(
                  'Tinku conecta usuarios, negocios, organizadores y lugares turísticos. '
                      'Permite explorar por mapa y categorías, reservar eventos, validar asistencia con QR, '
                      'gestionar favoritos, revisar calendario, usar billetera y recibir notificaciones.',
                  style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.35),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Funcionalidades
          const _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(icon: Icons.star_outline, title: 'Lo que ofrece'),
                SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FeatureChip(icon: Icons.store_mall_directory, label: 'Negocios'),
                    _FeatureChip(icon: Icons.event, label: 'Eventos'),
                    _FeatureChip(icon: Icons.qr_code_scanner, label: 'Asistencia QR'),
                    _FeatureChip(icon: Icons.account_balance_wallet, label: 'Billetera'),
                    _FeatureChip(icon: Icons.reviews, label: 'Reseñas'),
                    _FeatureChip(icon: Icons.map, label: 'Mapa y rutas'),
                    _FeatureChip(icon: Icons.local_offer, label: 'Promociones'),
                    _FeatureChip(icon: Icons.notifications_active, label: 'Notificaciones'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Información
          _SectionCard(
            child: Column(
              children: [
                const _SectionTitle(icon: Icons.settings, title: 'Información'),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.code, color: AppColors.darkBlue),
                  title: Text('Versión de la app'),
                  subtitle: Text(_appVersion),
                ),
                const Divider(height: 8),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.person, color: AppColors.darkBlue),
                  title: Text('Desarrollado por'),
                  subtitle: Text('Equipo Tinku'),
                ),
                const Divider(height: 8),
                 ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.email_outlined, color: AppColors.darkBlue),
                  title: const Text('Contacto'),
                  subtitle: const Text(_contactEmail),
                   trailing: const Icon(Icons.copy, color: AppColors.darkBlue),
                   onTap: () => _copyEmail(context, _contactEmail),
                 ),
                const Divider(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.privacy_tip, color: AppColors.darkBlue),
                  title: const Text('Términos y condiciones'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openUrl(_termsUrl),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Footer
          Center(
            child: Text(
              '© ${DateTime.now().year} $_appName • Todos los derechos reservados',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.darkBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppColors.darkBlue),
      label: Text(label),
      backgroundColor: AppColors.mediumBlue.withValues(alpha:.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelStyle: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
