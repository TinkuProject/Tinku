import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../components/utils.dart';
import '../../../controllers/certification/certification_controller.dart';
import '../../../models/certification_model.dart';
import '../../../providers/user_provider.dart';
import '../../../services/business_service.dart';
import '../../../services/certification_service.dart';
import '../../../services/media_service.dart';
import '../../../widgets/bars/filter_bar_products.dart';
import '../../../widgets/certifications/certification_manage_card.dart';
import '../../../widgets/common/actions/app_fab.dart';
import '../../../widgets/common/confirm_dialog.dart';
import '../../../widgets/common/filtered_empty.dart';
import '../../../widgets/common/initial_empty_state.dart';
import '../../../widgets/common/loaders/app_loader.dart';
import '../../../widgets/common/navigation/custom_app_bar.dart';
import '../../../widgets/selectors/business_selector_dialog.dart';
import 'certification_form.dart';

class ListCertificationsPage extends StatefulWidget {
  const ListCertificationsPage({super.key});

  @override
  State<ListCertificationsPage> createState() => _ListCertificationsPageState();
}

class _ListCertificationsPageState extends State<ListCertificationsPage> {
  late CertificationController c;
  bool _initialized = false;
  String? _loadedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final userProvider = context.watch<UserProvider>();
    final userId = userProvider.user?.id;
    if (_initialized && _loadedUserId == userId) return;

    if (_initialized) {
      c.removeListener(_rebuild);
      c.reset();
    }

    final auth = userProvider.authService;

    c = CertificationController(
      CertificationService(auth),
      BusinessService(auth),
      MediaService(auth),
    );

    c.addListener(_rebuild);
    _loadedUserId = userId;

    Future.microtask(() async {
      await c.loadMine();
    });

    _initialized = true;
  }

  @override
  void dispose() {
    if (_initialized) {
      c.removeListener(_rebuild);
      c.reset();
      c.dispose();
    }
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      tinkuSnackBar(message),
    );
  }

  Future<void> _refresh() async {
    await c.refresh();
  }

  Future<void> _openPDF(String url) async {
    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnack('No se pudo abrir el archivo');
    }
  }

  Future<void> _confirmDelete(CertificationModel certification) async {
    final ok = await ConfirmDialog.showDelete(
      context: context,
      title: '¿Eliminar certificación?',
      message: '¿Seguro que deseas eliminar "${certification.name}"?',
    );

    if (!ok) return;

    final deleted = await c.deleteCertification(certification.id);

    if (!mounted) return;

    _showSnack(
      deleted ? 'Certificación eliminada' : 'Error al eliminar',
    );
  }

  Future<void> _openCreateCertification() async {
    if (!c.hasBusinesses) {
      _showSnack('No tienes negocios disponibles.');
      return;
    }

    final items = Map<int, String>.from(c.businessSelectorItems)..remove(0);

    final selected = await showBusinessSelectorDialog(
      context: context,
      businessItems: items,
      disabledIds: c.disabledBusinessSelectorIds,
      disabledLabel: 'Pendiente',
      title: 'Seleccionar negocio',
    );

    if (!mounted || selected == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CertificationFormPage(
          businessId: selected,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      _showSnack('Certificación creada correctamente.');
      await c.refresh();
    }
  }

  Future<void> _editCertification(CertificationModel certification) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CertificationFormPage(
          businessId: certification.businessId,
          certification: certification,
        ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      _showSnack('Certificación actualizada correctamente.');
      await c.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = c.filteredCertifications;
    final hasBusinesses = c.hasBusinesses;
    final isFilteredEmpty = filtered.isEmpty && c.hasData;
    final isInitialEmpty = filtered.isEmpty && !c.hasData;
    final isLoading = c.loading;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Certificaciones'),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: FilterBarProducts(
                  order: c.filterOrder,
                  business: c.selectedBusinessId,
                  businessItems: c.businessSelectorItems,
                  onOrder: c.setFilterOrder,
                  onBusiness: (v) async {
                    await c.loadByBusiness(v);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: isLoading
                    ? const SizedBox.shrink()
                    : !hasBusinesses
                    ? InitialEmptyState(
                  icon: FontAwesomeIcons.certificate,
                  title: 'No tienes negocios registrados',
                  description:
                  'Primero necesitas crear un negocio para poder registrar certificaciones.',
                  actionLabel: 'Agregar certificación',
                  onCreate: _openCreateCertification,
                )
                    : isInitialEmpty
                    ? InitialEmptyState(
                  icon: FontAwesomeIcons.certificate,
                  title: 'No tienes certificaciones',
                  description:
                  'Agrega certificaciones para mostrar la documentación de tus negocios.',
                  actionLabel: 'Agregar certificación',
                  onCreate: _openCreateCertification,
                )
                    : isFilteredEmpty
                    ? FilteredEmptyState(
                  title: 'No hay certificaciones con estos filtros',
                  subtitle: 'Prueba cambiando el negocio o el orden.',
                  onAction: () async {
                    c.resetFilters();
                    await c.loadByBusiness(0);
                  },
                )
                    : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final cert = filtered[index];
                      final media = c.getMedia(cert.id);
                      final url = media.isNotEmpty ? media.first : null;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: CertificationManageCard(
                          certification: cert,
                          documentUrl: url,
                          businessName: c.businessNameFor(cert.businessId),
                          onOpen: url == null ? null : () => _openPDF(url),
                          onEdit: () => _editCertification(cert),
                          onDelete: () => _confirmDelete(cert),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          if (isLoading)
            const AppLoader(
              message: 'Cargando tus certificaciones...',
            ),
        ],
      ),
      floatingActionButton: filtered.isEmpty
          ? null
          : AppFAB(
        icon: Icons.add,
        label: 'Agregar certificación',
        onPressed: _openCreateCertification,
      ),
    );
  }
}
