import 'package:flutter/material.dart';

import '../../core/enums.dart';
import '../../models/business_model.dart';
import '../../models/certification_model.dart';
import '../../models/discount_model.dart';
import '../../models/media_target.dart';
import '../../models/media_model.dart';
import '../../models/opening_hour_model.dart';
import '../../models/product_model.dart';
import '../../models/social_link_model.dart';
import '../../models/entity_transport_relation_model.dart';
import '../../models/transport_line_model.dart';
import '../../models/transport_route_model.dart';
import '../../models/user_visit_model.dart';

import '../../providers/user_provider.dart';

import '../../services/category_service.dart';
import '../../services/boost_service.dart';
import '../../services/business_service.dart';
import '../../services/media_service.dart';
import '../../services/marketplace_service.dart';
import '../../services/user_visit_service.dart';
import '../../services/discount_service.dart';
import '../certification/certification_controller.dart';
import '../shared/media/media_controller.dart';
import '../shared/opening_hours/opening_hours_controller.dart';
import '../product/product_carousel_controller.dart';
import '../product/product_controller.dart';
import '../shared/social/social_links_controller.dart';
import '../shared/transport/entity_transport_controller.dart';

class BusinessDetailController extends ChangeNotifier {
  BusinessDetailController(
    this._categorySvc,
    this._boostSvc,
    this._visitSvc,
    this._discountSvc,
    this.userProvider,
    this._mediaSvc,
    this._businessSvc,
    this._marketplaceSvc,
    this.productsC,
    this.certificationsC,
    this.mediaC,
    this.socialsC,
    this.hoursC,
    this.transportC,
  ) {
    carouselC = ProductCarouselController(
      mediaService: _mediaSvc, // o como estés accediendo
      categoryService: _categorySvc,
    );

    carouselC.addListener(notifyListeners);
    certificationsC.addListener(notifyListeners);
    productsC.addListener(notifyListeners);
    socialsC.addListener(notifyListeners);
    hoursC.addListener(notifyListeners);
    mediaC.addListener(notifyListeners);
    transportC.addListener(notifyListeners);
  }

  final CategoryService _categorySvc;
  final BoostService _boostSvc;
  final UserVisitService _visitSvc;
  final DiscountService _discountSvc;
  final UserProvider userProvider;
  final MediaService _mediaSvc;
  final BusinessService _businessSvc;
  final MarketplaceService _marketplaceSvc;

  late BusinessModel business;
  late final ProductCarouselController carouselC;
  final CertificationController certificationsC;
  final ProductController productsC;
  final SocialLinksController socialsC;
  final OpeningHoursController hoursC;
  final MediaController mediaC;
  final EntityTransportController transportC;

  bool initializing = true;

  // Datos básicos
  String categoryName = '';
  bool isPromoting = false;
  bool isFavorite = false;
  bool _hasBusiness = false;

  String? get ownerCi {
    final user = userProvider.user;
    if (user == null || user.id != business.ownerId) return null;
    return user.ci;
  }

  // Certificaciones
  List<DiscountModel> discounts = [];

  // -------------------------------------------------------------
  // INIT
  // -------------------------------------------------------------
  Future<void> init(BusinessModel b) async {
    business = b;
    _hasBusiness = true;
    initializing = true;
    notifyListeners();

    transportC.setContext(
      entityType: VisitEntity.business,
      entityId: business.id,
    );

    final detailLoaded = await _loadDetailAggregate();

    final futures = <Future<void>>[];

    if (!detailLoaded) {
      futures.addAll([
        _loadCategory(),
        productsC.loadByBusiness(business.id),
        certificationsC.loadByBusiness(business.id),
        _checkPromotion(),
        _loadDiscounts(),
        mediaC.load(
          target: EntityMediaTarget(
            entityId: b.id,
            entityType: MediaEntityType.business,
          ),
        ),
        socialsC.load(entityId: business.id),
        hoursC.load(
          entityType: OpeningEntity.business,
          entityId: business.id,
        ),
        transportC.loadSelectedOnly(
          entityType: VisitEntity.business,
          entityId: business.id,
        ),
      ]);
    }

    if (userProvider.user != null) {
      futures.add(_registerView());
      futures.add(_checkFavorite());
    }

    await Future.wait(futures);

    if (!detailLoaded) {
      await carouselC.init(productsC.products);
    }

    initializing = false;
    notifyListeners();
  }

  Future<bool> _loadDetailAggregate() async {
    try {
      final detail = await _businessSvc.getDetail(business.id);

      final category = _asMap(detail['category']);
      categoryName = category?['name']?.toString() ?? '';

      final medias = _parseList(detail['media'], MediaModel.fromJson);
      final products = _parseList(detail['products'], ProductModel.fromJson);
      final productMedia = _parseMediaMap(detail['product_media']);
      final certs =
          _parseList(detail['certifications'], CertificationModel.fromJson);
      final certMedia = _parseMediaMap(detail['certification_media']);
      final socialLinks =
          _parseList(detail['social_links'], SocialLinkModel.fromJson);
      final openingHours =
          _parseList(detail['opening_hours'], OpeningHourModel.fromJson);
      final relations = _parseList(
        detail['transport_relations'],
        EntityTransportRelationModel.fromJson,
      );
      final lines =
          _parseList(detail['transport_lines'], TransportLineModel.fromJson);
      final routes = _parseTransportRouteMap(detail['transport_routes']);

      discounts = _parseList(detail['discounts'], DiscountModel.fromJson);
      isPromoting = _asList(detail['boosts']).isNotEmpty;

      mediaC.setLoaded(medias);
      productsC.setBusinessProducts(
        businessId: business.id,
        items: products,
        mediaUrlsByProduct: productMedia,
      );
      carouselC.setLoaded(
        products: products,
        mediaUrlsByProduct: productMedia,
      );
      await carouselC.loadCategoriesOnly();
      certificationsC.setBusinessCertifications(
        businessId: business.id,
        items: certs,
        mediaUrlsByCertification: certMedia,
      );
      socialsC.setLoaded(entityId: business.id, socials: socialLinks);
      hoursC.setLoaded(
        entityType: OpeningEntity.business,
        entityId: business.id,
        hours: openingHours,
      );
      transportC.setLoaded(
        relations: relations,
        lines: lines,
        routes: routes,
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> reload() async {
    if (!_hasBusiness) return;
    await init(business);
  }

  // -------------------------------------------------------------
  // CATEGORÍA
  // -------------------------------------------------------------
  Future<void> _loadCategory() async {
    try {
      categoryName = await _categorySvc.getCategoryName(business.categoryId);
    } catch (_) {
      categoryName = '';
    }
  }

  // -------------------------------------------------------------
  // CERTIFICACIONES / DESCUENTOS
  // -------------------------------------------------------------

  Future<void> _loadDiscounts() async {
    try {
      discounts = await _discountSvc.getByBusiness(business.id);
    } catch (_) {
      discounts = [];
    }
  }

  // -------------------------------------------------------------
  // PROMOCIÓN
  // -------------------------------------------------------------
  Future<void> _checkPromotion() async {
    final boosts = await _boostSvc.getByEntity(
      entityType: VisitEntity.business,
      entityId: business.id,
    );

    isPromoting = boosts.isNotEmpty;
  }

  // -------------------------------------------------------------
  // FAVORITOS
  // -------------------------------------------------------------
  Future<void> _checkFavorite() async {
    if (userProvider.user == null) {
      isFavorite = false;
      return;
    }

    final visits = await _visitSvc.getByEntity(
      entityType: VisitEntity.business,
      entityId: business.id,
    );

    isFavorite = visits.any((v) => v.type == VisitType.favorited);
  }

  Future<void> _registerView() async {
    final user = userProvider.user;
    if (user?.id == business.ownerId) return;

    try {
      await _marketplaceSvc.registerBusinessView(business.id);
    } catch (_) {
      // La vista no debe bloquear el detalle si falla la métrica.
    }
  }

  Future<void> toggleFavorite() async {
    final visits = await _visitSvc.getByEntity(
      entityType: VisitEntity.business,
      entityId: business.id,
    );

    UserVisitModel? favoriteVisit;

    try {
      favoriteVisit = visits.firstWhere(
        (v) => v.type == VisitType.favorited,
      );
    } catch (_) {
      favoriteVisit = null;
    }

    if (favoriteVisit == null) {
      await _visitSvc.createVisit(
        CreateUserVisitModel(
          entityId: business.id,
          entityType: VisitEntity.business,
          type: VisitType.favorited,
        ),
      );

      isFavorite = true;
    } else {
      await _visitSvc.deleteByEntity(
        entityType: VisitEntity.business,
        entityId: business.id,
      );
      isFavorite = false;
    }

    notifyListeners();
  }

  // -------------------------------------------------------------
  // REFRESH
  // -------------------------------------------------------------
  Future<void> refreshProducts() async {
    await productsC.refresh();
  }

  Future<void> refreshPromotion() async {
    await _checkPromotion();
    notifyListeners();
  }

  Future<void> refreshMedia() async {
    await mediaC.load(
      target: EntityMediaTarget(
        entityId: business.id,
        entityType: MediaEntityType.business,
      ),
    );
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  List<dynamic> _asList(dynamic value) {
    return value is List ? value : const [];
  }

  List<T> _parseList<T>(
    dynamic value,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return _asList(value)
        .whereType<Map>()
        .map((item) => fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Map<int, List<String>> _parseMediaMap(dynamic value) {
    final result = <int, List<String>>{};
    final rawMap = value is Map ? value : const {};

    for (final entry in rawMap.entries) {
      final id = int.tryParse(entry.key.toString());
      if (id == null) continue;

      final urls = _parseList(entry.value, MediaModel.fromJson)
          .map((media) => media.url)
          .where((url) => url.trim().isNotEmpty)
          .toList();

      result[id] = urls;
    }

    return result;
  }

  Map<String, List<TransportRouteModel>> _parseTransportRouteMap(
    dynamic value,
  ) {
    final result = <String, List<TransportRouteModel>>{};
    final rawMap = value is Map ? value : const {};

    for (final entry in rawMap.entries) {
      result[entry.key.toString()] = _parseList(
        entry.value,
        TransportRouteModel.fromJson,
      );
    }

    return result;
  }

  @override
  void dispose() {
    certificationsC.dispose();
    productsC.dispose();
    socialsC.dispose();
    hoursC.dispose();
    mediaC.dispose();
    transportC.dispose();
    super.dispose();
  }
}
