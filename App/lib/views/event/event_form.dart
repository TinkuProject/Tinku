import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tinkuapp/controllers/shared/media/media_controller.dart';
import 'package:tinkuapp/services/entity_update_service.dart';

import '../../components/utils.dart';
import '../../controllers/event/event_form_controller.dart';
import '../../controllers/business/location_controller.dart';
import '../../controllers/shared/entity_updates/entity_update_controller.dart';
import '../../controllers/shared/notification/notification_controller.dart';
import '../../controllers/shared/transport/entity_transport_controller.dart';

import '../../models/event_model.dart';
import '../../providers/user_provider.dart';

import '../../services/entity_transport_relation_service.dart';
import '../../services/event_service.dart';
import '../../services/category_service.dart';
import '../../services/media_service.dart';
import '../../services/notification_service.dart';
import '../../services/transport_line_service.dart';
import '../../services/storage_service.dart';
import '../../services/business_service.dart';
import '../../services/transport_route_service.dart';

import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';
import '../../widgets/events/form/event_form_layout.dart';

class EventFormPage extends StatefulWidget {
  final bool editing;
  final EventModel? event;

  const EventFormPage({
    super.key,
    this.editing = false,
    this.event,
  });

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
  final _formKey = GlobalKey<FormState>();

  late EventFormController c;
  late LocationController locC;
  late NotificationController notifC;

  bool _initialLoading = true;
  bool _mapError = false;

  @override
  void initState() {
    super.initState();

    final userProvider = context.read<UserProvider>();
    final auth = userProvider.authService;

    final transportC = EntityTransportController(
      TransportLineService(auth),
      EntityTransportRelationService(auth),
      TransportRouteService(auth),
    );

    final mediaC = MediaController(
      StorageService(auth),
      MediaService(auth),
    );

    c = EventFormController(
      EventService(auth),
      CategoryService(auth),
      BusinessService(auth),
      userProvider,
      EntityUpdateController(EntityUpdateService(auth)),
      transportC,
      mediaC,
    );

    locC = LocationController();

    notifC = NotificationController(
      NotificationService(auth),
    );

    c.addListener(_rebuild);
    locC.addListener(_rebuild);

    _init();
  }

  Future<void> _init() async {
    if (widget.editing && widget.event != null) {
      await c.initFromEvent(widget.event!, locC);
    } else {
      await c.loadInitialData();
    }

    if (mounted) {
      setState(() => _initialLoading = false);
    }
  }

  @override
  void dispose() {
    c.removeListener(_rebuild);
    locC.removeListener(_rebuild);
    c.dispose();
    locC.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing;

    return Scaffold(
      appBar: CustomAppBar(
        title: isEdit ? "Editar Evento" : "Crear Evento",
      ),
      body: Stack(
        children: [
          // Fondo limpio moderno
          Positioned.fill(
            child: Container(color: Colors.white),
          ),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _initialLoading
                ? const AppLoader(
              message: "Preparando formulario...",
            )
                : _buildContent(isEdit),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isEdit) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: EventFormLayout(
        c: c,
        locC: locC,
        notifC: notifC,
        formKey: _formKey,
        isEdit: isEdit,
        eventId: widget.event?.id,
        mapError: _mapError,
        setMapError: (v) => setState(() => _mapError = v),

        onPickStart: _pickStartDate,
        onPickEnd: _pickEndDate,
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: c.startAt ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (!mounted || pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(c.startAt ?? now),
    );

    if (!mounted || pickedTime == null) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    c.setStart(combined);

    final suggestedEnd = combined.add(const Duration(minutes: 30));

    if (c.endAt == null || c.endAt!.isBefore(suggestedEnd)) {
      c.setEnd(suggestedEnd);
    }
  }

  Future<void> _pickEndDate() async {
    if (c.startAt == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar(
          "Selecciona primero la fecha de inicio.",
          isError: true,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(
      c.startAt!.year,
      c.startAt!.month,
      c.startAt!.day,
    );
    final firstEndDate = startDay.isAfter(today) ? startDay : today;
    final currentEndDate = c.endAt;
    final initialEndDate =
        currentEndDate != null && currentEndDate.isAfter(firstEndDate)
            ? currentEndDate
            : firstEndDate;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialEndDate,
      firstDate: firstEndDate,
      lastDate: DateTime(2100),
    );

    if (!mounted || pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(c.endAt ?? now),
    );

    if (!mounted || pickedTime == null) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    c.setEnd(combined);
  }
}
