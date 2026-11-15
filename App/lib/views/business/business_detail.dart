import 'package:flutter/material.dart';
import 'package:tinkuapp/core/enums.dart';
import 'package:tinkuapp/services/business_service.dart';
import 'package:tinkuapp/services/entity_transport_relation_service.dart';
import 'package:tinkuapp/services/opening_hour_service.dart';
import 'package:tinkuapp/services/social_link_service.dart';
import 'package:tinkuapp/services/transport_line_service.dart';
import 'package:tinkuapp/services/transport_route_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../../controllers/business/business_detail_controller.dart';
import '../../controllers/shared/review/reviews_controller.dart';

import '../../controllers/certification/certification_controller.dart';
import '../../controllers/shared/media/media_controller.dart';
import '../../controllers/shared/opening_hours/opening_hours_controller.dart';
import '../../controllers/product/product_controller.dart';
import '../../controllers/shared/social/social_links_controller.dart';
import '../../controllers/shared/transport/entity_transport_controller.dart';
import '../../models/business_model.dart';

import '../../services/certification_service.dart';
import '../../services/discount_service.dart';
import '../../services/product_service.dart';
import '../../services/category_service.dart';
import '../../services/boost_service.dart';
import '../../services/storage_service.dart';
import '../../services/user_visit_service.dart';
import '../../services/review_service.dart';
import '../../services/user_service.dart';
import '../../services/media_service.dart';
import '../../services/marketplace_service.dart';

import '../../providers/user_provider.dart';
import '../../utils/dialogs/auth_dialogs.dart';
import '../../widgets/business/detail/business_actions_row.dart';
import '../../widgets/business/detail/business_header.dart';
import '../../widgets/business/detail/business_info_section.dart';
import '../../widgets/business/detail/tabs/description_tab.dart';
import '../../widgets/common/empty/app_empty.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/reviews/reviews_section.dart';
import '../../widgets/transport/transport_section.dart';

class BusinessDetailPage extends StatefulWidget {
  final BusinessModel business;
  final String? type;

  const BusinessDetailPage({
    super.key,
    required this.business,
    this.type,
  });

  @override
  State<BusinessDetailPage> createState() => _BusinessDetailPageState();
}

class _BusinessDetailPageState extends State<BusinessDetailPage>
    with SingleTickerProviderStateMixin {
  late BusinessDetailController c;
  late ReviewsController r;
  late TabController _tab;

  bool _loading = true;
  bool _error = false;
  bool _favoriteChanged = false;

  bool get _isService => widget.business.businessType == BusinessType.service;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final userProvider = context.read<UserProvider>();
    final auth = userProvider.authService;

    c = BusinessDetailController(
      CategoryService(auth),
      BoostService(auth),
      UserVisitService(auth),
      DiscountService(auth),
      userProvider,
      MediaService(auth),
      BusinessService(auth),
      MarketplaceService(auth),
      ProductController(
        ProductService(auth),
        BusinessService(auth),
        MediaService(auth),
      ),
      CertificationController(
        CertificationService(auth),
        BusinessService(auth),
        MediaService(auth),
      ),
      MediaController(
        StorageService(auth),
        MediaService(auth),
      ),
      SocialLinksController(
        SocialLinkService(auth),
      )..init(),
      OpeningHoursController(
        OpeningHourService(auth),
      ),
      EntityTransportController(
        TransportLineService(auth),
        EntityTransportRelationService(auth),
        TransportRouteService(auth),
      ),
    );

    r = ReviewsController(
      ReviewService(auth),
      UserService(auth),
      MediaService(auth),
      StorageService(auth),
      userProvider,
    );

    c.addListener(_rebuild);
    r.addListener(_rebuild);

    _tab = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });

    Future.microtask(() async {
      try {
        await c.init(widget.business);

        final currentUser = userProvider.user;

        if (currentUser != null && widget.business.ownerId != null) {
          await r.load(
            targetId: widget.business.id,
            targetType: ReviewEntityType.business,
            ownerUserId: widget.business.ownerId!,
          );
        }
      } catch (_) {
        _error = true;
      } finally {
        _loading = false;
        if (mounted) setState(() {});
      }
    });

    _initialized = true;
  }

  @override
  void dispose() {
    c.removeListener(_rebuild);
    r.removeListener(_rebuild);

    c.dispose();
    r.dispose();
    _tab.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _openWhatsApp() {
    final phone = widget.business.phone;
    if (phone != null && phone.trim().isNotEmpty) {
      final url = Uri.parse("https://wa.me/${phone.replaceAll(' ', '')}");
      launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _openMaps() {
    final lat = widget.business.latitude;
    final lng = widget.business.longitude;
    launchUrl(
      Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng"),
      mode: LaunchMode.externalApplication,
    );
  }

  void _openWebsite() {
    final site = widget.business.website;
    if (site != null && site.trim().isNotEmpty) {
      final url = Uri.parse(site.startsWith("http") ? site : "https://$site");
      launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.business;
    final currentUser = context.watch<UserProvider>().user;
    final isOwner =
        currentUser != null && currentUser.id == widget.business.ownerId;
    final isLogged = currentUser != null;

    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          children: [
            BusinessHeader(
              images: c.mediaC.existingMedia
                  .map((m) => m.url)
                  .where((url) => url.trim().isNotEmpty)
                  .toList(),
              isFavorite: c.isFavorite,
              isOwner: isOwner,
              isLogged: isLogged,
              isLoading: _loading || c.initializing,
              onBack: () => Navigator.pop(context, _favoriteChanged),
              onToggleFavorite: () async {
                if (!isLogged) {
                  AuthDialogs.showLoginRequired(context);
                  return;
                }

                final before = c.isFavorite;
                await c.toggleFavorite();

                if (before != c.isFavorite) {
                  _favoriteChanged = true;
                }
              },
            ),
            Positioned(
              top: 250,
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: Container(
                  color: Colors.white,
                  child: _loading
                      ? const Center(child: AppLoader())
                      : _error
                          ? const Center(
                              child: Text(
                                'Error cargando datos',
                                style: TextStyle(color: Colors.red),
                              ),
                            )
                          : NestedScrollView(
                              headerSliverBuilder:
                                  (context, innerBoxIsScrolled) => [
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      16,
                                      16,
                                      0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        BusinessInfoSection(
                                          business: b,
                                          categoryName: c.categoryName,
                                          ownerCi: c.ownerCi,
                                          onWhatsApp: _openWhatsApp,
                                          onWebsite: _openWebsite,
                                        ),
                                        const SizedBox(height: 16),
                                        BusinessActionsRow(
                                          phone: b.phone,
                                          website: b.website,
                                          onOpenWhatsApp: _openWhatsApp,
                                          onOpenMaps: _openMaps,
                                          onOpenWebsite: _openWebsite,
                                        ),
                                        const SizedBox(height: 20),
                                      ],
                                    ),
                                  ),
                                ),
                                SliverPersistentHeader(
                                  pinned: true,
                                  delegate: _PinnedTabBarDelegate(
                                    TabBar(
                                      controller: _tab,
                                      labelColor: Colors.black,
                                      tabs: const [
                                        Tab(text: 'Descripción'),
                                        Tab(text: 'Reseñas'),
                                        Tab(text: 'Transporte'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              body: TabBarView(
                                controller: _tab,
                                children: [
                                  DescriptionTab(
                                    controller: c,
                                    isService: _isService,
                                  ),
                                  b.ownerId != null
                                      ? ReviewsSection(
                                          controller: r,
                                          targetId: b.id,
                                          targetType: ReviewEntityType.business,
                                          ownerUserId: b.ownerId!,
                                        )
                                      : const Center(
                                          child: AppEmptyState(
                                            icon: Icons.reviews_outlined,
                                            title: 'Sin reseñas disponibles',
                                            subtitle:
                                                'Este contenido todavía no puede recibir reseñas.',
                                          ),
                                        ),
                                  TransportSection(
                                    latitude: b.latitude,
                                    longitude: b.longitude,
                                    placeName: b.name,
                                    controller: c.transportC,
                                  ),
                                ],
                              ),
                            ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinnedTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _PinnedTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedTabBarDelegate oldDelegate) {
    return oldDelegate.tabBar != tabBar;
  }
}
