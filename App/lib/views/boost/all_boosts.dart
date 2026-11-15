import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tinkuapp/services/system_config_service.dart';

import '../../core/enums.dart';

import '../../providers/user_provider.dart';

import '../../services/boost_service.dart';
import '../../services/business_service.dart';
import '../../services/event_service.dart';
import '../../services/media_service.dart';
import '../../services/product_service.dart';
import '../../services/review_service.dart';
import '../../services/tourist_place_service.dart';

import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';
import '../../widgets/boost/boosts_carousel.dart';

import '../../controllers/boost/boost_controller.dart';
import '../../controllers/boost/boost_navigation.dart';

class AllBoostsPage extends StatefulWidget {
  const AllBoostsPage({super.key});

  @override
  State<AllBoostsPage> createState() => _AllBoostsPageState();
}

class _AllBoostsPageState extends State<AllBoostsPage> {
  late BoostController controller;
  late BoostNavigation navigation;

  final _businessController = PageController(viewportFraction: 0.85);

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final auth = context.read<UserProvider>().authService;

    controller = BoostController(
      boostService: BoostService(auth),
      mediaService: MediaService(auth),
      businessService: BusinessService(auth),
      eventService: EventService(auth),
      productService: ProductService(auth),
      reviewService: ReviewService(auth),
      touristPlaceService: TouristPlaceService(auth),
      systemConfigService: SystemConfigService(auth)
    );

    navigation = BoostNavigation(
      businessService: BusinessService(auth),
      eventService: EventService(auth),
      touristPlaceService: TouristPlaceService(auth),
    );

    controller.loadActive();

    _initialized = true;
  }

  @override
  void dispose() {
    _businessController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Consumer<BoostController>(
        builder: (context, c, _) {
          return Scaffold(
            appBar: const CustomAppBar(title: 'Todos los boosts'),
            body: c.loading
                ? const Center(child: AppLoader(message: "Cargando tus impulsos..."))
                : SingleChildScrollView(
              child: Column(
                children: [

                  /// 🏢 BUSINESS BOOSTS
                  if (c.activeBoosts
                      .where((b) =>
                  b.entityType == VisitEntity.business)
                      .isNotEmpty)
                    BoostsCarousel(
                      title: 'Negocios destacados',
                      boosts: c.activeBoosts
                          .where((b) =>
                      b.entityType == VisitEntity.business)
                          .toList(),
                      controller: _businessController,
                      onTap: (context, boost) {
                        navigation.open(context, boost);
                      },
                      boostController: c, // 👈 para obtener data enriquecida
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
