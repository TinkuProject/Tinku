import 'package:flutter/material.dart';

import '../../core/enums.dart';
import '../../models/certification_model.dart';
import '../../ui/themes/colors.dart';

import '../common/entity_manage/entity_manage_actions.dart';
import '../common/entity_manage/entity_manage_header.dart';

class CertificationManageCard extends StatelessWidget {
  final CertificationModel certification;
  final String? documentUrl;
  final String businessName;

  final VoidCallback? onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CertificationManageCard({
    super.key,
    required this.certification,
    required this.documentUrl,
    required this.businessName,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  ({String label, Color color, IconData icon}) get _statusMeta {
    switch (certification.status) {
      case BasicStatus.active:
        return (
        label: 'Activo',
        color: Colors.green,
        icon: Icons.check_circle,
        );

      default:
        return (
        label: 'Inactivo',
        color: Colors.grey,
        icon: Icons.pause_circle,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = _statusMeta;

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          /// TOP
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade400,
                      Colors.red.shade600,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EntityManageHeader(
                      title: certification.name,
                      statusLabel: meta.label,
                      statusColor: meta.color,
                      statusIcon: meta.icon,
                    ),

                    const SizedBox(height: 6),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniChip(
                          icon: Icons.storefront_outlined,
                          label: businessName,
                        ),

                        if ((certification.licenseNumber ?? '')
                            .trim()
                            .isNotEmpty)
                          _MiniChip(
                            icon: Icons.verified_outlined,
                            label: certification.licenseNumber!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          /// ACTIONS
          if (onOpen != null || onEdit != null || onDelete != null) ...[
            const SizedBox(height: 12),

            if (onOpen != null)
              _OpenDocumentButton(
                enabled: documentUrl != null,
                onTap: onOpen,
              ),

            if (onEdit != null || onDelete != null) ...[
              const SizedBox(height: 10),
              EntityManageActions(
                onEdit: onEdit,
                onDelete: onDelete,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _OpenDocumentButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onTap;

  const _OpenDocumentButton({
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(
          Icons.open_in_new_rounded,
          size: 16,
          color: enabled ? AppColors.darkBlue : Colors.grey,
        ),
        label: Text(
          enabled ? 'Documento' : 'Sin documento',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            fontSize: 12.5,
            color: enabled ? AppColors.darkBlue : Colors.grey,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          side: BorderSide(
            color: enabled
                ? AppColors.darkBlue.withValues(alpha: 0.25)
                : Colors.grey.withValues(alpha: 0.25),
          ),
          minimumSize: const Size.fromHeight(40),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: AppColors.darkBlue,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
