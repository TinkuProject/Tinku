import 'package:flutter/material.dart';

import '../../../models/social_link_model.dart';
import '../../../services/social_link_service.dart';

class SocialLinksController extends ChangeNotifier {
  SocialLinksController(this._socialService);

  final SocialLinkService _socialService;

  final List<SocialLinkModel> socialNetworks = [];

  static const List<String> allSocialTypes = [
    'facebook',
    'instagram',
    'tiktok',
    'x',
    'youtube',
  ];

  final Set<String> _availableSocialTypes = {};

  String? selectedSocialType;
  final TextEditingController urlController = TextEditingController();

  bool loading = false;
  int? _entityId;

  List<String> get availableSocialTypes => _availableSocialTypes.toList();

  String _normalize(String value) => value.trim().toLowerCase();

  String usernameFromUrl(String platform, String value) {
    var clean = value.trim();
    if (clean.isEmpty) return clean;

    clean = clean.replaceFirst(RegExp(r'^@+'), '');

    final uri = Uri.tryParse(clean);
    if (uri != null && uri.host.isNotEmpty) {
      final path = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      if (path.isNotEmpty) return path.replaceFirst(RegExp(r'^@+'), '');
    }

    if (clean.contains('/')) {
      clean = clean.split('/').where((part) => part.trim().isNotEmpty).last;
    }

    return clean.replaceFirst(RegExp(r'^@+'), '');
  }

  String buildProfileUrl(String platform, String username) {
    final normalizedPlatform = _normalize(platform);
    final cleanUser = usernameFromUrl(platform, username);

    switch (normalizedPlatform) {
      case 'facebook':
        return 'https://facebook.com/$cleanUser';
      case 'instagram':
        return 'https://instagram.com/$cleanUser';
      case 'tiktok':
        return 'https://tiktok.com/@$cleanUser';
      case 'x':
        return 'https://x.com/$cleanUser';
      case 'youtube':
        return 'https://youtube.com/@$cleanUser';
      default:
        return cleanUser;
    }
  }

  void _resetAvailableTypes() {
    _availableSocialTypes
      ..clear()
      ..addAll(allSocialTypes);
  }

  void init() {
    _resetAvailableTypes();
  }

  void setEntity(int entityId) {
    _entityId = entityId;
  }

  Future<void> load({
    required int entityId,
  }) async {
    _entityId = entityId;

    socialNetworks.clear();
    _resetAvailableTypes();

    final socials = await _socialService.getByBusiness(entityId);
    socialNetworks.addAll(socials);

    for (final s in socials) {
      _availableSocialTypes.remove(_normalize(s.platform));
    }

    if (selectedSocialType != null &&
        !_availableSocialTypes.contains(_normalize(selectedSocialType!))) {
      selectedSocialType = null;
    }

    notifyListeners();
  }

  void setLoaded({
    required int entityId,
    required List<SocialLinkModel> socials,
  }) {
    _entityId = entityId;
    socialNetworks
      ..clear()
      ..addAll(socials);
    _resetAvailableTypes();

    for (final s in socials) {
      _availableSocialTypes.remove(_normalize(s.platform));
    }

    if (selectedSocialType != null &&
        !_availableSocialTypes.contains(_normalize(selectedSocialType!))) {
      selectedSocialType = null;
    }

    loading = false;
    notifyListeners();
  }

  void addSocialNetwork(String type, String username) {
    final normalizedType = _normalize(type);
    final normalizedUrl = buildProfileUrl(normalizedType, username);

    if (normalizedType.isEmpty || normalizedUrl.isEmpty) return;

    final alreadyExists = socialNetworks.any(
          (s) => _normalize(s.platform) == normalizedType,
    );

    if (alreadyExists) return;

    socialNetworks.add(
      SocialLinkModel(
        id: 0,
        businessId: _entityId ?? 0,
        platform: normalizedType,
        url: normalizedUrl,
      ),
    );

    _availableSocialTypes.remove(normalizedType);
    selectedSocialType = null;
    urlController.clear();

    notifyListeners();
  }

  Future<void> removeSocialNetwork(SocialLinkModel soc) async {
    socialNetworks.remove(soc);

    _availableSocialTypes.add(_normalize(soc.platform));

    if (soc.id != 0) {
      await _socialService.deleteLink(soc.id);
    }

    notifyListeners();
  }

  Future<void> save({
    required int entityId,
  }) async {
    loading = true;
    notifyListeners();

    try {
      final existing = await _socialService.getByBusiness(entityId);

      for (final e in existing) {
        await _socialService.deleteLink(e.id);
      }

      for (final s in socialNetworks) {
        await _socialService.create(
          SocialLinkModel(
            id: 0,
            businessId: entityId,
            platform: _normalize(s.platform),
            url: buildProfileUrl(s.platform, s.url),
          ),
        );
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void reset() {
    socialNetworks.clear();
    _resetAvailableTypes();
    selectedSocialType = null;
    urlController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }
}
