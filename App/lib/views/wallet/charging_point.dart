import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tinkuapp/core/enums.dart';

import '../../components/utils.dart';
import '../../helpers/marker_helper.dart';
import '../../models/charging_point_model.dart';
import '../../models/opening_hour_model.dart';
import '../../models/warehouse_model.dart';
import '../../providers/user_provider.dart';
import '../../services/charging_point_service.dart';
import '../../services/opening_hour_service.dart';
import '../../services/warehouse_service.dart';
import '../../ui/themes/colors.dart';

import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';
import '../../widgets/map/full_map.dart';

class ChargingPointsMapPage extends StatefulWidget {
  const ChargingPointsMapPage({super.key});

  @override
  State<ChargingPointsMapPage> createState() => _ChargingPointsMapPageState();
}

class _ChargingPointsMapPageState extends State<ChargingPointsMapPage> {
  late ChargingPointService _chargingPointService;
  late OpeningHourService _openingHourService;
  late WarehouseService _warehouseService;

  bool _initialized = false;
  bool _loading = true;

  final TextEditingController _searchCtrl = TextEditingController();

  final Set<Marker> _markers = {};
  List<_RechargeMapPlace> _allPlaces = [];
  List<_RechargeMapPlace> _visiblePlaces = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final auth = context.read<UserProvider>().authService;

    _chargingPointService = ChargingPointService(auth);
    _openingHourService = OpeningHourService(auth);
    _warehouseService = WarehouseService(auth);

    _loadChargingPoints();

    _initialized = true;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ================= LOAD =================

  Future<void> _loadChargingPoints() async {
    try {
      final pointsFuture = _chargingPointService.getActive();
      final warehousesFuture = _warehouseService.getActive();
      final points = await pointsFuture;
      final warehouses = await warehousesFuture;

      _allPlaces = [
        ...points.map(_RechargeMapPlace.fromChargingPoint),
        ...warehouses
            .where((w) => w.latitude != null && w.longitude != null)
            .map(_RechargeMapPlace.fromWarehouse),
      ];
      _visiblePlaces = List.of(_allPlaces);

      await _rebuildMarkers(_visiblePlaces);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ================= MARKERS =================

  Future<void> _rebuildMarkers(List<_RechargeMapPlace> places) async {
    final markers = await Future.wait(
      places.map((place) async {
        final icon = await MarkerHelper.getMarker(
          place.markerType,
          color: place.markerColor,
        );

        return Marker(
          markerId: MarkerId('${place.type}_${place.id}'),
          position: LatLng(place.latitude, place.longitude),
          icon: icon,
          onTap: () => _showPlaceDetail(place),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: place.typeLabel,
          ),
        );
      }),
    );

    _markers
      ..clear()
      ..addAll(markers);

    if (mounted) setState(() {});
  }

  // ================= SEARCH =================

  void _applySearch(String query) {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      _visiblePlaces = List.of(_allPlaces);
    } else {
      _visiblePlaces = _allPlaces.where((p) {
        final name = p.name.toLowerCase();
        final addr = p.address.toLowerCase();
        final type = p.typeLabel.toLowerCase();
        return name.contains(q) || addr.contains(q) || type.contains(q);
      }).toList();
    }

    _rebuildMarkers(_visiblePlaces);
  }

  // ================= ACTIONS =================

  Future<void> _openInMaps(ChargingPointModel point) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${point.latitude},${point.longitude}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          tinkuSnackBar('No se pudo abrir Google Maps', isError: true),
        );
      }
    }
  }

  Future<void> _openPlaceInMaps(_RechargeMapPlace place) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar('No se pudo abrir Google Maps', isError: true),
      );
    }
  }

  // ================= DETAIL =================

  void _showPlaceDetail(_RechargeMapPlace place) {
    if (place.chargingPoint != null) {
      _showChargingPointDetail(place.chargingPoint!);
      return;
    }

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.warehouse_outlined,
                    color: AppColors.emerald,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      place.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (place.address.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 20,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(place.address)),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openPlaceInMaps(place),
                      icon: const Icon(Icons.directions),
                      label: const Text('Cómo llegar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      label: const Text('Cerrar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChargingPointDetail(ChargingPointModel point) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return FutureBuilder<List<OpeningHourModel>>(
          future: _openingHourService.getByEntity(
            entityId: point.id,
            entityType: OpeningEntity.charging_point,
          ),
          builder: (context, snapshot) {
            final hours = snapshot.data ?? [];

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Row(
                    children: [
                      Icon(Icons.ev_station,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          point.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (point.address.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 20, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(child: Text(point.address)),
                      ],
                    ),

                  if (hours.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Icon(Icons.schedule, size: 20, color: Colors.grey),
                        SizedBox(width: 6),
                        Text('Horarios',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: hours
                          .map((h) =>
                          Text("• ${h.weekDay}: ${h.startTime} - ${h.endTime}"))
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _openInMaps(point),
                          icon: const Icon(Icons.directions),
                          label: const Text('Cómo llegar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          label: const Text('Cerrar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ================= UI =================

  Widget _buildSearchBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _applySearch,
            decoration: const InputDecoration(
              hintText: 'Buscar punto o almacén...',
              prefixIcon: Icon(Icons.search),
              border: InputBorder.none,
              contentPadding:
              EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapHeaderInfo() {
    return Positioned(
      left: 16,
      bottom: 80,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.ev_station,
              size: 18,
              color: AppColors.darkBlue,
            ),
            const SizedBox(width: 6),
            Text('${_visiblePlaces.where((p) => p.isChargingPoint).length}'),
            const SizedBox(width: 12),
            const Icon(
              Icons.warehouse_outlined,
              size: 18,
              color: AppColors.emerald,
            ),
            const SizedBox(width: 6),
            Text('${_visiblePlaces.where((p) => p.isWarehouse).length}'),
          ],
        ),
      ),
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Recarga y almacenes'),
      body: _loading
          ? const AppLoader(message: 'Cargando puntos y almacenes...')
          : Stack(
        children: [
          FullMap(
            markers: _markers,
            mapType: MapType.normal,
          ),
          _buildSearchBar(context),
          _buildMapHeaderInfo(),
        ],
      ),
    );
  }
}

class _RechargeMapPlace {
  const _RechargeMapPlace({
    required this.id,
    required this.type,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.markerType,
    required this.markerColor,
    required this.typeLabel,
    this.chargingPoint,
  });

  final int id;
  final String type;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String markerType;
  final Color markerColor;
  final String typeLabel;
  final ChargingPointModel? chargingPoint;

  bool get isChargingPoint => type == 'charging_point';
  bool get isWarehouse => type == 'warehouse';

  factory _RechargeMapPlace.fromChargingPoint(ChargingPointModel point) {
    return _RechargeMapPlace(
      id: point.id,
      type: 'charging_point',
      name: point.name,
      address: point.address,
      latitude: point.latitude,
      longitude: point.longitude,
      markerType: 'charging_point',
      markerColor: AppColors.darkBlue,
      typeLabel: 'Punto de recarga',
      chargingPoint: point,
    );
  }

  factory _RechargeMapPlace.fromWarehouse(WarehouseModel warehouse) {
    return _RechargeMapPlace(
      id: warehouse.id,
      type: 'warehouse',
      name: warehouse.name,
      address: warehouse.address ?? '',
      latitude: warehouse.latitude!,
      longitude: warehouse.longitude!,
      markerType: 'warehouse',
      markerColor: AppColors.emerald,
      typeLabel: 'Almacén',
    );
  }
}
