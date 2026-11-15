import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/financial_transaction_model.dart';
import '../core/enums.dart';

extension FinancialTransactionExtension on FinancialTransactionModel {
  bool get isPending => status == TransactionStatus.pending;
  bool get isRejected => status == TransactionStatus.failed;

  bool get isIncome {
    switch (type) {
      case TransactionType.reward:
      case TransactionType.refund:
      case TransactionType.admin_adjustment:
        return true;

      case TransactionType.purchase:
      case TransactionType.spend:
      case TransactionType.cashout:
        return false;
    }
  }

  Color get color {
    if (isPending) return Colors.orange;
    return isIncome ? Colors.green : Colors.red;
  }

  IconData get icon {
    if (isPending) return Icons.hourglass_empty;
    return isIncome ? Icons.arrow_downward : Icons.arrow_upward;
  }

  String get prefix {
    if (isPending) return '';
    return isIncome ? '+ ' : '- ';
  }

  String get statusLabel {
    if (isPending) return 'Pendiente';
    return '';
  }

  String get typeLabel {
    switch (type) {
      case TransactionType.purchase:
        return 'Compra de monedas';
      case TransactionType.spend:
        return 'Gasto';
      case TransactionType.reward:
        return 'Recompensa';
      case TransactionType.refund:
        return 'Reembolso';
      case TransactionType.cashout:
        return 'Retiro';
      case TransactionType.admin_adjustment:
        return 'Ajuste del sistema';
    }
  }

  String get purposeLabel {
    switch (purpose) {
      case 'partner_upgrade':
        return 'Upgrade a partner';
      case 'coin_purchase':
        return 'Compra de monedas';
      case 'subscription':
        return 'Suscripción';
      case 'marketplace_order':
        return 'Compra en marketplace';
      default:
        return 'Movimiento';
    }
  }

  String get formattedDate {
    return DateFormat('dd/MM/yyyy • HH:mm').format(createdAt);
  }

  String get subtitleText {
    return isPending
        ? 'Pendiente • $formattedDate'
        : formattedDate;
  }

  String get formattedAmount {
    final formatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: 2,
    );

    return '$prefix${formatter.format(amount)} $currency';
  }
}
