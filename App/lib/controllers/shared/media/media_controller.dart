import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../components/utils.dart';
import '../../../models/media_model.dart';
import '../../../models/media_target.dart';
import '../../../services/media_service.dart';
import '../../../services/storage_service.dart';

class MediaController extends ChangeNotifier {
  MediaController(
      this._storageService,
      this._mediaService,
      );

  final StorageService _storageService;
  final MediaService _mediaService;

  // =========================
  // STATE
  // =========================
  final List<MediaModel> existingMedia = [];
  final List<MediaModel> deletedMedia = [];
  final List<XFile> newMedia = [];

  bool loading = false;

  // =========================
  // GETTERS
  // =========================
  List<dynamic> get items => [...existingMedia, ...newMedia];

  List<int> get deletedMediaIds => deletedMedia.map((m) => m.id).toList();

  bool _isImagePath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  bool _isPdfPath(String path) {
    return path.toLowerCase().endsWith('.pdf');
  }

  bool _isSupportedPath(String path) {
    return _isImagePath(path) || _isPdfPath(path);
  }

  // =========================
  // LOAD
  // =========================
  Future<void> load({
    required MediaTarget target,
  }) async {
    loading = true;
    notifyListeners();

    try {
      existingMedia.clear();
      deletedMedia.clear();
      newMedia.clear();

      final media = await _mediaService.getByEntity(
        entityId: target.id.toString(),
        entityType: target.type,
      );

      existingMedia.addAll(media);
      notifyListeners();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setLoaded(List<MediaModel> media) {
    existingMedia
      ..clear()
      ..addAll(media);
    deletedMedia.clear();
    newMedia.clear();
    loading = false;
    notifyListeners();
  }

  // =========================
  // PICK FILES
  // =========================
  Future<void> pickImagesFromGallery(BuildContext context) async {
    const maxFiles = 10;

    final picker = ImagePicker();
    final result = await picker.pickMultiImage();

    if (result.isEmpty) return;
    if (!context.mounted) return;

    final currentTotal = existingMedia.length + newMedia.length;
    final remaining = maxFiles - currentTotal;

    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar(
          "Solo puedes agregar hasta 10 imágenes",
          isError: true,
        ),
      );
      return;
    }

    newMedia.addAll(result.take(remaining));
    notifyListeners();

    if (result.length > remaining) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar("Solo se agregaron $remaining imágenes (máximo 10)"),
      );
    }
  }

  Future<void> pickFiles(BuildContext context) async {
    const maxFiles = 10;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
        'webp',
        'gif',
        'pdf',
      ],
    );

    if (result == null || result.files.isEmpty) return;
    if (!context.mounted) return;

    final currentTotal = existingMedia.length + newMedia.length;
    final remaining = maxFiles - currentTotal;

    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar(
          "Solo puedes agregar hasta 10 archivos",
          isError: true,
        ),
      );
      return;
    }

    final validFiles = result.files
        .where((f) => f.path != null && _isSupportedPath(f.path!))
        .take(remaining)
        .toList();

    if (validFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar("Solo se permiten imágenes o PDFs", isError: true),
      );
      return;
    }

    newMedia.addAll(
      validFiles.map(
            (f) => XFile(
          f.path!,
          name: f.name,
          mimeType: f.extension == 'pdf' ? 'application/pdf' : null,
        ),
      ),
    );

    notifyListeners();

    if (result.files.length > remaining) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar("Solo se agregaron $remaining archivos (máximo 10)"),
      );
    }
  }

  // =========================
  // REMOVE FILE
  // =========================
  void removeItem(dynamic item) {
    if (item is MediaModel) {
      deletedMedia.add(item);
      existingMedia.remove(item);
    } else if (item is XFile) {
      newMedia.remove(item);
    }

    notifyListeners();
  }

  void undoRemove(MediaModel media) {
    deletedMedia.removeWhere((m) => m.id == media.id);
    existingMedia.add(media);
    notifyListeners();
  }

  // =========================
  // UPLOAD ONLY NEW FILES
  // =========================
  Future<List<String>> uploadNew({
    required MediaTarget target,
    String uploadMode = 'direct',
  }) async {
    loading = true;
    notifyListeners();

    try {
      if (newMedia.isEmpty) return [];

      final uploadedUrls = await _storageService.uploadFiles(
        entityType: target.type,
        entityId: target.id,
        files: newMedia,
        uploadMode: uploadMode,
      );

      newMedia.clear();
      return uploadedUrls;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // =========================
  // DELETE ONLY MARKED FILES
  // =========================
  Future<void> commitDeletes() async {
    loading = true;
    notifyListeners();

    try {
      for (final media in deletedMedia) {
        await _storageService.deleteFile(media.id);
      }

      deletedMedia.clear();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // =========================
  // DIRECT SAVE
  // =========================
  Future<List<String>> saveDirect({
    required MediaTarget target,
  }) async {
    loading = true;
    notifyListeners();

    try {
      final uploadedUrls = await uploadNew(
        target: target,
        uploadMode: 'direct',
      );
      await commitDeletes();
      return uploadedUrls;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // =========================
  // RESET
  // =========================
  void reset() {
    existingMedia.clear();
    deletedMedia.clear();
    newMedia.clear();
    notifyListeners();
  }
}
