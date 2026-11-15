import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/enums.dart';
import '../../../helpers/error_message_helper.dart';
import '../../../models/review_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/user_provider.dart';
import '../../../services/media_service.dart';
import '../../../services/review_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/user_service.dart';

class SubmitResult {
  final bool ok;
  final String message;

  const SubmitResult(this.ok, this.message);
}

class ReviewsController extends ChangeNotifier {
  ReviewsController(
    this._reviewSvc,
    this._userSvc,
    this._mediaSvc,
    this._storageSvc,
    this._userProvider,
  );

  final ReviewService _reviewSvc;
  final UserService _userSvc;
  final MediaService _mediaSvc;
  final StorageService _storageSvc;
  final UserProvider _userProvider;

  final List<ReviewModel> reviews = [];
  final Map<String, UserModel?> userCache = {};

  final TextEditingController commentCtrl = TextEditingController();

  bool loading = false;
  bool submitting = false;
  bool isOwner = false;
  bool editing = false;

  double rating = 0;
  XFile? pickedImage;
  ReviewModel? myReview;

  void startEditing() {
    final review = myReview;
    if (review != null) {
      rating = review.rating;
      commentCtrl.text = review.comment ?? '';
      pickedImage = null;
    }
    editing = true;
    notifyListeners();
  }

  void cancelEditing() {
    final review = myReview;
    if (review != null) {
      rating = review.rating;
      commentCtrl.text = review.comment ?? '';
    }
    pickedImage = null;
    editing = false;
    notifyListeners();
  }

  Future<void> load({
    required int targetId,
    required ReviewEntityType targetType,
    required String ownerUserId,
  }) async {
    loading = true;
    notifyListeners();

    final currentUser = _userProvider.user;
    isOwner = currentUser != null && currentUser.id == ownerUserId;

    try {
      reviews.clear();

      // REVIEWS
      final loadedReviews = await _reviewSvc.getByEntity(
        entityType: targetType,
        entityId: targetId,
      );
      reviews.addAll(loadedReviews);

      // MEDIA
      if (reviews.isNotEmpty) {
        final reviewIds = reviews.map((r) => r.id).toList();

        final mediaMap = await _mediaSvc.getByEntities(
          entityIds: reviewIds,
          entityType: MediaEntityType.review,
        );

        for (final r in reviews) {
          r.media = mediaMap[r.id] ?? [];
        }
      }

      // MY REVIEW
      if (currentUser != null) {
        final mine = reviews.where((r) => r.userId == currentUser.id).toList();
        myReview = mine.isNotEmpty ? mine.first : null;

        if (myReview != null) {
          rating = myReview!.rating;
          commentCtrl.text = myReview!.comment ?? "";
        } else {
          rating = 0;
          commentCtrl.clear();
        }
      } else {
        myReview = null;
        rating = 0;
        commentCtrl.clear();
      }

      // USERS
      final ids = reviews.map((r) => r.userId).toSet();
      final missingIds = ids.where((id) => !userCache.containsKey(id)).toList();

      if (missingIds.isNotEmpty) {
        final usersFuture = _userSvc.getByIds(missingIds);
        final mediaFuture = _mediaSvc.getByEntityIds(
          entityIds: missingIds,
          entityType: MediaEntityType.user,
        );

        final users = await usersFuture;
        final mediaMap = await mediaFuture;

        for (final id in missingIds) {
          final user = users[id];
          user?.media = mediaMap[id] ?? [];
          userCache[id] = user;
        }
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  double get averageRating {
    if (reviews.isEmpty) return 0;
    final total = reviews.fold<double>(0, (acc, r) => acc + r.rating);
    return total / reviews.length;
  }

  int get totalReviews => reviews.length;

  String formatDate(DateTime dt) => DateFormat('dd MMM yyyy').format(dt);

  void setRating(double r) {
    rating = r;
    notifyListeners();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);

    if (img != null) {
      pickedImage = img;
      notifyListeners();
    }
  }

  void clearImage() {
    pickedImage = null;
    notifyListeners();
  }

  void prepareNewReview() {
    rating = 0;
    commentCtrl.clear();
    pickedImage = null;
    editing = false;
    notifyListeners();
  }

  Future<SubmitResult> submit({
    required int targetId,
    required ReviewEntityType targetType,
    required String ownerUserId,
  }) async {
    if (rating == 0) {
      return const SubmitResult(false, 'Debes calificar para enviar.');
    }

    final currentUser = _userProvider.user;
    if (currentUser == null) {
      return const SubmitResult(false, 'Usuario no autenticado');
    }

    submitting = true;
    notifyListeners();

    try {
      late int reviewId;

      if (myReview == null) {
        final review = ReviewModel(
          id: 0,
          userId: currentUser.id,
          entityType: targetType,
          entityId: targetId,
          rating: rating,
          comment: commentCtrl.text.trim().isEmpty
              ? null
              : commentCtrl.text.trim(),
          status: ReviewStatus.visible,
          createdAt: DateTime.now(),
          updatedAt: null,
        );

        final created = await _reviewSvc.create(review);
        reviewId = created.id;
        myReview = created;
      } else {
        final updated = ReviewModel(
          id: myReview!.id,
          userId: myReview!.userId,
          entityType: myReview!.entityType,
          entityId: myReview!.entityId,
          rating: rating,
          comment: commentCtrl.text.trim().isEmpty
              ? null
              : commentCtrl.text.trim(),
          status: myReview!.status,
          createdAt: myReview!.createdAt,
          updatedAt: DateTime.now(),
        );

        final saved = await _reviewSvc.updateReview(
          myReview!.id,
          updated.toJson(),
        );

        reviewId = saved.id;
        myReview = saved;
      }

      if (pickedImage != null) {
        await _storageSvc.deleteEntityMedia(
          entityType: MediaEntityType.review,
          entityId: reviewId,
        );

        await _storageSvc.uploadSingleFile(
          entityType: MediaEntityType.review,
          entityId: reviewId,
          file: pickedImage!,
          uploadMode: 'direct',
        );
      }

      await load(
        targetId: targetId,
        targetType: targetType,
        ownerUserId: ownerUserId,
      );

      rating = 0;
      commentCtrl.clear();
      pickedImage = null;
      editing = false;

      return const SubmitResult(true, 'Reseña guardada correctamente.');
    } catch (e) {
      if (e.toString().contains("duplicate")) {
        return const SubmitResult(
          false,
          'Ya has dejado una reseña. Puedes editarla.',
        );
      }

      return SubmitResult(false, userFacingError(e));
    } finally {
      submitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    commentCtrl.dispose();
    super.dispose();
  }
}
