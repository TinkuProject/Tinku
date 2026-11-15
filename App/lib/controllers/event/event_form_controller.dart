import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/enums.dart';
import '../../helpers/error_message_helper.dart';
import '../../models/business_model.dart';
import '../../models/event_model.dart';
import '../../models/media_target.dart';
import '../../providers/user_provider.dart';
import '../../services/business_service.dart';
import '../../services/category_service.dart';
import '../../services/event_service.dart';
import '../business/location_controller.dart';
import '../shared/entity_updates/entity_update_controller.dart';
import '../shared/media/media_controller.dart';
import '../shared/transport/entity_transport_controller.dart';

class SubmitResult {
  final bool ok;
  final String message;
  const SubmitResult(this.ok, this.message);
}

class EventFormController extends ChangeNotifier {
  EventFormController(
      this._eventSvc,
      this._categorySvc,
      this._businessSvc,
      this._userProvider,
      this._entityUpdateController,
      this.transportC,
      this.media,
      ) {
    transportC.addListener(notifyListeners);
    media.addListener(notifyListeners);
  }

  final EventService _eventSvc;
  final CategoryService _categorySvc;
  final BusinessService _businessSvc;
  final UserProvider _userProvider;
  final EntityUpdateController _entityUpdateController;
  final MediaController media;
  final EntityTransportController transportC;

  // Campos del formulario
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final attendeesCtrl = TextEditingController();
  final tinkuPriceCtrl = TextEditingController();

  DateTime? startAt;
  DateTime? endAt;
  double? currentLat;
  double? currentLng;

  String? selectedCategoryId;
  String? selectedBusinessId;

  Map<String, String> categories = {};
  List<BusinessModel> businesses = [];

  // Imágenes
  List<dynamic> get images => media.items;

  bool loading = false;
  bool loadingData = false;

  // --------------------------
  // Protección contra dispose
  // --------------------------
  bool _disposed = false;
  void _safeNotify() {
    if (_disposed) return;
    try {
      notifyListeners();
    } catch (_) {
      // si algo falla mientras se desmonta la vista, no se revienta la app
    }
  }

  // -------------------------------------------------------------
  // LOAD INITIAL DATA (CATEGORÍAS, LÍNEAS, NEGOCIOS)
  // -------------------------------------------------------------
  Future<void> loadInitialData() async {
    loadingData = true;
    _safeNotify();

    try {
      final user = _userProvider.user;

      final results = await Future.wait([
        _categorySvc.getActive(entityType: CategoryEntityType.event),
        _businessSvc.getMine(),
      ]);

      final cats = results[0] as List;
      final mineBiz = results[1] as List<BusinessModel>;

      categories = {for (var c in cats) c.id.toString(): c.name};

      businesses = mineBiz
          .where(
            (b) =>
                b.ownerId == user?.id &&
                b.businessType == BusinessType.business,
      )
          .toList();
    } catch (_) {
    } finally {
      loadingData = false;
      _safeNotify();
    }
  }

  // -------------------------------------------------------------
  // INIT FROM EXISTING EVENT
  // -------------------------------------------------------------
  Future<void> initFromEvent(EventModel event, LocationController locC) async {
    loadingData = true;
    _safeNotify();

    await loadInitialData();

    nameCtrl.text = event.name;
    descCtrl.text = event.description ?? '';
    attendeesCtrl.text =
    (event.capacity != null && event.capacity! > 0)
        ? event.capacity.toString()
        : '';

    tinkuPriceCtrl.text =
    (event.tinkuPrice != null && event.tinkuPrice! > 0)
        ? event.tinkuPrice.toString()
        : '';

    startAt = event.startDate;
    endAt = event.endDate;
    selectedCategoryId = event.categoryId.toString();
    selectedBusinessId = event.businessId?.toString();

    final pos = LatLng(event.latitude, event.longitude);
    locC.selected = pos;

    loadingData = false;
    _safeNotify();

    media.load(
      target: EntityMediaTarget(
        entityId: event.id,
        entityType: MediaEntityType.event,
      ),
    );

    locC.updateAddressFromLatLng(pos);
  }

  void setCategory(String? id) {
    selectedCategoryId = id;
    _safeNotify();
  }

  void setBusiness(String? id) {
    selectedBusinessId = id;
    _safeNotify();
  }

  void setStart(DateTime dt) {
    startAt = dt;
    _safeNotify();
  }

  void setEnd(DateTime dt) {
    endAt = dt;
    _safeNotify();
  }

  // -------------------------------------------------------------
  // SUBMIT (CREAR O EDITAR)
  // -------------------------------------------------------------
  Future<SubmitResult> submit({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required String address,
    required double? lat,
    required double? lng,
    bool editing = false,
    int? eventId,
  }) async {
    final currentUser = _userProvider.user;

    if (currentUser == null) {
      return const SubmitResult(false, "No hay usuario autenticado");
    }

    if (!(formKey.currentState?.validate() ?? false) ||
        selectedCategoryId == null ||
        startAt == null ||
        endAt == null ||
        lat == null ||
        lng == null) {
      return const SubmitResult(false, "Faltan datos obligatorios");
    }

    if (!endAt!.isAfter(startAt!)) {
      return const SubmitResult(
        false,
        "La fecha de fin no puede ser anterior al inicio",
      );
    }

    final now = DateTime.now();
    if (endAt!.isBefore(now)) {
      return const SubmitResult(
        false,
        "La fecha y hora de fin no puede estar en el pasado",
      );
    }

    if (endAt!.difference(startAt!).inMinutes < 30) {
      return const SubmitResult(
        false,
        "El evento debe durar al menos 30 minutos",
      );
    }

    loading = true;
    _safeNotify();

    try {
      if (editing && eventId != null) {
        final data = {
          'name': nameCtrl.text.trim(),
          'description': descCtrl.text.trim(),
          'start_date': startAt!.toUtc().toIso8601String(),
          'end_date': endAt!.toUtc().toIso8601String(),
          'capacity': attendeesCtrl.text.trim().isEmpty
              ? 0
              : (int.tryParse(attendeesCtrl.text.trim()) ?? 0),
          'category_id': int.parse(selectedCategoryId!),
          'tinku_price': tinkuPriceCtrl.text.trim().isEmpty
              ? 0
              : (int.tryParse(tinkuPriceCtrl.text.trim()) ?? 0),
          'address': address,
          'latitude': lat,
          'longitude': lng,
          'location': {
            'latitude': lat,
            'longitude': lng,
          },
          'business_id': selectedBusinessId != null &&
              selectedBusinessId!.isNotEmpty
              ? int.tryParse(selectedBusinessId!)
              : null,
        };

        final removedMediaIds = media.deletedMediaIds;
        final uploadedUrls = await media.uploadNew(
          target: EntityMediaTarget(
            entityId: eventId,
            entityType: MediaEntityType.event,
          ),
          uploadMode: 'storage_only',
        );

        await _entityUpdateController.submit(
          entityType: UpdateEntityType.event,
          entityId: eventId,
          creatorId: currentUser.id,
          data: {
            ...data,
            'media': {
              'add': uploadedUrls,
              'remove': removedMediaIds,
            },
          },
        );

        return const SubmitResult(
          true,
          "Solicitud de actualización enviada para revisión",
        );
      }

      final event = EventModel(
        id: 0,
        creatorId: currentUser.id,
        categoryId: int.parse(selectedCategoryId!),
        name: nameCtrl.text.trim(),
        description: descCtrl.text.trim(),
        startDate: startAt!,
        endDate: endAt!,
        capacity: attendeesCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(attendeesCtrl.text.trim()),
        tinkuPrice: tinkuPriceCtrl.text.trim().isEmpty
            ? 0
            : int.tryParse(tinkuPriceCtrl.text.trim()),
        address: address,
        latitude: lat,
        longitude: lng,
        status: EventStatus.pending,
        businessId: selectedBusinessId != null
            ? int.tryParse(selectedBusinessId!)
            : null,
        createdAt: DateTime.now(),
      );

      final created = await _eventSvc.create(event);
      final id = created.id;

      await media.uploadNew(
        target: EntityMediaTarget(
          entityId: id,
          entityType: MediaEntityType.event,
        ),
      );

      return const SubmitResult(true, "Evento creado con éxito");
    } catch (e) {
      return SubmitResult(false, userFacingError(e));
    } finally {
      loading = false;
      _safeNotify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    nameCtrl.dispose();
    descCtrl.dispose();
    attendeesCtrl.dispose();
    tinkuPriceCtrl.dispose();
    media.removeListener(notifyListeners);
    transportC.removeListener(notifyListeners);
    super.dispose();
  }
}
