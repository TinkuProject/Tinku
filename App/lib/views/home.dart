import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:tinkuapp/views/touristPlaces/tourist_place_detail.dart';

import '../controllers/boost/boost_controller.dart';
import '../controllers/discount/discount_controller.dart';
import '../controllers/nearby/nearby_controller.dart';

import '../core/enums.dart';
import '../core/route_observer.dart';
import '../models/discount_model.dart';
import '../providers/user_provider.dart';

import '../services/boost_service.dart';
import '../services/business_service.dart';
import '../services/discount_service.dart';
import '../services/event_service.dart';
import '../services/media_service.dart';
import '../services/product_service.dart';
import '../services/review_service.dart';
import '../services/system_config_service.dart';
import '../services/tourist_place_service.dart';
import '../services/nearby_service.dart';

import '../ui/themes/colors.dart';

import '../widgets/common/navigation/custom_app_bar.dart';
import '../widgets/common/user_avatar.dart';
import '../widgets/boost/boosts_section.dart';
import '../widgets/discount/discounts_section.dart';
import '../widgets/nearby/nearby_section.dart';

import '../widgets/home/category_circle_item.dart';
import '../widgets/home/location_status_card.dart';

import 'business/business_detail.dart';
import 'event/event_detail.dart';
import 'explore/explore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  StreamSubscription<ServiceStatus>? _serviceStatusSub;
  bool _locationFlowRunning = false;
  bool _isVisible = false;

  late final BoostController boostsC;
  late final NearbyController nearbyC;
  late final PageController boostsPageController;
  late final DiscountController discountsC;
  late final PageController discountsPageController;

  late final BusinessService businessService;
  late final EventService eventService;
  late final TouristPlaceService touristPlaceService;
  late final SystemConfigService systemConfigService;

  String? userLocationText;
  bool locationEnabled = false;
  bool locationLoading = true;

  final _typeItems = const [
    {
      'key': 'business',
      'label': 'Negocios',
      'icon': Icons.storefront,
      'color': AppColors.darkBlue
    },
    {
      'key': 'tourist_place',
      'label': 'Turismo',
      'icon': Icons.place,
      'color': AppColors.emerald
    },
    {
      'key': 'event',
      'label': 'Eventos',
      'icon': Icons.event,
      'color': AppColors.mustard
    },
    {
      'key': 'service',
      'label': 'Servicios',
      'icon': Icons.handyman,
      'color': AppColors.electricBlue
    },
  ];

  @override
  void initState() {
    super.initState();

    final auth = context.read<UserProvider>().authService;
    final mediaService = MediaService(auth);

    businessService = BusinessService(auth);
    eventService = EventService(auth);
    touristPlaceService = TouristPlaceService(auth);
    systemConfigService = SystemConfigService(auth);

    final boostService = BoostService(auth);
    final discountService = DiscountService(auth);
    final nearbyService = NearbyService(auth);

    nearbyC = NearbyController(
      nearbyService: nearbyService,
    );

    boostsC = BoostController(
      boostService: boostService,
      mediaService: mediaService,
      businessService: businessService,
      eventService: eventService,
      productService: ProductService(auth),
      reviewService: ReviewService(auth),
      touristPlaceService: touristPlaceService,
      systemConfigService: systemConfigService,
    );

    boostsPageController = PageController(viewportFraction: 0.9);
    boostsC.loadActive();

    discountsC = DiscountController(
      discountService: discountService,
      businessService: businessService,
      systemConfigService: systemConfigService,
      mediaService: mediaService,
    );

    discountsPageController = PageController(viewportFraction: 0.9);
    discountsC.loadActiveByBusiness(0);

    _serviceStatusSub = Geolocator.getServiceStatusStream().listen((status) {
      if (!mounted || !_isVisible) return;

      if (status == ServiceStatus.enabled) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted && _isVisible) {
            _initLocationFlow();
          }
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute<dynamic>);
  }

  @override
  void didPush() {
    _isVisible = true;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _isVisible) {
        _initLocationFlow();
      }
    });
  }

  @override
  void didPopNext() {
    _isVisible = true;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _isVisible) {
        _initLocationFlow();
      }
    });
  }

  @override
  void didPushNext() {
    _isVisible = false;
  }

  @override
  void didPop() {
    _isVisible = false;
  }

  Future<bool> _showLocationDisabledDialog() async {
    if (!mounted || !_isVisible) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.darkBlue.withValues(alpha: 0.08),
                  ),
                  child: const Icon(
                    Icons.location_off_rounded,
                    size: 38,
                    color: AppColors.darkBlue,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Ubicación desactivada',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Debes activar la ubicación para mostrar lugares cercanos y calcular rutas disponibles.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        icon: const Icon(
                          Icons.settings_rounded,
                          size: 18,
                        ),
                        label: const Text('Abrir ajustes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  Future<void> _clearNearbyState() async {
    nearbyC.clear();
    userLocationText = null;
  }

  Future<void> _initLocationFlow() async {
    if (!_isVisible) return;
    if (_locationFlowRunning) return;

    _locationFlowRunning = true;

    if (!mounted || !_isVisible) {
      _locationFlowRunning = false;
      return;
    }

    setState(() {
      locationLoading = true;
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();

      if (!mounted || !_isVisible) return;

      if (!enabled) {
        final shouldOpen = await _showLocationDisabledDialog();

        if (!mounted || !_isVisible) return;

        if (shouldOpen) {
          await Geolocator.openLocationSettings();
        }

        locationEnabled = false;
        await _clearNearbyState();
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (!mounted || !_isVisible) return;

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        locationEnabled = false;
        await _clearNearbyState();
        return;
      }

      if (permission == LocationPermission.denied) {
        locationEnabled = false;
        await _clearNearbyState();
        return;
      }

      final pos = await Geolocator.getCurrentPosition();

      if (!mounted || !_isVisible) return;

      await nearbyC.loadNearby(
        lat: pos.latitude,
        lng: pos.longitude,
      );

      await _resolveLocationName(pos.latitude, pos.longitude);

      locationEnabled = true;
    } catch (_) {
      locationEnabled = false;
      await _clearNearbyState();
    } finally {
      if (mounted) {
        setState(() {
          locationLoading = false;
        });
      }
      _locationFlowRunning = false;
    }
  }

  Future<void> _resolveLocationName(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        final city = p.locality ?? p.subAdministrativeArea ?? '';
        final country = p.country ?? '';

        userLocationText =
            [city, country].where((e) => e.trim().isNotEmpty).join(', ');

        if (userLocationText!.trim().isEmpty) {
          userLocationText = null;
        }
      }
    } catch (_) {
      userLocationText = null;
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  void _openType(String typeKey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExplorePage(initialType: typeKey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Inicio'),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.darkBlue, AppColors.mediumBlue],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      const UserAvatar(radius: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_greeting()}, ${user?.username ?? 'Invitado'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (locationLoading)
                              const Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Colors.white70,
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Detectando ubicación...',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else if (locationEnabled)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      userLocationText ??
                                          'Ubicación no disponible',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              const SizedBox.shrink(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: LocationStatusCard(
                enabled: locationEnabled,
                onTap: _initLocationFlow,
              ),
            ),
            _title("Explorar"),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 90,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _typeItems.length,
                  itemBuilder: (context, i) {
                    final t = _typeItems[i];

                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: CategoryCircleItem(
                        icon: t['icon'] as IconData,
                        label: t['label'] as String,
                        color: t['color'] as Color,
                        onTap: () => _openType(t['key'] as String),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            _title("Cerca de ti"),
            SliverToBoxAdapter(
              child: NearbySection(
                controller: nearbyC,
                onTapItem: (item) async {
                  switch (item.entityType) {
                    case VisitEntity.business:
                      final business =
                          await businessService.getById(item.entityId);
                      if (business == null || !context.mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BusinessDetailPage(
                            business: business,
                          ),
                        ),
                      );
                      break;

                    case VisitEntity.event:
                      final event = await eventService.getById(item.entityId);
                      if (event == null || !context.mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventDetailPage(
                            event: event,
                          ),
                        ),
                      );
                      break;

                    case VisitEntity.tourist_place:
                      final place =
                          await touristPlaceService.getById(item.entityId);
                      if (place == null || !context.mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TouristPlaceDetail(
                            place: place,
                          ),
                        ),
                      );
                      break;
                  }
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            _title("Descuentos"),
            SliverToBoxAdapter(
              child: DiscountsSection(
                controller: discountsC,
                pageController: discountsPageController,
                onTap: _openDiscountBusiness,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            _title("Novedades"),
            SliverToBoxAdapter(
              child: BoostsSection(
                controller: boostsC,
                pageController: boostsPageController,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _title(String text) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Future<void> _openDiscountBusiness(DiscountModel discount) async {
    final business = await businessService.getById(discount.businessId);
    if (!mounted || business == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BusinessDetailPage(business: business),
      ),
    );
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _serviceStatusSub?.cancel();
    boostsC.dispose();
    boostsPageController.dispose();
    discountsC.dispose();
    discountsPageController.dispose();
    super.dispose();
  }
}
