import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/enums.dart';
import '../../helpers/error_message_helper.dart';
import '../../models/certification_model.dart';
import '../../services/certification_service.dart';
import '../../services/media_service.dart';
import '../../services/storage_service.dart';

class CertificationFormController extends ChangeNotifier {
  CertificationFormController(
      this._service,
      this._storageService,
      this._mediaService,
      );

  final CertificationService _service;
  final StorageService _storageService;
  final MediaService _mediaService;

  final formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final licenseCtrl = TextEditingController();

  File? _pdfFile;
  String? _pdfName;
  String? _pdfUrl;

  CertificationModel? _certification;

  bool loading = false;

  bool get editing => _certification != null;
  bool get hasPdf => _pdfFile != null || _pdfUrl != null;

  String? get pdfName {
    if (_pdfName != null) return _pdfName;
    if (_pdfUrl == null) return null;
    return _extractFileName(_pdfUrl!);
  }

  String? get pdfUrl => _pdfUrl;
  File? get pdfFile => _pdfFile;

  Future<void> init({CertificationModel? certification}) async {
    _certification = certification;

    if (certification == null) {
      notifyListeners();
      return;
    }

    nameCtrl.text = certification.name;
    licenseCtrl.text = certification.licenseNumber ?? '';

    try {
      final mediaList = await _mediaService.getByEntity(
        entityId: certification.id.toString(),
        entityType: MediaEntityType.certification,
      );

      if (mediaList.isNotEmpty) {
        _pdfUrl = mediaList.first.url;
        _pdfName = _extractFileName(_pdfUrl!);
      }
    } catch (_) {
      _pdfUrl = null;
      _pdfName = null;
    }

    notifyListeners();
  }

  Future<bool> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );

    if (result == null || result.files.single.path == null) {
      return false;
    }

    _pdfFile = File(result.files.single.path!);
    _pdfName = result.files.single.name;
    _pdfUrl = null;

    notifyListeners();
    return true;
  }

  void clearPdf() {
    _pdfFile = null;
    _pdfName = null;
    _pdfUrl = null;
    notifyListeners();
  }

  Future<String?> submit({
    required int businessId,
  }) async {
    if (loading) return 'Ya se está guardando';
    if (!(formKey.currentState?.validate() ?? false)) {
      return 'Completá los campos requeridos';
    }

    if (!hasPdf) {
      return 'Seleccioná el PDF';
    }

    loading = true;
    notifyListeners();

    try {
      final cert = CertificationModel(
        id: editing ? _certification!.id : 0,
        businessId: businessId,
        name: nameCtrl.text.trim(),
        licenseNumber: licenseCtrl.text.trim().isEmpty
            ? null
            : licenseCtrl.text.trim(),
        status: BasicStatus.active,
        createdAt: editing ? _certification!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final saved = editing
          ? await _service.patchCertification(cert.id, cert.toJson())
          : await _service.create(cert);

      if (_pdfFile != null) {
        final existingMedia = await _mediaService.getByEntity(
          entityId: saved.id.toString(),
          entityType: MediaEntityType.certification,
        );

        for (final media in existingMedia) {
          await _mediaService.delete(media.id);
        }

        final url = await _storageService.uploadSingleFile(
          entityType: MediaEntityType.certification,
          entityId: saved.id,
          file: XFile(_pdfFile!.path),
        );

        _pdfUrl = url;
        _pdfName = _extractFileName(url);
      }

      return null;
    } catch (e) {
      return userFacingError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  String _extractFileName(String url) {
    final cleanUrl = url.split('?').first;
    final parts = cleanUrl.split(RegExp(r'[\\/]+'));
    return parts.isNotEmpty ? parts.last : cleanUrl;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    licenseCtrl.dispose();
    super.dispose();
  }
}
