import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tinkuapp/core/enums.dart';

import '../../components/utils.dart';
import '../../models/tourist_place_model.dart';
import '../../models/media_model.dart';
import '../../models/tag_model.dart';
import '../../models/tourist_place_tag_model.dart';
import '../../models/opening_hour_model.dart';

import '../../providers/user_provider.dart';
import '../../services/tourist_place_service.dart';
import '../../services/category_service.dart';
import '../../services/storage_service.dart';
import '../../services/media_service.dart';
import '../../services/tag_service.dart';
import '../../services/tourist_place_tag_service.dart';
import '../../services/opening_hour_service.dart';

import '../../ui/themes/colors.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';

class TouristPlaceFormPage extends StatefulWidget {
  final bool editing;
  final TouristPlaceModel? place;

  const TouristPlaceFormPage({super.key, this.editing = false, this.place});

  @override
  State<TouristPlaceFormPage> createState() => _TouristPlaceFormPageState();
}

class _TouristPlaceFormPageState extends State<TouristPlaceFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TouristPlaceService _placeService;
  late CategoryService _categoryService;
  late StorageService _storageService;
  late MediaService _mediaService;
  late TagService _tagService;
  late TouristPlaceTagService _tpTagService;
  late OpeningHourService _hourService;

  bool _initialized = false;

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _hourCtrl = TextEditingController();

  final List<String> _tags = [];
  final List<String> _hours = [];
  final List<XFile> _newImages = [];
  final List<String> _existingUrls = [];

  String? _selectedCategoryId;
  String _address = '';
  LatLng _mapCenter = const LatLng(-17.3936, -66.1570);
  LatLng? _selectedLocation;

  bool _loading = false;
  Map<String, String> _categories = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final auth = context.read<UserProvider>().authService;

    _placeService = TouristPlaceService(auth);
    _categoryService = CategoryService(auth);
    _storageService = StorageService(auth);
    _mediaService = MediaService(auth);
    _tagService = TagService(auth);
    _tpTagService = TouristPlaceTagService(auth);
    _hourService = OpeningHourService(auth);

    _loadInitialData();

    if (widget.editing && widget.place != null) {
      _prefillFromModel(widget.place!);
    }

    _initialized = true;
  }

  Future<void> _loadInitialData() async {
    final cats = await _categoryService.getActive(entityType: CategoryEntityType.tourist_place);
    if (!mounted) return;
    setState(() {
      _categories = {for (var c in cats) c.id.toString(): c.name};
    });
  }

  void _prefillFromModel(TouristPlaceModel place) {
    _nameCtrl.text = place.name;
    _descCtrl.text = place.description ?? '';
    _selectedCategoryId = place.categoryId.toString();
    _selectedLocation = LatLng(place.latitude, place.longitude);
    _mapCenter = _selectedLocation!;
    _address = place.address ?? '';
  }

  Future<void> _onMapTap(LatLng pos) async {
    setState(() => _selectedLocation = pos);
    try {
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        _address = '${p.street}, ${p.locality}, ${p.country}';
      }
    } catch (_) {
      _address = '(${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)})';
    }
    setState(() {});
  }

  void _addTag() {
    final tag = _tagCtrl.text.trim();
    if (tag.isNotEmpty) {
      setState(() {
      _tags.add(tag);
      _tagCtrl.clear();
    });
    }
  }

  void _removeTag(String tag) => setState(() => _tags.remove(tag));

  void _addHour() {
    final h = _hourCtrl.text.trim();
    if (h.isNotEmpty) {
      setState(() {
      _hours.add(h);
      _hourCtrl.clear();
    });
    }
  }

  void _removeHour(String h) => setState(() => _hours.remove(h));

  void _removeExisting(String url) => setState(() => _existingUrls.remove(url));
  void _removeNew(XFile x) => setState(() => _newImages.remove(x));

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final imgs = await picker.pickMultiImage();
    if (imgs.isNotEmpty) setState(() => _newImages.addAll(imgs));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _selectedCategoryId == null ||
        _selectedLocation == null) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _loading = true);

    try {
      if (widget.editing && widget.place != null) {
        // -------- ACTUALIZAR --------
        final updates = {
          'name': _nameCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'address': _address,
          'location': {
            'latitude': _selectedLocation!.latitude,
            'longitude': _selectedLocation!.longitude,
          },
          'category_id': int.parse(_selectedCategoryId!),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await _placeService.update(widget.place!.id, updates);

        // Subir nuevas imágenes
        if (_newImages.isNotEmpty) {
          final urls = await _storageService.uploadFiles(
            entityType: MediaEntityType.tourist_place,
            entityId: widget.place!.id,
            files: _newImages,
            uploadMode: 'direct',
          );
          for (final url in urls) {
            await _mediaService.create(MediaModel(
              id: 0,
              entityId: widget.place!.id.toString(),
              entityType: MediaEntityType.tourist_place,
              url: url,
              type: MediaType.image,
              displayOrder: 0,
              isPrimary: false,
              createdAt: DateTime.now(),
              updatedAt: null,
            ));
          }
        }

        if (!mounted) return;

        messenger.showSnackBar(
          tinkuSnackBar("Lugar actualizado con éxito"),
        );
      } else {
        // -------- CREAR NUEVO --------
        final place = TouristPlaceModel(
          id: 0,
          categoryId: int.parse(_selectedCategoryId!),
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          address: _address,
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
          status: BasicStatus.active,
          createdAt: DateTime.now(),
          updatedAt: null,
        );

        final created = await _placeService.create(place);
        final id = created.id;

        // Imágenes
        if (_newImages.isNotEmpty) {
          final urls = await _storageService.uploadFiles(
            entityType: MediaEntityType.tourist_place,
            entityId: id,
            files: _newImages,
            uploadMode: 'direct',
          );
          for (final url in urls) {
            await _mediaService.create(MediaModel(
              id: 0,
              entityId: id.toString(),
              entityType: MediaEntityType.tourist_place,
              url: url,
              type: MediaType.image,
              displayOrder: 0,
              isPrimary: false,
              createdAt: DateTime.now(),
              updatedAt: null,
            ));
          }
        }

        // Etiquetas
        for (final t in _tags) {
          final tag = await _tagService.create(TagModel(
            id: 0,
            name: t,
            description: null,
            status: BasicStatus.active,
            createdAt: DateTime.now(),
            updatedAt: null,
          ));
          await _tpTagService.create(TouristPlaceTagModel(
            touristPlaceId: id,
            tagId: tag.id,
          ));
        }

        // Horarios
        await _hourService.create(OpeningHourModel(
          id: 0,
          entityId: id,
          entityType: OpeningEntity.tourist_place,
          weekDay: WeekDay.monday,
          startTime: "10:00",
          endTime: "18:00",
          createdAt: DateTime.now(),
          updatedAt: null,
        ));

        messenger.showSnackBar(
          tinkuSnackBar("Lugar guardado con éxito"),
        );
      }

      if (!mounted) return;
      navigator.pop(true);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        tinkuSnackBar("Error: $e", isError: true),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing;
    return Scaffold(
      appBar: CustomAppBar(
        title: isEdit ? "Editar Lugar Turístico" : "Agregar Lugar Turístico",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: "Nombre"),
              validator: (v) =>
              v == null || v.isEmpty ? "Campo obligatorio" : null,
            ),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: "Descripción"),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Categoría"),
              initialValue: _selectedCategoryId,
              items: _categories.entries
                  .map((e) =>
                  DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategoryId = v),
              validator: (v) => v == null ? "Seleccione una categoría" : null,
            ),
            const SizedBox(height: 16),
            const Text("Ubicación", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 350,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(target: _mapCenter, zoom: 14),
                  markers: _selectedLocation != null
                      ? {Marker(markerId: const MarkerId("pos"), position: _selectedLocation!)}
                      : {},
                  onTap: _onMapTap,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(_address.isEmpty
                ? "Toca el mapa para seleccionar una ubicación"
                : _address,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            const Text("Etiquetas", style: TextStyle(fontWeight: FontWeight.bold)),
            Row(children: [
              Expanded(
                child: TextFormField(
                    controller: _tagCtrl,
                    decoration: const InputDecoration(
                        hintText: "Ej: naturaleza, histórico")),
              ),
              IconButton(onPressed: _addTag, icon: const Icon(Icons.add))
            ]),
            Wrap(
                spacing: 6,
                children: _tags
                    .map((t) => Chip(label: Text(t), onDeleted: () => _removeTag(t)))
                    .toList()),
            const SizedBox(height: 16),
            const Text("Imágenes", style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._existingUrls.map((url) => Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(url,
                        width: 100, height: 100, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () => _removeExisting(url),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  )
                ])),
                ..._newImages.map((x) => Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(x.path),
                        width: 100, height: 100, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () => _removeNew(x),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  )
                ])),
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade200,
                      border: Border.all(color: Colors.grey),
                    ),
                    child: const Icon(Icons.add_a_photo, color: Colors.grey),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            const Text("Horarios", style: TextStyle(fontWeight: FontWeight.bold)),
            Row(children: [
              Expanded(
                child: TextFormField(
                    controller: _hourCtrl,
                    decoration:
                    const InputDecoration(hintText: "Ej: Todos los días 10:00-18:00")),
              ),
              IconButton(onPressed: _addHour, icon: const Icon(Icons.add))
            ]),
            Wrap(
                spacing: 6,
                children: _hours
                    .map((h) => Chip(label: Text(h), onDeleted: () => _removeHour(h)))
                    .toList()),
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEdit ? "Guardar Cambios" : "Crear Lugar Turístico",
                      style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _tagCtrl.dispose();
    _hourCtrl.dispose();
    super.dispose();
  }
}
