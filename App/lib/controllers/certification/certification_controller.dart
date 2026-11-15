import 'package:flutter/material.dart';

import '../../core/enums.dart';
import '../../models/business_model.dart';
import '../../models/certification_model.dart';
import '../../services/business_service.dart';
import '../../services/certification_service.dart';
import '../../services/media_service.dart';

class CertificationController extends ChangeNotifier {
  CertificationController(
    this._certService,
    this._businessService,
    this._mediaService,
  );

  final CertificationService _certService;
  final BusinessService _businessService;
  final MediaService _mediaService;

  // =========================
  // STATE
  // =========================
  List<CertificationModel> certifications = [];
  List<BusinessModel> businesses = [];

  final Map<int, List<String>> certificationMedia = {};

  bool loading = false;

  int _filterOrder = 0;
  int selectedBusinessId = 0;

  int get filterOrder => _filterOrder;

  void setFilterOrder(int value) {
    if (_filterOrder == value) return;
    _filterOrder = value;
    notifyListeners();
  }

  void setSelectedBusiness(int value) {
    if (selectedBusinessId == value) return;
    selectedBusinessId = value;
    notifyListeners();
  }

  void resetFilters() {
    _filterOrder = 0;
    selectedBusinessId = 0;
    notifyListeners();
  }

  // =========================
  // LOAD INITIAL
  // =========================
  Future<void> loadMine() async {
    loading = true;
    notifyListeners();

    try {
      final loadedBusinesses = await _businessService.getMine();
      final loaded = await _fetchCertifications(
        businessId: 0,
        sourceBusinesses: loadedBusinesses,
      );
      businesses = loadedBusinesses;
      selectedBusinessId = 0;
      certifications = loaded.items;
      certificationMedia
        ..clear()
        ..addAll(loaded.media);
    } catch (_) {
      // Conserva los últimos datos válidos ante errores temporales.
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // =========================
  // LOAD BY BUSINESS
  // =========================
  Future<void> loadByBusiness(int businessId) async {
    loading = true;
    notifyListeners();

    try {
      final loaded = await _fetchCertifications(
        businessId: businessId,
        sourceBusinesses: businesses,
      );
      selectedBusinessId = businessId;
      certifications = loaded.items;
      certificationMedia
        ..clear()
        ..addAll(loaded.media);
    } catch (_) {
      // La selección y el contenido previo permanecen visibles.
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setBusinessCertifications({
    required int businessId,
    required List<CertificationModel> items,
    required Map<int, List<String>> mediaUrlsByCertification,
  }) {
    certifications = items;
    businesses = [];
    selectedBusinessId = businessId;
    certificationMedia
      ..clear()
      ..addAll(mediaUrlsByCertification);
    loading = false;
    notifyListeners();
  }

  Future<
      ({
        List<CertificationModel> items,
        Map<int, List<String>> media,
      })> _fetchCertifications({
    required int businessId,
    required List<BusinessModel> sourceBusinesses,
  }) async {
    List<CertificationModel> certs = [];

    if (businessId == 0) {
      final certsByBusiness = await _certService.getByBusinesses(
        businessIds: sourceBusinesses.map((b) => b.id).toList(),
      );

      certs = certsByBusiness.values.expand((items) => items).toList();
    } else {
      certs = await _certService.getByBusiness(businessId);
    }

    final mediaResult = <int, List<String>>{};
    final ids = certs.map((cert) => cert.id).toList();
    if (ids.isEmpty) return (items: certs, media: mediaResult);

    try {
      final mediaMap = await _mediaService.getByEntities(
        entityIds: ids,
        entityType: MediaEntityType.certification,
      );

      for (final cert in certs) {
        final media = mediaMap[cert.id] ?? [];
        mediaResult[cert.id] = media.map((m) => m.url).toList();
      }
    } catch (_) {
      for (final cert in certs) {
        mediaResult[cert.id] = [];
      }
    }
    return (items: certs, media: mediaResult);
  }

  // =========================
  // CRUD
  // =========================
  Future<bool> deleteCertification(int id) async {
    try {
      await _certService.softDelete(id);

      certifications.removeWhere((c) => c.id == id);
      certificationMedia.remove(id);

      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> refresh() async {
    await loadByBusiness(selectedBusinessId);
  }

  // =========================
  // SELECTORS / DERIVED
  // =========================
  Map<int, String> get businessSelectorItems {
    return {
      0: 'Todos mis negocios',
      for (final b in businesses) b.id: b.name,
    };
  }

  Set<int> get disabledBusinessSelectorIds {
    return businesses
        .where((b) => !b.validated || b.status != BusinessStatus.active)
        .map((b) => b.id)
        .toSet();
  }

  List<CertificationModel> get filteredCertifications {
    final list = List<CertificationModel>.from(certifications);

    list.sort((a, b) {
      if (_filterOrder == 0) {
        return b.createdAt.compareTo(a.createdAt);
      }
      return a.createdAt.compareTo(b.createdAt);
    });

    return list;
  }

  String businessNameFor(int businessId) {
    for (final b in businesses) {
      if (b.id == businessId) return b.name;
    }
    return 'Sin negocio';
  }

  List<String> getMedia(int certId) => certificationMedia[certId] ?? [];

  bool get hasBusinesses => businesses.isNotEmpty;
  bool get hasData => certifications.isNotEmpty;

  void _clearData() {
    businesses = [];
    certifications = [];
    certificationMedia.clear();
    selectedBusinessId = 0;
  }

  void reset() {
    _clearData();
    _filterOrder = 0;
    loading = false;
    notifyListeners();
  }
}
