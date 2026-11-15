import 'package:flutter/material.dart';

import '../../models/payment_activity_item.dart';
import '../../ui/themes/colors.dart';
import '../../utils/date/date_formatter.dart';

Future<void> showPaymentActivityReceipt(
  BuildContext context,
  PaymentActivityItem item,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => PaymentActivityReceiptSheet(item: item),
  );
}

class PaymentActivityReceiptSheet extends StatelessWidget {
  final PaymentActivityItem item;

  const PaymentActivityReceiptSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item);
    final movementColor = item.isIncome ? AppColors.emerald : AppColors.primary;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: movementColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: movementColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recibo Tinku',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        item.isIncome
                            ? 'Entrada de fondos'
                            : 'Salida de fondos',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textSecondary,
                  tooltip: 'Cerrar',
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.amountLabel,
                    style: TextStyle(
                      color: movementColor,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ReceiptChip(
                        icon: Icons.swap_vert_rounded,
                        label: item.isIncome ? 'Entrada' : 'Salida',
                        color: movementColor,
                      ),
                      _ReceiptChip(
                        icon: _statusIcon(item),
                        label: item.statusLabel,
                        color: statusColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ReceiptSection(
              children: [
                _ReceiptRow(label: 'Concepto', value: item.title),
                _ReceiptRow(label: 'Tipo', value: _typeLabel(item.type)),
                _ReceiptRow(
                  label: 'Fecha',
                  value: DateFormatter.formDateTime(item.createdAt),
                ),
                _ReceiptRow(
                  label: 'Moneda',
                  value: _currencyLabel(item.currency),
                ),
                if (_notBlank(item.description))
                  _ReceiptRow(label: 'Detalle', value: item.description!),
                if (_notBlank(item.purpose))
                  _ReceiptRow(label: 'Motivo', value: item.purpose!),
                if (_notBlank(item.comment))
                  _ReceiptRow(label: 'Comentario', value: item.comment!),
              ],
            ),
            const SizedBox(height: 12),
            _ReceiptSection(
              children: [
                _ReceiptRow(label: 'Recibo', value: '#${item.id}'),
                _ReceiptRow(label: 'Origen', value: _kindLabel(item.kind)),
                if (item.paymentId != null)
                  _ReceiptRow(
                    label: 'Pago asociado',
                    value: '#${item.paymentId}',
                  ),
                if (item.referenceId != null)
                  _ReceiptRow(
                    label: 'Referencia',
                    value: '#${item.referenceId}',
                  ),
                if (item.targetId != null)
                  _ReceiptRow(
                    label: 'Entidad asociada',
                    value: '#${item.targetId}',
                  ),
                if (item.reviewedAt != null)
                  _ReceiptRow(
                    label: 'Revisado',
                    value: DateFormatter.formDateTime(item.reviewedAt),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static bool _notBlank(String? value) =>
      value != null && value.trim().isNotEmpty;

  static Color _statusColor(PaymentActivityItem item) {
    if (item.isPending) return Colors.orange;
    if (item.isRejected) return AppColors.error;
    return AppColors.emerald;
  }

  static IconData _statusIcon(PaymentActivityItem item) {
    if (item.isPending) return Icons.hourglass_top_rounded;
    if (item.isRejected) return Icons.close_rounded;
    return Icons.check_rounded;
  }

  static String _kindLabel(PaymentActivityKind kind) {
    switch (kind) {
      case PaymentActivityKind.paymentRequest:
        return 'Solicitud de pago';
      case PaymentActivityKind.financialTransaction:
        return 'Movimiento automático';
    }
  }

  static String _currencyLabel(String currency) {
    switch (currency.toUpperCase()) {
      case 'TINKU':
      case 'TINKUS':
      case 'T':
        return 'Tinkus';
      case 'BOB':
        return 'Bolivianos';
      case 'USD':
        return 'Dólares';
      default:
        return currency.toUpperCase();
    }
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'coin_purchase':
        return 'Compra de monedas';
      case 'subscription':
        return 'Suscripción';
      case 'partner_upgrade':
        return 'Solicitud de socio';
      case 'marketplace_order':
        return 'Compra en marketplace';
      case 'product_publication':
        return 'Publicación de producto';
      case 'product_publication_update':
        return 'Actualización de publicación';
      case 'boost':
      case 'boost_purchase':
        return 'Impulso';
      case 'discount':
      case 'discount_creation':
        return 'Promoción';
      case 'business_creation':
        return 'Registro de negocio';
      case 'event_reservation':
        return 'Reserva de evento';
      default:
        if (type.trim().isEmpty) return 'Movimiento';
        return type.replaceAll('_', ' ');
    }
  }
}

class _ReceiptSection extends StatelessWidget {
  final List<Widget> children;

  const _ReceiptSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ReceiptChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
