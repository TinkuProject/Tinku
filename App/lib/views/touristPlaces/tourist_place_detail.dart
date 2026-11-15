import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:tinkuapp/core/enums.dart';
import 'package:tinkuapp/services/tourist_place_tag_service.dart';
import '../../models/media_model.dart';
import '../../models/opening_hour_model.dart';

import '../../models/tag_model.dart';
import '../../models/tourist_place_model.dart';
import '../../models/transport_line_model.dart';
import '../../models/user_visit_model.dart';
import '../../services/category_service.dart';
import '../../services/entity_transport_relation_service.dart';
import '../../services/transport_line_service.dart';
import '../../services/user_visit_service.dart';
import '../../services/media_service.dart';
import '../../services/opening_hour_service.dart';
import '../../providers/user_provider.dart';
import '../../ui/themes/colors.dart';
import '../../utils/dialogs/auth_dialogs.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/layout/section_block.dart';
import '../../widgets/tourist_places/tourist_place_header.dart';

class TouristPlaceDetail extends StatefulWidget {
  final TouristPlaceModel place;

  const TouristPlaceDetail({super.key, required this.place});

  @override
  State<TouristPlaceDetail> createState() => _TouristPlaceDetailState();
}

class _TouristPlaceDetailState extends State<TouristPlaceDetail> {
  String categoryName = '';
  bool _isVisited = false;
  UserVisitModel? _visit;

  late TransportLineService _transportService;
  late CategoryService _categoryService;
  late UserVisitService _visitedPlaceService;
  late MediaService _mediaService;
  late TouristPlaceTagService _tagService;
  late OpeningHourService _openingHourService;
  late EntityTransportRelationService _relationService;

  bool _initialized = false;
  late Future<List<MediaModel>> _mediaFuture;
  late Future<List<TagModel>> _tagsFuture;
  late Future<List<OpeningHourModel>> _hoursFuture;
  late Future<List<TransportLineModel>> _transportFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final auth = context.read<UserProvider>().authService;

    _transportService = TransportLineService(auth);
    _categoryService = CategoryService(auth);
    _visitedPlaceService = UserVisitService(auth);
    _mediaService = MediaService(auth);
    _tagService = TouristPlaceTagService(auth);
    _openingHourService = OpeningHourService(auth);
    _relationService = EntityTransportRelationService(auth);

    _mediaFuture = _mediaService.getByEntity(
      entityId: widget.place.id.toString(),
      entityType: MediaEntityType.tourist_place,
    );
    _tagsFuture = _tagService.getByPlace(widget.place.id);
    _hoursFuture = _openingHourService.getByEntity(
      entityId: widget.place.id,
      entityType: OpeningEntity.tourist_place,
    );
    _transportFuture = _loadTransportLines();

    _fetchCategoryName();
    _checkIfVisited();

    _initialized = true;
  }

  Future<void> _fetchCategoryName() async {
    final name =
    await _categoryService.getCategoryName(widget.place.categoryId);
    if (!mounted) return;
    setState(() {
      categoryName = name;
    });
  }

  Future<void> _checkIfVisited() async {
    final visits = await _visitedPlaceService.getByEntity(
      entityType: VisitEntity.tourist_place,
      entityId: widget.place.id,
    );

    if (!mounted) return;
    setState(() {
      _isVisited = visits.isNotEmpty;
      _visit = visits.isNotEmpty ? visits.first : null;
    });
  }

  Future<void> _markAsVisited() async {
    await _visitedPlaceService.createVisit(
      CreateUserVisitModel(
        entityType: VisitEntity.tourist_place,
        entityId: widget.place.id,
        type: VisitType.visited,
      ),
    );
    await _checkIfVisited();
  }

  Future<void> _unmarkAsVisited() async {
    if (_visit == null) return;

    await _visitedPlaceService.deleteByEntity(
      entityType: VisitEntity.tourist_place,
      entityId: widget.place.id,
    );
    await _checkIfVisited();
  }

  Future<List<TransportLineModel>> _loadTransportLines() async {
    final relations = await _relationService.getByEntity(
      entityType: VisitEntity.tourist_place,
      entityId: widget.place.id,
    );

    final ids = relations.map((r) => r.transportLineId).toList();

    if (ids.isEmpty) return [];

    return _transportService.getByIds(ids);
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;

    return Scaffold(
      body: FutureBuilder<List<MediaModel>>(
        future: _mediaFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const AppLoader(message: 'Cargando lugar...');
          }

          final media = snapshot.data!;
          final images = media.map((m) => m.url).toList();
          final mainImage = images.isNotEmpty
              ? images.first
              : "https://via.placeholder.com/400";

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              TouristPlaceHeader(
                image: mainImage,
                name: place.name,
                category: categoryName,
                isVisited: _isVisited,
                onVisitedTap: _handleVisitedClick,
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// 📍 DIRECCIÓN (INFO RÁPIDA)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.place, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                place.address ?? "Sin dirección",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// 📝 DESCRIPCIÓN
                      if (place.description != null &&
                          place.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Text(
                            place.description!,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                      /// 🏷️ TAGS
                      FutureBuilder<List<TagModel>>(
                        future: _tagsFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final tags = snapshot.data!;

                          return AnimatedOpacity(
                            opacity: 1,
                            duration: const Duration(milliseconds: 400),
                            child: SectionBlock(
                              title: "Etiquetas",
                              icon: Icons.label,
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: tags.map((tag) {
                                  return Container(
                                    padding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightBlue
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                      BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      tag.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                        FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),

                      /// 🗺️ MAPA
                      AnimatedOpacity(
                        opacity: 1,
                        duration: const Duration(milliseconds: 400),
                        child: SectionBlock(
                          title: "Ubicación",
                          icon: Icons.map,
                          child: ClipRRect(
                            borderRadius:
                            BorderRadius.circular(18),
                            child: SizedBox(
                              height: 200,
                              child: GoogleMap(
                                initialCameraPosition:
                                CameraPosition(
                                  target: LatLng(
                                    place.latitude,
                                    place.longitude,
                                  ),
                                  zoom: 12,
                                ),
                                markers: {
                                  Marker(
                                    markerId:
                                    const MarkerId("place"),
                                    position: LatLng(
                                      place.latitude,
                                      place.longitude,
                                    ),
                                    onTap: () async {
                                      final allowed =
                                      await _requireAuth();
                                      if (!allowed) return;
                                    },
                                  )
                                },
                                zoomControlsEnabled: false,
                              ),
                            ),
                          ),
                        ),
                      ),

                      /// ⏰ HORARIOS
                      FutureBuilder<List<OpeningHourModel>>(
                        future: _hoursFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final hours = snapshot.data!;

                          return AnimatedOpacity(
                            opacity: 1,
                            duration:
                            const Duration(milliseconds: 400),
                            child: SectionBlock(
                              title: "Horarios",
                              icon: Icons.access_time,
                              child: Column(
                                children: hours.map((h) {
                                  return Container(
                                    margin:
                                    const EdgeInsets.only(
                                        bottom: 8),
                                    padding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                      Colors.grey.shade100,
                                      borderRadius:
                                      BorderRadius.circular(
                                          10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                      children: [
                                        Text(
                                          weekDayToString(h.weekDay),
                                          style:
                                          const TextStyle(
                                            fontWeight:
                                            FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                            "${h.startTime} - ${h.endTime}"),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),

                      /// 🚌 TRANSPORTE
                      FutureBuilder<List<TransportLineModel>>(
                        future: _transportFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final lines = snapshot.data!;

                          return AnimatedOpacity(
                            opacity: 1,
                            duration:
                            const Duration(milliseconds: 400),
                            child: SectionBlock(
                              title: "Transporte",
                              icon:
                              Icons.directions_bus,
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: lines.map((line) {
                                  return Container(
                                    padding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors
                                          .mediumBlue
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                      BorderRadius.circular(
                                          20),
                                    ),
                                    child: Text(line.name),
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool> _requireAuth() async {
    final userProvider = context.read<UserProvider>();

    if (userProvider.user == null) {
      AuthDialogs.showLoginRequired(context);
      return false;
    }

    return true;
  }

  Future<void> _handleVisitedClick() async {
    final allowed = await _requireAuth();
    if (!allowed) return;

    if (_isVisited) {
      await _unmarkAsVisited();
    } else {
      await _markAsVisited();
    }
  }
}
