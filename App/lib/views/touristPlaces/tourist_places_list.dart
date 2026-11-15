import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:tinkuapp/core/enums.dart';
import 'package:tinkuapp/views/touristPlaces/tourist_place_form_page.dart';

import '../../components/utils.dart';
import '../../helpers/error_message_helper.dart';
import '../../models/tourist_place_model.dart';
import '../../providers/user_provider.dart';
import '../../services/tourist_place_service.dart';
import '../../ui/themes/colors.dart';
import 'tourist_place_detail.dart';
import '../../widgets/common/empty/app_empty.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';

class TouristPlaces extends StatefulWidget {
  const TouristPlaces({super.key});

  @override
  State<TouristPlaces> createState() => _TouristPlacesState();
}

class _TouristPlacesState extends State<TouristPlaces> {
  late TouristPlaceService _service;

  bool _initialized = false;

  List<TouristPlaceModel> _places = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final auth = context.read<UserProvider>().authService;

    _service = TouristPlaceService(auth);

    _loadPlaces(reset: true);

    _initialized = true;
  }

  Future<void> _loadPlaces({bool reset = false}) async {
    if (_loadingMore) return;

    if (reset) {
      _offset = 0;
      _hasMore = true;
      setState(() => _loading = true);
    } else {
      if (!_hasMore) return;
      setState(() => _loadingMore = true);
    }

    try {
      final role = context.read<UserProvider>().user?.role;
      final canManageTouristPlaces =
          role == UserRole.admin || role == UserRole.master;
      final data = canManageTouristPlaces
          ? await _service.getMine(
              limit: _pageSize,
              offset: _offset,
            )
          : await _service.getPreviewList(
              limit: _pageSize,
              offset: _offset,
            );

      if (!mounted) return;

      setState(() {
        _places = reset ? data : [..._places, ...data];
        _offset = _places.length;
        _hasMore = data.length == _pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar(userFacingError(e), isError: true),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _confirmDelete(TouristPlaceModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar lugar?'),
        content: Text('¿Seguro que deseas eliminar "${p.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Eliminar'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        await _service.archive(p.id);
        await _loadPlaces(reset: true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          tinkuSnackBar('Lugar eliminado'),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          tinkuSnackBar(userFacingError(e), isError: true),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final canManageTouristPlaces =
        user?.role == UserRole.admin || user?.role == UserRole.master;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Lugares Turísticos'),
      body: _loading
          ? const AppLoader(message: 'Cargando lugares...')
          : _places.isEmpty
          ? const Center(
              child: AppEmptyState(
                icon: Icons.place_outlined,
                title: 'Sin lugares turísticos',
                subtitle: 'No hay lugares turísticos disponibles.',
                iconColor: AppColors.darkBlue,
              ),
            )
          : RefreshIndicator(
        onRefresh: () => _loadPlaces(reset: true),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          itemCount: _places.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _places.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: _loadingMore
                      ? const CircularProgressIndicator()
                      : TextButton(
                          onPressed: () => _loadPlaces(),
                          child: const Text('Cargar más'),
                        ),
                ),
              );
            }

            final p = _places[index];
            final imageUrl = p.primaryImageUrl;

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TouristPlaceDetail(place: p)),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 12),
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                color: Colors.white,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📷 Imagen
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                      child: imageUrl == null || imageUrl.trim().isEmpty
                          ? Container(
                              width: MediaQuery.of(context).size.width * 0.40,
                              height: 160,
                              color: Colors.grey.shade300,
                              child: const Icon(
                                FontAwesomeIcons.image,
                                size: 40,
                                color: Colors.white,
                              ),
                            )
                          : Image.network(
                              imageUrl,
                              width: MediaQuery.of(context).size.width * 0.40,
                              height: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: MediaQuery.of(context).size.width * 0.40,
                                height: 160,
                                color: Colors.grey.shade300,
                                child: const Icon(
                                  FontAwesomeIcons.image,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),

                    // 📝 Texto y acciones
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              p.description ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                            const SizedBox(height: 10),

                            // 🏷️ Chip de categoría
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.category, size: 14, color: Colors.black87),
                                  const SizedBox(width: 6),
                                  Text(
                                    p.categoryName ?? 'Sin categoría',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (canManageTouristPlaces) ...[
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text('Editar'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.blue.shade700,
                                      padding: EdgeInsets.zero,
                                      textStyle: const TextStyle(fontSize: 13),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TouristPlaceFormPage(
                                            place: p,
                                          ),
                                        ),
                                      ).then((_) => _loadPlaces(reset: true));
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  TextButton.icon(
                                    icon: const Icon(Icons.delete, size: 16),
                                    label: const Text('Eliminar'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red.shade600,
                                      padding: EdgeInsets.zero,
                                      textStyle: const TextStyle(fontSize: 13),
                                    ),
                                    onPressed: () => _confirmDelete(p),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: canManageTouristPlaces
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.darkBlue,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TouristPlaceFormPage()),
                ).then((_) => _loadPlaces(reset: true));
              },
              icon: const Icon(FontAwesomeIcons.plus, color: AppColors.pureWhite),
              label: const Text(
                'Agregar lugar',
                style: TextStyle(color: AppColors.pureWhite),
              ),
            )
          : null,
    );
  }
}
