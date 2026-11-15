import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../helpers/claim_document_helper.dart';

import '../../components/utils.dart';
import '../../core/enums.dart';
import '../../helpers/flow_timeline_helper.dart';
import '../../models/business_claim_request_model.dart';
import '../../providers/user_provider.dart';
import '../../services/business_claim_request_service.dart';
import '../../ui/themes/colors.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';
import '../../widgets/common/flow_timeline.dart';

class AdminBusinessClaimsPage extends StatefulWidget {
  const AdminBusinessClaimsPage({super.key});

  @override
  State<AdminBusinessClaimsPage> createState() =>
      _AdminBusinessClaimsPageState();
}

class _AdminBusinessClaimsPageState extends State<AdminBusinessClaimsPage> {
  late BusinessClaimRequestService _service;
  List<BusinessClaimRequestModel> _pending = [];
  List<BusinessClaimRequestModel> _history = [];
  bool _loading = true;
  int? _processingId;

  @override
  void initState() {
    super.initState();
    final auth = context.read<UserProvider>().authService;
    _service = BusinessClaimRequestService(auth);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.getPending(),
        _service.getAllAdmin(),
      ]);

      if (!mounted) return;
      setState(() {
        _pending = results[0];
        _history = results[1]
            .where((claim) => claim.status != ApprovalStatus.pending)
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      showSnackbar('No se pudieron cargar los reclamos', isError: true);
    }
  }

  Future<void> _review(
    BusinessClaimRequestModel claim,
    ApprovalStatus status,
  ) async {
    final commentCtrl = TextEditingController();
    final approved = status == ApprovalStatus.approved;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approved ? 'Aprobar reclamo' : 'Rechazar reclamo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              approved
                  ? 'El negocio pasara a pertenecer al socio solicitante.'
                  : 'El socio vera el reclamo como rechazado.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comentario opcional',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(approved ? 'Aprobar' : 'Rechazar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _processingId = claim.id);

    try {
      await _service.review(
        claim.id,
        status,
        comment:
            commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
      );
      if (!mounted) return;
      showSnackbar(approved ? 'Reclamo aprobado' : 'Reclamo rechazado');
      await _load();
    } catch (_) {
      if (!mounted) return;
      showSnackbar('No se pudo procesar el reclamo', isError: true);
    } finally {
      if (mounted) setState(() => _processingId = null);
      commentCtrl.dispose();
    }
  }

  Future<void> _openDocument(String url) async {
    for (final claim in [..._pending, ..._history]) {
      final index = claim.documents.indexOf(url);
      if (index >= 0) {
        await openClaimDocument(context, claim.id, index);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Column(
            children: [
              const CustomAppBar(title: 'Reclamos de negocio'),
              Container(
                color: AppColors.background,
                child: const TabBar(
                  labelColor: AppColors.darkBlue,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.darkBlue,
                  tabs: [
                    Tab(text: 'Pendientes'),
                    Tab(text: 'Historial'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.darkBlue),
              )
            : RefreshIndicator(
                color: AppColors.darkBlue,
                onRefresh: _load,
                child: TabBarView(
                  children: [
                    _ClaimsList(
                      claims: _pending,
                      processingId: _processingId,
                      showInfo: true,
                      emptyTitle: 'No hay reclamos pendientes',
                      emptySubtitle:
                          'Cuando un socio solicite reclamar un negocio, aparecera aqui para su revision.',
                      onApprove: (claim) =>
                          _review(claim, ApprovalStatus.approved),
                      onReject: (claim) =>
                          _review(claim, ApprovalStatus.rejected),
                      onOpenDocument: _openDocument,
                    ),
                    _ClaimsList(
                      claims: _history,
                      processingId: _processingId,
                      emptyTitle: 'Todavia no hay historial',
                      emptySubtitle:
                          'Los reclamos aprobados o rechazados se conservaran en esta vista.',
                      onApprove: (claim) =>
                          _review(claim, ApprovalStatus.approved),
                      onReject: (claim) =>
                          _review(claim, ApprovalStatus.rejected),
                      onOpenDocument: _openDocument,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ClaimsList extends StatelessWidget {
  final List<BusinessClaimRequestModel> claims;
  final int? processingId;
  final bool showInfo;
  final String emptyTitle;
  final String emptySubtitle;
  final ValueChanged<BusinessClaimRequestModel> onApprove;
  final ValueChanged<BusinessClaimRequestModel> onReject;
  final ValueChanged<String> onOpenDocument;

  const _ClaimsList({
    required this.claims,
    required this.processingId,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onApprove,
    required this.onReject,
    required this.onOpenDocument,
    this.showInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (showInfo) ...[
          const _ClaimsInfoCard(),
          const SizedBox(height: 12),
        ],
        if (claims.isEmpty)
          _EmptyClaims(title: emptyTitle, subtitle: emptySubtitle)
        else
          ...claims.map(
            (claim) => _ClaimAdminCard(
              claim: claim,
              processing: processingId == claim.id,
              onApprove: () => onApprove(claim),
              onReject: () => onReject(claim),
              onOpenDocument: onOpenDocument,
            ),
          ),
      ],
    );
  }
}

class _ClaimsInfoCard extends StatelessWidget {
  const _ClaimsInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.darkBlue),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Esta vista es para revisar la documentacion enviada por socios y decidir si corresponde asignarles negocios sin propietario.',
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClaimAdminCard extends StatelessWidget {
  final BusinessClaimRequestModel claim;
  final bool processing;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final ValueChanged<String> onOpenDocument;

  const _ClaimAdminCard({
    required this.claim,
    required this.processing,
    required this.onApprove,
    required this.onReject,
    required this.onOpenDocument,
  });

  @override
  Widget build(BuildContext context) {
    final business = claim.business;
    final canReview = claim.status == ApprovalStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.darkBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: AppColors.darkBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business?.name ?? 'Negocio #${claim.businessId}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (business?.address.trim().isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          business!.address,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _ClaimStatusPill(status: claim.status),
            ],
          ),
          const SizedBox(height: 12),
          FlowTimelinePanel(
            steps: FlowTimelineHelper.approval(
              status: claim.status,
              createdAt: claim.createdAt,
              reviewedAt: claim.reviewedAt,
              submittedLabel: 'Reclamo enviado',
            ),
            title: 'Seguimiento del reclamo',
          ),
          if (claim.comment?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              claim.comment!,
              style: const TextStyle(
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ],
          if (claim.documents.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < claim.documents.length; i++)
                  OutlinedButton.icon(
                    onPressed: () => onOpenDocument(claim.documents[i]),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text('Documento ${i + 1}'),
                  ),
              ],
            ),
          ],
          if (claim.reviewedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Revisado: ${claim.reviewedAt!.day.toString().padLeft(2, '0')}/${claim.reviewedAt!.month.toString().padLeft(2, '0')}/${claim.reviewedAt!.year}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          if (canReview) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: processing ? null : onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.darkBlue,
                      foregroundColor: AppColors.pureWhite,
                    ),
                    onPressed: processing ? null : onApprove,
                    icon: processing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Aprobar'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ClaimStatusPill extends StatelessWidget {
  final ApprovalStatus status;

  const _ClaimStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;

    switch (status) {
      case ApprovalStatus.approved:
        label = 'Aprobado';
        color = Colors.green;
        break;
      case ApprovalStatus.rejected:
        label = 'Rechazado';
        color = AppColors.error;
        break;
      case ApprovalStatus.pending:
        label = 'Pendiente';
        color = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyClaims extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyClaims({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.fact_check_outlined,
            color: AppColors.darkBlue,
            size: 38,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
