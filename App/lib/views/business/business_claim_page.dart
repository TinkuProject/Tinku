import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../helpers/claim_document_helper.dart';

import '../../components/utils.dart';
import '../../core/enums.dart';
import '../../helpers/flow_timeline_helper.dart';
import '../../models/business_model.dart';
import '../../models/business_claim_request_model.dart';
import '../../services/auth_service.dart';
import '../../services/business_claim_request_service.dart';
import '../../services/business_service.dart';
import '../../ui/themes/colors.dart';
import '../../widgets/common/navigation/custom_app_bar.dart';
import '../../widgets/common/flow_timeline.dart';

class BusinessClaimPage extends StatefulWidget {
  const BusinessClaimPage({super.key});

  @override
  State<BusinessClaimPage> createState() => _BusinessClaimPageState();
}

class _BusinessClaimPageState extends State<BusinessClaimPage> {
  late final BusinessService _businessService;
  late final BusinessClaimRequestService _claimService;

  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _commentCtrl = TextEditingController();

  List<BusinessModel> _businesses = [];
  List<BusinessClaimRequestModel> _myClaims = [];
  Map<int, BusinessModel> _claimBusinesses = {};
  List<PlatformFile> _documents = [];
  int? _selectedBusinessId;

  bool _loading = true;
  bool _submitting = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    _businessService = BusinessService(auth);
    _claimService = BusinessClaimRequestService(auth);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final businesses = await _businessService.getClaimable();
      final claims = await _claimService.getMine();
      final embeddedBusinesses = claims
          .map((claim) => claim.business)
          .whereType<BusinessModel>()
          .toList();
      final missingBusinessIds = claims
          .where((claim) => claim.business == null)
          .map((claim) => claim.businessId)
          .toSet();
      final fallbackBusinesses = missingBusinessIds.isEmpty
          ? <BusinessModel>[]
          : await _businessService.getByIds(missingBusinessIds.toList());

      if (!mounted) return;
      setState(() {
        _businesses = businesses;
        _myClaims = claims;
        _claimBusinesses = {
          for (final business in embeddedBusinesses) business.id: business,
          for (final business in fallbackBusinesses) business.id: business,
        };
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      showSnackbar('No se pudieron cargar los negocios reclamables',
          isError: true);
    }
  }

  Future<void> _pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.isEmpty) return;

    final validFiles = result.files.where((file) => file.path != null).toList();

    if (validFiles.isEmpty) {
      showSnackbar('No se pudo leer el archivo seleccionado', isError: true);
      return;
    }

    setState(() => _documents = validFiles);
  }

  Future<void> _submit() async {
    final businessId = _selectedBusinessId;

    if (businessId == null) {
      showSnackbar('Selecciona el negocio que quieres reclamar', isError: true);
      return;
    }

    if (_documents.isEmpty) {
      showSnackbar('Debes adjuntar documentación que avale el reclamo',
          isError: true);
      return;
    }

    setState(() => _submitting = true);

    try {
      final documents = await _claimService.uploadDocuments(_documents);

      if (documents.isEmpty) {
        throw Exception('No documents uploaded');
      }

      await _claimService.createClaim(
        businessId: businessId,
        documents: documents,
        comment: _commentCtrl.text,
      );

      if (!mounted) return;
      showSnackbar('Reclamo enviado para revisión');
      setState(() {
        _selectedBusinessId = null;
        _documents = [];
        _commentCtrl.clear();
      });
      await _load();
    } catch (_) {
      if (!mounted) return;
      showSnackbar('No se pudo enviar el reclamo', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  List<BusinessModel> get _filteredBusinesses {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _businesses;

    return _businesses.where((business) {
      return business.name.toLowerCase().contains(q) ||
          business.address.toLowerCase().contains(q) ||
          (business.nit ?? '').toLowerCase().contains(q);
    }).toList();
  }

  bool _hasPendingClaim(int businessId) {
    return _myClaims.any(
      (claim) =>
          claim.businessId == businessId &&
          claim.status == ApprovalStatus.pending,
    );
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
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomAppBar(title: 'Reclamar negocio'),
              Container(
                color: AppColors.background,
                child: const TabBar(
                  labelColor: AppColors.darkBlue,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.darkBlue,
                  tabs: [
                    Tab(text: 'Nuevo reclamo'),
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
            : TabBarView(
                children: [
                  RefreshIndicator(
                    color: AppColors.darkBlue,
                    onRefresh: _load,
                    child: _buildNewClaimView(),
                  ),
                  RefreshIndicator(
                    color: AppColors.darkBlue,
                    onRefresh: _load,
                    child: _ClaimHistoryView(
                      claims: _myClaims,
                      businesses: _claimBusinesses,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNewClaimView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _InfoPanel(),
        const SizedBox(height: 16),
        _SearchBox(
          controller: _searchCtrl,
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 14),
        if (_filteredBusinesses.isEmpty)
          const _EmptyState()
        else
          ..._filteredBusinesses.map(
            (business) {
              final pending = _hasPendingClaim(business.id);
              return _BusinessClaimCard(
                business: business,
                selected: _selectedBusinessId == business.id,
                pending: pending,
                onTap: pending
                    ? null
                    : () => setState(
                          () => _selectedBusinessId = business.id,
                        ),
              );
            },
          ),
        const SizedBox(height: 18),
        _DocumentPicker(
          documents: _documents,
          onPick: _pickDocuments,
          onRemove: (file) {
            setState(() {
              _documents =
                  _documents.where((item) => !identical(item, file)).toList();
            });
          },
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _commentCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Comentario opcional',
            hintText: 'Agrega detalles que ayuden a revisar tu caso',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.darkBlue,
            foregroundColor: AppColors.pureWhite,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.pureWhite,
                  ),
                )
              : const Icon(Icons.verified_user_outlined),
          label: Text(
            _submitting ? 'Enviando reclamo...' : 'Enviar reclamo',
          ),
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.darkBlue),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cuándo reclamar un negocio',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Puedes reclamar un negocio cuando aparece en Tinku pero todavía no tiene un socio responsable asignado.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.35),
          ),
          SizedBox(height: 10),
          Text(
            'Selecciona el negocio, adjunta documentación que demuestre tu relación con él y envía el reclamo para revisión.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Buscar por nombre, dirección o NIT',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _BusinessClaimCard extends StatelessWidget {
  const _BusinessClaimCard({
    required this.business,
    required this.selected,
    required this.pending,
    required this.onTap,
  });

  final BusinessModel business;
  final bool selected;
  final bool pending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.darkBlue : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.darkBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    color: AppColors.darkBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        business.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      if (business.nit?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 3),
                        Text(
                          'NIT ${business.nit}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                pending
                    ? const Text(
                        'Pendiente',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : Radio<int>(
                        value: business.id,
                        // ignore: deprecated_member_use
                        groupValue: selected ? business.id : null,
                        activeColor: AppColors.darkBlue,
                        // ignore: deprecated_member_use
                        onChanged: (_) => onTap?.call(),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentPicker extends StatelessWidget {
  const _DocumentPicker({
    required this.documents,
    required this.onPick,
    required this.onRemove,
  });

  final List<PlatformFile> documents;
  final VoidCallback onPick;
  final ValueChanged<PlatformFile> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            children: [
              const Expanded(
                child: Text(
                  'Documentación obligatoria',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Adjuntar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Puedes adjuntar PDF o imágenes.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          if (documents.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...documents.map(
              (file) => Row(
                children: [
                  const Icon(
                    Icons.insert_drive_file_outlined,
                    color: AppColors.darkBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Quitar documento',
                    onPressed: () => onRemove(file),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClaimHistoryView extends StatelessWidget {
  const _ClaimHistoryView({
    required this.claims,
    required this.businesses,
  });

  final List<BusinessClaimRequestModel> claims;
  final Map<int, BusinessModel> businesses;

  @override
  Widget build(BuildContext context) {
    if (claims.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _HistoryEmptyState(),
        ],
      );
    }

    final ordered = List<BusinessClaimRequestModel>.from(claims)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ordered.length,
      itemBuilder: (context, index) {
        final claim = ordered[index];
        final business = businesses[claim.businessId];
        return _ClaimHistoryCard(
          claim: claim,
          business: business,
        );
      },
    );
  }
}

class _ClaimHistoryCard extends StatelessWidget {
  const _ClaimHistoryCard({
    required this.claim,
    required this.business,
  });

  final BusinessClaimRequestModel claim;
  final BusinessModel? business;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(claim.status);
    final statusText = _statusText(claim.status);

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
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _statusIcon(claim.status),
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business?.name ?? 'Negocio #${claim.businessId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(claim.createdAt),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (business?.address.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              business!.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ],
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
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.attach_file,
                color: AppColors.darkBlue,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '${claim.documents.length} documento${claim.documents.length == 1 ? '' : 's'} adjunto${claim.documents.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (claim.documents.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < claim.documents.length; i++)
                  OutlinedButton.icon(
                    onPressed: () => openClaimDocument(context, claim.id, i),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text('Documento ${i + 1}'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(ApprovalStatus status) {
    return switch (status) {
      ApprovalStatus.pending => AppColors.mustard,
      ApprovalStatus.approved => AppColors.emerald,
      ApprovalStatus.rejected => AppColors.error,
    };
  }

  IconData _statusIcon(ApprovalStatus status) {
    return switch (status) {
      ApprovalStatus.pending => Icons.hourglass_top_rounded,
      ApprovalStatus.approved => Icons.check_circle_outline,
      ApprovalStatus.rejected => Icons.cancel_outlined,
    };
  }

  String _statusText(ApprovalStatus status) {
    return switch (status) {
      ApprovalStatus.pending => 'Pendiente',
      ApprovalStatus.approved => 'Aprobado',
      ApprovalStatus.rejected => 'Rechazado',
    };
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.history, color: AppColors.darkBlue, size: 38),
          SizedBox(height: 10),
          Text(
            'Todavía no enviaste reclamos',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Cuando inicies un reclamo, vas a poder seguir su estado desde aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.store_mall_directory_outlined,
              color: AppColors.darkBlue, size: 38),
          SizedBox(height: 10),
          Text(
            'No hay negocios disponibles para reclamar',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Solo se muestran negocios activos sin socio asignado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
