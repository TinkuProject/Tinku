import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/utils.dart';
import '../../core/enums.dart';
import '../../helpers/media_helper.dart';
import '../../helpers/error_message_helper.dart';
import '../../models/user_visit_model.dart';
import '../../models/tourist_place_model.dart';
import '../../providers/user_provider.dart';
import '../../services/business_service.dart';
import '../../services/media_service.dart';
import '../../services/user_visit_service.dart';
import '../../services/tourist_place_service.dart';
import '../../services/category_service.dart';
import '../../views/business/business_detail.dart';
import '../../views/touristPlaces/tourist_place_detail.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';
import '../../widgets/common/liked_carousel.dart';
import '../../widgets/tourist_places/tourist_places_carousel.dart';
import '../../ui/themes/colors.dart';

class FavoriteBusinessesPage extends StatefulWidget {
  const FavoriteBusinessesPage({super.key});

  @override
  State<FavoriteBusinessesPage> createState() => _FavoriteBusinessesPageState();
}

class _FavoriteBusinessesPageState extends State<FavoriteBusinessesPage> {
  late BusinessService _businessService;
  late UserVisitService _visitService;
  late CategoryService _categoryService;
  late TouristPlaceService _touristPlaceService;
  late MediaService _mediaService;

  final PageController _likedCarouselController =
      PageController(viewportFraction: 0.88);
  final PageController _visitedCarouselController =
      PageController(viewportFraction: 0.88);

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  int _filterIndex = 0; // 0=Todos, 1=Favoritos, 2=Visitados
  final List<String> _filters = const ['Todos', 'Favoritos', 'Visitados'];

  List<LikedItem> _likedItems = [];
  List<TouristPlaceModel> _visitedPlaces = [];
  List<UserVisitModel> _visitModels = [];
  Map<int, String?> _touristPlaceImages = {};

  bool _loading = true;
  bool _loaded = false;
  String? _loadedUserId;
  int _loadVersion = 0;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
      () => setState(() => _query = _searchCtrl.text.trim().toLowerCase()),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Esto obliga a que el UserProvider ya esté listo
    // si no, no entra
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    if (user == null) {
      _loadVersion++;
      if (_loaded) {
        setState(() {
          _loaded = false;
          _loadedUserId = null;
          _likedItems = [];
          _visitedPlaces = [];
          _visitModels = [];
          _touristPlaceImages = {};
          _loading = false;
        });
      }
      return;
    }
    if (_loaded && _loadedUserId == user.id) return;

    final auth = context.read<UserProvider>().authService;

    _businessService = BusinessService(auth);
    _visitService = UserVisitService(auth);
    _categoryService = CategoryService(auth);
    _touristPlaceService = TouristPlaceService(auth);
    _mediaService = MediaService(auth);

    _loaded = true;
    _loadedUserId = user.id;
    _loadAllData();
  }

  @override
  void dispose() {
    _loadVersion++;
    _searchCtrl.dispose();
    _likedCarouselController.dispose();
    _visitedCarouselController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    if (_loadedUserId == null) return;
    final version = ++_loadVersion;
    final userId = _loadedUserId;
    final visitService = _visitService;
    final businessService = _businessService;
    final touristPlaceService = _touristPlaceService;
    final mediaService = _mediaService;
    final categoryService = _categoryService;
    setState(() {
      _loading = true;
      _likedItems = [];
      _visitedPlaces = [];
      _visitModels = [];
      _touristPlaceImages = {};
    });

    try {
      final visits = await visitService.getMine();

      final List<LikedItem> favorites = [];
      final List<TouristPlaceModel> visitedPlaces = [];
      final List<UserVisitModel> visitModels = [];
      final Map<int, String?> touristPlaceImages = {};

      final favoriteBusinessVisits = visits
          .where((v) =>
              v.type == VisitType.favorited &&
              v.entityType == VisitEntity.business)
          .toList();
      final visitedPlaceVisits = visits
          .where((v) =>
              v.type == VisitType.visited &&
              v.entityType == VisitEntity.tourist_place)
          .toList();

      final businessIds =
          favoriteBusinessVisits.map((v) => v.entityId).toSet().toList();
      final placeIds =
          visitedPlaceVisits.map((v) => v.entityId).toSet().toList();

      final businessesFuture = businessService.getByIds(businessIds);
      final placesFuture = touristPlaceService.getByIds(placeIds);
      final businessMediaFuture = mediaService.getByEntities(
        entityIds: businessIds,
        entityType: MediaEntityType.business,
      );
      final placeMediaFuture = mediaService.getByEntities(
        entityIds: placeIds,
        entityType: MediaEntityType.tourist_place,
      );

      await Future.wait([
        businessesFuture,
        placesFuture,
        businessMediaFuture,
        placeMediaFuture,
      ]);

      final businessesById = {
        for (final business in await businessesFuture) business.id: business,
      };
      final placesById = {
        for (final place in await placesFuture) place.id: place,
      };

      final categoryIds = <int>{
        ...businessesById.values.map((b) => b.categoryId),
      }.toList();
      final categoryNames = await categoryService.getNamesByIds(categoryIds);

      final businessMedia = await businessMediaFuture;
      final placeMedia = await placeMediaFuture;

      for (final visit in favoriteBusinessVisits) {
        final business = businessesById[visit.entityId];
        if (business == null) continue;

        favorites.add(
          LikedItem(
            type: LikedType.business,
            visit: visit,
            business: business,
            title: business.name,
            subtitle: business.address,
            category: categoryNames[business.categoryId] ?? 'Categoría',
            images: MediaHelper.getImageUrls(businessMedia[business.id] ?? []),
          ),
        );
      }

      for (final visit in visitedPlaceVisits) {
        final place = placesById[visit.entityId];
        if (place == null) continue;

        visitedPlaces.add(place);
        visitModels.add(visit);

        final images = MediaHelper.getImageUrls(placeMedia[place.id] ?? []);
        touristPlaceImages[place.id] = images.isNotEmpty ? images.first : null;
      }

      if (!mounted || version != _loadVersion || userId != _loadedUserId) {
        return;
      }

      setState(() {
        _likedItems = favorites;
        _visitedPlaces = visitedPlaces;
        _visitModels = visitModels;
        _touristPlaceImages = touristPlaceImages;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || version != _loadVersion || userId != _loadedUserId) {
        return;
      }

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar(userFacingError(e), isError: true),
      );
    }
  }

  Future<void> _removeLike(UserVisitModel visit) async {
    setState(() {
      _likedItems.removeWhere((it) => it.visit.id == visit.id);
    });

    await _visitService.deleteByEntity(
      entityType: visit.entityType,
      entityId: visit.entityId,
    );
  }

  Future<void> _removeVisit(UserVisitModel visit) async {
    await _visitService.deleteByEntity(
      entityType: visit.entityType,
      entityId: visit.entityId,
    );

    _loadAllData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar('Lugar eliminado de visitados'),
      );
    }
  }

  List<LikedItem> get _likedFiltered {
    if (_query.isEmpty) return _likedItems;

    return _likedItems.where((it) {
      return it.title.toLowerCase().contains(_query) ||
          it.category.toLowerCase().contains(_query);
    }).toList();
  }

  List<TouristPlaceModel> get _visitedFiltered {
    if (_query.isEmpty) return _visitedPlaces;
    return _visitedPlaces
        .where((p) => (p.name).toLowerCase().contains(_query))
        .toList();
  }

  bool get _showLiked => _filterIndex == 0 || _filterIndex == 1;
  bool get _showVisited => _filterIndex == 0 || _filterIndex == 2;

  Future<void> _refresh() async => _loadAllData();

  @override
  Widget build(BuildContext context) {
    final totalFavs = _likedItems.length;
    final totalVisited = _visitedPlaces.length;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Favoritos'),
      backgroundColor: AppColors.background,
      body: _loading
          ? const AppLoader(message: 'Cargando favoritos...')
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // HERO
                  _HeroHeader(totalFavs: totalFavs, totalVisited: totalVisited),

                  const SizedBox(height: 14),

                  // Búsqueda
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar en favoritos y visitados',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: AppColors.surfaceSoft,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.darkBlue.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Filtros
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_filters.length, (i) {
                        final selected = _filterIndex == i;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_filters[i]),
                            selected: selected,
                            onSelected: (_) => setState(() => _filterIndex = i),
                            selectedColor:
                                AppColors.darkBlue.withValues(alpha: 0.15),
                            backgroundColor: AppColors.surfaceSoft,
                            side: BorderSide(
                              color: selected
                                  ? AppColors.darkBlue.withValues(alpha: 0.4)
                                  : Colors.transparent,
                            ),
                            labelStyle: TextStyle(
                              color: selected
                                  ? AppColors.darkBlue
                                  : Colors.black87,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Sección: Favoritos
                  if (_showLiked) ...[
                    const _SectionTitle(
                        icon: Icons.favorite_border,
                        title: 'Lugares que te gustaron'),
                    const SizedBox(height: 8),
                    if (_likedFiltered.isNotEmpty)
                      LikedCarousel(
                        items: _likedFiltered,
                        controller: _likedCarouselController,
                        onRemove: _removeLike,
                        onTap: (item) async {
                          final result = await _openLikedItem(item);

                          if (result == true) {
                            await _loadAllData(); // ← forzar sync con backend
                          }
                        },
                      )
                    else
                      _EmptyCard(
                        icon: Icons.favorite_outline,
                        title: _query.isEmpty
                            ? 'Sin favoritos'
                            : 'Sin resultados en favoritos',
                        subtitle: _query.isEmpty
                            ? 'Cuando marques favoritos aparecerán aquí.'
                            : 'Prueba con otras palabras.',
                      ),
                    const SizedBox(height: 26),
                  ],

                  // Sección: Visitados
                  if (_showVisited) ...[
                    const _SectionTitle(
                        icon: Icons.place_outlined,
                        title: 'Tus lugares visitados'),
                    const SizedBox(height: 5),
                    if (_visitedFiltered.isNotEmpty)
                      TouristPlaceCarousel(
                        places: _visitedFiltered,
                        imageUrls: _touristPlaceImages,
                        controller: _visitedCarouselController,
                        showExtraInfo: true,
                        onTap: (place) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TouristPlaceDetail(place: place),
                            ),
                          );
                        },
                        onRemove: (place) {
                          final index = _visitedPlaces
                              .indexWhere((p) => p.id == place.id);
                          if (index != -1) {
                            final visit = _visitModels[index];
                            _removeVisit(visit);
                          }
                        },
                      )
                    else
                      _EmptyCard(
                        icon: Icons.navigation_outlined,
                        title: _query.isEmpty
                            ? 'Aún no visitaste lugares'
                            : 'Sin resultados en visitados',
                        subtitle: _query.isEmpty
                            ? 'Explora y marca los lugares que ya visitaste.'
                            : 'Ajusta tu búsqueda.',
                      ),
                  ],
                ],
              ),
            ),
    );
  }

  Future<Object?> _openLikedItem(LikedItem item) {
    switch (item.type) {
      case LikedType.business:
        return Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BusinessDetailPage(business: item.business!),
          ),
        );

      case LikedType.event:
        return Future.value(null);
    }
  }
}

/* ---------- Widgets auxiliares de UI (no tocan tus componentes) ---------- */

class _HeroHeader extends StatelessWidget {
  final int totalFavs;
  final int totalVisited;

  const _HeroHeader({required this.totalFavs, required this.totalVisited});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.darkBlue, AppColors.mediumBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: _circle(130, Colors.white.withValues(alpha: 0.08)),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: _circle(100, Colors.white.withValues(alpha: 0.06)),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.star_outline,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tus favoritos y visitas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Explora, guarda y revive tus lugares',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _pill('$totalFavs favs'),
                          const SizedBox(width: 8),
                          _pill('$totalVisited visitados'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.darkBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 28,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
