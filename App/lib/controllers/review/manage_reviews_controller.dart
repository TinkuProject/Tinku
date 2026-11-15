import 'package:flutter/material.dart';

import '../../core/enums.dart';
import '../../models/business_model.dart';
import '../../models/review_model.dart';
import '../../services/business_service.dart';
import '../../services/review_service.dart';

enum ManagedReviewFilter { all, business, service, event, pending, replied }

class ManageReviewsController extends ChangeNotifier {
  ManageReviewsController(this._reviewService, this._businessService);

  final ReviewService _reviewService;
  final BusinessService _businessService;

  bool loading = false;
  bool saving = false;
  String? error;
  ManagedReviewFilter filter = ManagedReviewFilter.all;
  int selectedBusinessId = 0;

  final List<ReviewModel> reviews = [];
  final List<BusinessModel> businesses = [];

  List<ReviewModel> get visibleReviews {
    Iterable<ReviewModel> list = reviews;

    if (selectedBusinessId != 0) {
      list = list.where((r) => r.entityBusinessId == selectedBusinessId);
    }

    switch (filter) {
      case ManagedReviewFilter.business:
        return list.where((r) => r.entityKind == 'business').toList();
      case ManagedReviewFilter.service:
        return list.where((r) => r.entityKind == 'service').toList();
      case ManagedReviewFilter.event:
        return list.where((r) => r.entityKind == 'event').toList();
      case ManagedReviewFilter.pending:
        return list.where((r) => (r.ownerReply ?? '').trim().isEmpty).toList();
      case ManagedReviewFilter.replied:
        return list
            .where((r) => (r.ownerReply ?? '').trim().isNotEmpty)
            .toList();
      case ManagedReviewFilter.all:
        return list.toList();
    }
  }

  Map<int, String> get businessSelectorItems => {
        0: 'Todos mis negocios',
        for (final business in businesses) business.id: business.name,
      };

  Set<int> get disabledBusinessSelectorIds => businesses
      .where((business) => business.status != BusinessStatus.active)
      .map((business) => business.id)
      .toSet();

  void setFilter(ManagedReviewFilter value) {
    filter = value;
    notifyListeners();
  }

  void setSelectedBusiness(int value) {
    selectedBusinessId = value;
    notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final loaded = await Future.wait([
        _reviewService.getManaged(),
        _businessService.getMine(),
      ]);
      reviews
        ..clear()
        ..addAll(loaded[0] as List<ReviewModel>);
      businesses
        ..clear()
        ..addAll(loaded[1] as List<BusinessModel>);
      if (disabledBusinessSelectorIds.contains(selectedBusinessId)) {
        selectedBusinessId = 0;
      }
    } catch (_) {
      error = 'No se pudieron cargar las reseñas';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> reply({
    required int reviewId,
    required String text,
  }) async {
    saving = true;
    notifyListeners();

    try {
      final updated = await _reviewService.replyToReview(
        reviewId: reviewId,
        reply: text,
      );
      final index = reviews.indexWhere((r) => r.id == reviewId);
      if (index != -1) {
        reviews[index] = reviews[index].copyWith(
          ownerReply: updated.ownerReply,
          ownerReplyUserId: updated.ownerReplyUserId,
          ownerReplyAt: updated.ownerReplyAt,
          updatedAt: updated.updatedAt,
        );
      }
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
