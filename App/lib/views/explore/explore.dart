import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../controllers/explore/explore_controller.dart';

import '../../services/explore_feed_service.dart';

import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';
import '../../widgets/common/type_tab_selector.dart';
import '../../widgets/categories/category_chip_selector.dart';
import '../../widgets/map/explore_map.dart';
import '../../widgets/explore/explore_results_section.dart';
import '../../widgets/common/empty/empty_results.dart';
import '../../widgets/inputs/search_bar.dart';

import '../../ui/themes/colors.dart';

import '../business/business_detail.dart';
import '../event/event_detail.dart';
import '../touristPlaces/tourist_place_detail.dart';

class ExplorePage extends StatelessWidget {
  final String? initialType;

  const ExplorePage({super.key, this.initialType});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<UserProvider>().authService;

    return ChangeNotifierProvider(
      create: (_) {
        final controller = ExploreController(
          ExploreFeedService(auth),
        );

        if (initialType != null) {
          controller.selectedType = initialType!;
        }

        controller.init();

        return controller;
      },
      child: const _ExploreView(),
    );
  }
}

class _ExploreView extends StatefulWidget {
  const _ExploreView();

  @override
  State<_ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<_ExploreView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadNextPage);
  }

  void _loadNextPage() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 500) {
      context.read<ExploreController>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadNextPage)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreController>(
      builder: (context, controller, _) {
        if (controller.loading) {
          return const Scaffold(
            body: AppLoader(message: "Cargando lugares..."),
          );
        }

        final businesses = controller.businesses;
        final touristPlaces = controller.touristPlaces;
        final events = controller.events;

        final totalResults =
            businesses.length + touristPlaces.length + events.length;

        return Scaffold(
          appBar: const CustomAppBar(title: 'Explorar'),
          body: Column(
            children: [
              /// HEADER
              _ExploreFilters(controller: controller),

              /// 📜 CONTENIDO SCROLLEABLE
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.refresh,
                  child: ListView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      /// 🔎 SEARCH
                      _SearchSection(controller: controller),

                      /// MAPA
                      ExploreMap(markers: controller.markers),

                      const SizedBox(height: 20),

                      /// HEADER RESULTADOS
                      _ResultsHeader(total: totalResults),

                      const SizedBox(height: 10),

                      /// RESULTADOS
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: totalResults == 0
                            ? const EmptyResults()
                            : ExploreResultsSection(
                                key: ValueKey(totalResults),
                                businesses: businesses,
                                touristPlaces: touristPlaces,
                                events: events,
                                getBusinessImage: controller.businessImage,
                                getTouristImage: controller.touristImage,
                                getEventImage: controller.eventImage,
                                getCategory: controller.categoryLabel,
                                getRating: controller.getRating,
                                getPrice: controller.getPrice,
                                onBusinessTap: (b) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          BusinessDetailPage(business: b),
                                    ),
                                  );
                                },
                                onTouristTap: (p) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          TouristPlaceDetail(place: p),
                                    ),
                                  );
                                },
                                onEventTap: (e) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EventDetailPage(event: e),
                                    ),
                                  );
                                },
                              ),
                      ),

                      if (controller.loadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExploreFilters extends StatelessWidget {
  final ExploreController controller;

  const _ExploreFilters({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          /// 🔘 TABS
          TypeTabSelector<String>(
            types: const [
              'Todos',
              'business',
              'tourist_place',
              'event',
              'service'
            ],
            selectedType: controller.selectedType,
            onTypeSelected: controller.updateType,
            getLabel: (type) {
              switch (type) {
                case 'business':
                  return 'Negocios';
                case 'tourist_place':
                  return 'Lugares';
                case 'event':
                  return 'Eventos';
                case 'service':
                  return 'Servicios';
                default:
                  return 'Todos';
              }
            },
          ),

          const SizedBox(height: 8),

          /// 🏷️ CATEGORÍAS
          if (controller.selectedType != 'Todos')
            CategoryChipSelector(
              categories: controller.categories,
              selectedCategoryId: controller.selectedCategoryId ?? 0,
              onCategorySelected: controller.updateCategory,
            ),
        ],
      ),
    );
  }
}

class _SearchSection extends StatelessWidget {
  final ExploreController controller;

  const _SearchSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: SearchBarWidget(
        hintText: "Buscar lugares...",
        initialValue: controller.query,
        onChanged: (v) => controller.searchCtrl.text = v,
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  final int total;

  const _ResultsHeader({required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.darkBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "$total",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            "lugares encontrados",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
