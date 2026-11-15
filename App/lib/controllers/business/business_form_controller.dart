import 'package:flutter/material.dart';

import '../../core/enums.dart';
import '../../models/business_model.dart';
import '../../models/media_target.dart';
import '../../services/business_service.dart';
import '../../services/category_service.dart';
import '../shared/entity_updates/entity_update_controller.dart';
import '../shared/media/media_controller.dart';
import '../shared/opening_hours/opening_hours_controller.dart';
import '../shared/social/social_links_controller.dart';
import '../shared/transport/entity_transport_controller.dart';

class SubmitResult {
  final bool ok;
  final String message;

  const SubmitResult(this.ok, this.message);
}

class BusinessFormController extends ChangeNotifier {
  BusinessFormController(
      this._businessSvc,
      this._categorySvc,
      this._entityUpdateController,
      this.media,
      this.hours,
      this.transport,
      this.socials,
      ) {
    media.addListener(notifyListeners);
    hours.addListener(notifyListeners);
    transport.addListener(notifyListeners);
    socials.addListener(notifyListeners);
  }

  bool get isEditing => _original != null;
  int get originalId => _original?.id ?? 0;
  List<dynamic> get images => media.items;

  // Services
  final BusinessService _businessSvc;
  final CategoryService _categorySvc;
  final EntityUpdateController _entityUpdateController;

  // controllers inyectados
  final MediaController media;
  final OpeningHoursController hours;
  final EntityTransportController transport;
  final SocialLinksController socials;

  BusinessModel? _original;
  bool loading = false;
  Map<int, String> categories = {};

  // Form fields
  final nameCtrl = TextEditingController();
  final nitCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final websiteCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final emailCtrl = TextEditingController();

  int? selectedCategoryId;

  // -------------------------------------------------------------
  // LOAD INITIAL DATA
  // -------------------------------------------------------------
  Future<void> loadInitialData({required BusinessType type}) async {
    final cats = await _categorySvc.getActive(
      entityType: CategoryEntityType.business,
      businessType: type,
    );
    categories = {for (var c in cats) c.id: c.name};

    transport.reset();
    socials.reset();

    hours.setDraftContext(
      entityType: OpeningEntity.business,
    );
  }

  void setCategory(int? id) {
    selectedCategoryId = id;
    notifyListeners();
  }

  // -------------------------------------------------------------
  // LOAD BUSINESS FOR EDITING
  // -------------------------------------------------------------
  Future<void> loadForm(BusinessModel b) async {
    _original = b;
    notifyListeners();

    if (categories.isEmpty) {
      await loadInitialData(type: b.businessType);
    }

    transport.setContext(
      entityType: VisitEntity.business,
      entityId: b.id,
    );

    nameCtrl.text = b.name;
    nitCtrl.text = b.nit ?? '';
    phoneCtrl.text = b.phone ?? '';
    websiteCtrl.text = b.website ?? '';
    descCtrl.text = b.description ?? '';
    emailCtrl.text = b.email ?? '';
    selectedCategoryId = b.categoryId;

    await Future.wait([
      media.load(
        target: EntityMediaTarget(
          entityId: b.id,
          entityType: MediaEntityType.business,
        ),
      ),
      hours.load(
        entityType: OpeningEntity.business,
        entityId: b.id,
      ),
      socials.load(entityId: b.id),
    ]);
  }

  // -------------------------------------------------------------
  // SUBMIT
  // -------------------------------------------------------------
  Future<SubmitResult> submit({
    required BusinessType type,
    required String address,
    required double lat,
    required double lng,
    required GlobalKey<FormState> formKey,
    required String userRole,
    String? userId,
  }) async {
    if (!(formKey.currentState?.validate() ?? false) ||
        selectedCategoryId == null) {
      return const SubmitResult(false, "Faltan datos obligatorios");
    }

    if (hours.operatingHours.isEmpty) {
      return const SubmitResult(false, "Agregue al menos un horario de apertura");
    }

    loading = true;
    notifyListeners();

    final typeStr = businessTypeToString(type);
    final isAdmin = userRole == 'admin' || userRole == 'master';

    try {
      final baseData = _buildBusinessData(
        type: type,
        address: address,
        lat: lat,
        lng: lng,
        isAdmin: isAdmin,
      );

      // =========================
      // CREATE
      // =========================
      if (!isEditing) {
        final b = BusinessModel(
          id: 0,
          categoryId: selectedCategoryId!,
          ownerId: userId!,
          name: nameCtrl.text.trim(),
          nit: nitCtrl.text.trim().isEmpty ? null : nitCtrl.text.trim(),
          description: descCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
          email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
          businessType: type,
          address: address,
          latitude: lat,
          longitude: lng,
          website: websiteCtrl.text.trim(),
          validated: isAdmin,
          status: BusinessStatus.active,
        );

        final created = await _businessSvc.create(b);
        final id = created.id;

        hours.setContext(
          entityType: OpeningEntity.business,
          entityId: id,
        );

        await media.saveDirect(
          target: EntityMediaTarget(
            entityId: id,
            entityType: MediaEntityType.business,
          ),
        );

        await hours.save();
        await socials.save(entityId: id);

        final label = type == BusinessType.service ? 'Servicio' : 'Negocio';
        return SubmitResult(true, "$label creado con éxito");
      }

      // =========================
      // UPDATE
      // =========================
      final id = _original!.id;

      // ADMIN / MASTER: edición directa completa
      if (isAdmin) {
        await _businessSvc.update(id, {
          ...baseData,
          'business_type': typeStr,
          'location': {
            'latitude': lat,
            'longitude': lng,
          },
          'updated_at': DateTime.now().toIso8601String(),
        });

        await media.saveDirect(
          target: EntityMediaTarget(
            entityId: id,
            entityType: MediaEntityType.business,
          ),
        );

        await hours.save();
        await socials.save(entityId: id);

        final label = type == BusinessType.service ? 'Servicio' : 'Negocio';
        return SubmitResult(true, "$label actualizado con éxito");
      }

      // PARTNER: solicitud completa de actualización
      final removedMediaIds = media.deletedMediaIds;
      final uploadedUrls = await media.uploadNew(
        target: EntityMediaTarget(
          entityId: id,
          entityType: MediaEntityType.business,
        ),
        uploadMode: 'storage_only',
      );

      await _entityUpdateController.submit(
        entityType: UpdateEntityType.business,
        entityId: id,
        creatorId: userId!,
        data: {
          ...baseData,
          'business_type': typeStr,
          'media': {
            'add': uploadedUrls,
            'remove': removedMediaIds,
          },
          'socials': _buildSocialsData(),
          'hours': _buildHoursData(),
        },
      );

      return const SubmitResult(
        true,
        "Solicitud de actualización enviada para revisión",
      );
    } catch (e) {
      return SubmitResult(false, "Error: $e");
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    nitCtrl.dispose();
    phoneCtrl.dispose();
    websiteCtrl.dispose();
    descCtrl.dispose();
    emailCtrl.dispose();

    media.dispose();
    hours.dispose();
    transport.dispose();
    socials.dispose();

    super.dispose();
  }

  // =========================
  // HELPERS
  // =========================

  Map<String, dynamic> _buildBusinessData({
    required BusinessType type,
    required String address,
    required double lat,
    required double lng,
    required bool isAdmin,
  }) {
    return {
      'name': nameCtrl.text.trim(),
      'nit': nitCtrl.text.trim().isEmpty ? null : nitCtrl.text.trim(),
      'phone': phoneCtrl.text.trim(),
      'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
      'address': address,
      'latitude': lat,
      'longitude': lng,
      'website': websiteCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'category_id': selectedCategoryId,
      'validated': isAdmin ? (_original?.validated ?? true) : _original?.validated,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  List<Map<String, dynamic>> _buildSocialsData() {
    return socials.socialNetworks
        .map(
          (s) => {
        'platform': s.platform.trim().toLowerCase(),
        'url': s.url.trim(),
      },
    )
        .toList();
  }

  List<Map<String, dynamic>> _buildHoursData() {
    return hours.operatingHours
        .map(
          (h) => {
        'week_day': h.weekDay.name,
        'start_time': h.startTime,
        'end_time': h.endTime,
      },
    )
        .toList();
  }
}
