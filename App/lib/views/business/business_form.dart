import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:tinkuapp/controllers/shared/entity_updates/entity_update_controller.dart';
import 'package:tinkuapp/core/enums.dart';
import 'package:tinkuapp/services/entity_update_service.dart';
import 'package:tinkuapp/services/social_link_service.dart';
import 'package:tinkuapp/services/transport_route_service.dart';

import '../../components/utils.dart';
import '../../controllers/business/location_controller.dart';
import '../../controllers/business/business_form_controller.dart';
import '../../controllers/shared/media/media_controller.dart';
import '../../controllers/shared/notification/notification_controller.dart';
import '../../controllers/shared/opening_hours/opening_hours_controller.dart';
import '../../controllers/shared/social/social_links_controller.dart';
import '../../controllers/shared/transport/entity_transport_controller.dart';
import '../../models/business_model.dart';
import '../../providers/user_provider.dart';

import '../../services/business_service.dart';
import '../../services/category_service.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
import '../../services/transport_line_service.dart';
import '../../services/media_service.dart';
import '../../services/opening_hour_service.dart';
import '../../services/entity_transport_relation_service.dart';

import '../../widgets/business/form/business_form_layout.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';

class BusinessFormPage extends StatefulWidget {
  final String type;
  final BusinessModel? business;

  const BusinessFormPage({super.key, required this.type, this.business});

  @override
  State<BusinessFormPage> createState() => _BusinessFormPageState();
}

class _BusinessFormPageState extends State<BusinessFormPage> {
  final _formKey = GlobalKey<FormState>();

  late BusinessFormController formC;
  late LocationController locC;
  late NotificationController notifC;

  bool _initialLoading = true;

  bool get _isService => widget.type.toLowerCase() == 'service';
  String get _title =>
      widget.business == null
          ? (_isService ? 'Crear Servicio' : 'Crear Negocio')
          : (_isService ? 'Editar Servicio' : 'Editar Negocio');

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final userProvider = context.read<UserProvider>();
    final auth = userProvider.authService;

    locC = LocationController();

    formC = BusinessFormController(
      BusinessService(auth),
      CategoryService(auth),
      EntityUpdateController(EntityUpdateService(auth)),

      MediaController(
        StorageService(auth),
        MediaService(auth),
      ),

      OpeningHoursController(
        OpeningHourService(auth),
      ),

      EntityTransportController(
        TransportLineService(auth),
        EntityTransportRelationService(auth),
        TransportRouteService(auth),
      ),

      SocialLinksController(
        SocialLinkService(auth),
      )..init(),

    );

    notifC = NotificationController(
      NotificationService(auth),
    );

    formC.addListener(_rebuild);
    locC.addListener(_rebuild);

    Future.microtask(() async {
      await formC.loadInitialData(type: businessTypeFromString(widget.type));

      if (widget.business != null) {
        await formC.loadForm(widget.business!);

        final latLng = LatLng(
          widget.business!.latitude,
          widget.business!.longitude,
        );

        locC.selected = latLng;
        await locC.updateAddressFromLatLng(latLng);
      }

      if (mounted) setState(() => _initialLoading = false);
    });

    _initialized = true;
  }

  @override
  void dispose() {
    formC.removeListener(_rebuild);
    locC.removeListener(_rebuild);
    formC.dispose();
    locC.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: _title),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(color: Colors.white),
          ),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _initialLoading
                ? const AppLoader(
              message: "Preparando formulario...",
            )
                : _buildForm(context),
          ),

        ],
      )
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: BusinessFormLayout(
        c: formC,
        locC: locC,
        formKey: _formKey,
        onSubmit: () => _onSubmit(context),
      ),
    );
  }

  Future<void> _onSubmit(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;

    if (user == null) {
      messenger.showSnackBar(
        tinkuSnackBar("Debe iniciar sesión.", isError: true),
      );
      return;
    }

    if (locC.selected == null) {
      messenger.showSnackBar(
        tinkuSnackBar("Seleccione una ubicación.", isError: true),
      );
      return;
    }

    final res = await formC.submit(
      type: businessTypeFromString(widget.type),
      address: locC.address,
      lat: locC.selected!.latitude,
      lng: locC.selected!.longitude,
      formKey: _formKey,
      userRole: userRoleToString(user.role),
      userId: user.id,
    );

    if (!mounted) return;

    messenger.showSnackBar(
      tinkuSnackBar(res.message, isError: !res.ok),
    );

    if (res.ok) {
      navigator.pop(true);
    }
  }
}
