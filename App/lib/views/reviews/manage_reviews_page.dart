import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/utils.dart';
import '../../controllers/review/manage_reviews_controller.dart';
import '../../helpers/error_message_helper.dart';
import '../../models/review_model.dart';
import '../../services/business_service.dart';
import '../../services/review_service.dart';
import '../../providers/user_provider.dart';
import '../../ui/themes/colors.dart';
import '../../widgets/common/empty/app_empty.dart';
import '../../widgets/common/loaders/app_loader.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';
import '../../widgets/reviews/review_stars.dart';
import '../../widgets/selectors/business_filter_select.dart';

class ManageReviewsPage extends StatefulWidget {
  const ManageReviewsPage({super.key});

  @override
  State<ManageReviewsPage> createState() => _ManageReviewsPageState();
}

class _ManageReviewsPageState extends State<ManageReviewsPage> {
  late final ManageReviewsController c;

  @override
  void initState() {
    super.initState();
    final auth = context.read<UserProvider>().authService;
    c = ManageReviewsController(
      ReviewService(auth),
      BusinessService(auth),
    )..addListener(_rebuild);
    Future.microtask(c.load);
  }

  @override
  void dispose() {
    c.removeListener(_rebuild);
    c.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _openReplyDialog(ReviewModel review) async {
    final reply = await showDialog<String>(
      context: context,
      builder: (_) => _ReviewReplyDialog(initialReply: review.ownerReply),
    );

    if (reply == null) return;

    try {
      await c.reply(reviewId: review.id, text: reply);
      showSnackbar('Respuesta guardada.');
    } catch (e) {
      showSnackbar(userFacingError(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviews = c.visibleReviews;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Gestionar reseñas',
        subtitle: 'Responde opiniones de tus entidades',
      ),
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: c.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                const _IntroCard(),
                const SizedBox(height: 12),
                BusinessFilterSelect(
                  value: c.selectedBusinessId,
                  items: c.businessSelectorItems,
                  onChanged: c.setSelectedBusiness,
                  disabledIds: c.disabledBusinessSelectorIds,
                  disabledLabel: 'Pendiente',
                ),
                const SizedBox(height: 12),
                _FilterBar(
                  selected: c.filter,
                  onSelected: c.setFilter,
                ),
                const SizedBox(height: 12),
                if (c.error != null)
                  AppEmptyState(
                    icon: Icons.error_outline,
                    title: 'No se pudieron cargar reseñas',
                    subtitle: c.error!,
                    iconColor: AppColors.error,
                  )
                else if (reviews.isEmpty && !c.loading)
                  const AppEmptyState(
                    icon: Icons.reviews_outlined,
                    title: 'Sin reseñas para mostrar',
                    subtitle: 'No hay reseñas para este filtro.',
                    iconColor: AppColors.darkBlue,
                  )
                else
                  ...reviews.map(
                    (review) => _ManagedReviewCard(
                      review: review,
                      onReply: () => _openReplyDialog(review),
                    ),
                  ),
              ],
            ),
          ),
          if (c.loading || c.saving)
            const AppLoader(message: 'Cargando reseñas...'),
        ],
      ),
    );
  }
}

class _ReviewReplyDialog extends StatefulWidget {
  const _ReviewReplyDialog({this.initialReply});

  final String? initialReply;

  @override
  State<_ReviewReplyDialog> createState() => _ReviewReplyDialogState();
}

class _ReviewReplyDialogState extends State<_ReviewReplyDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialReply ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Responder reseña'),
      content: TextField(
        controller: _controller,
        minLines: 4,
        maxLines: 6,
        decoration: const InputDecoration(
          hintText: 'Escribe una respuesta clara y respetuosa',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.darkBlue),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Puedes responder reseñas de tus negocios, servicios y eventos. La calificación y el comentario del usuario no se modifican.',
              style: TextStyle(
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.onSelected,
  });

  final ManagedReviewFilter selected;
  final ValueChanged<ManagedReviewFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ManagedReviewFilter.values.map((filter) {
          final isSelected = filter == selected;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_label(filter)),
              selected: isSelected,
              onSelected: (_) => onSelected(filter),
              selectedColor: AppColors.darkBlue.withValues(alpha: 0.12),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.darkBlue : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _label(ManagedReviewFilter filter) {
    switch (filter) {
      case ManagedReviewFilter.business:
        return 'Negocios';
      case ManagedReviewFilter.service:
        return 'Servicios';
      case ManagedReviewFilter.event:
        return 'Eventos';
      case ManagedReviewFilter.pending:
        return 'Sin responder';
      case ManagedReviewFilter.replied:
        return 'Respondidas';
      case ManagedReviewFilter.all:
        return 'Todas';
    }
  }
}

class _ManagedReviewCard extends StatelessWidget {
  const _ManagedReviewCard({
    required this.review,
    required this.onReply,
  });

  final ReviewModel review;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final reviewerName = [
      review.reviewerFirstName,
      review.reviewerLastName,
    ].whereType<String>().where((v) => v.trim().isNotEmpty).join(' ');
    final displayName = reviewerName.isNotEmpty
        ? reviewerName
        : review.reviewerUsername ?? 'Usuario';
    final hasReply = (review.ownerReply ?? '').trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.entityName ?? 'Entidad',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              _TypePill(kind: review.entityKind ?? review.entityType.name),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ReviewStars(rating: review.rating, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayName,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          if ((review.comment ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: const TextStyle(
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ],
          if (hasReply) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.darkBlue.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                review.ownerReply!,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onReply,
              icon: Icon(hasReply ? Icons.edit_outlined : Icons.reply),
              label: Text(hasReply ? 'Editar respuesta' : 'Responder'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.kind});

  final String kind;

  @override
  Widget build(BuildContext context) {
    final label = switch (kind) {
      'service' => 'Servicio',
      'event' => 'Evento',
      _ => 'Negocio',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.darkBlue,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
