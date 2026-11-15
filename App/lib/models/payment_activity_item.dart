import 'package:flutter/material.dart';

import '../core/enums.dart';
import '../ui/themes/colors.dart';
import '../utils/date/local_date_parser.dart';

enum PaymentActivityKind {
  paymentRequest,
  financialTransaction,
}

enum PaymentActivityFlow {
  income,
  expense,
}

PaymentActivityKind paymentActivityKindFromString(String value) {
  switch (value) {
    case 'payment_request':
      return PaymentActivityKind.paymentRequest;
    case 'financial_transaction':
      return PaymentActivityKind.financialTransaction;
    default:
      return PaymentActivityKind.paymentRequest;
  }
}

String paymentActivityKindToString(PaymentActivityKind value) {
  switch (value) {
    case PaymentActivityKind.paymentRequest:
      return 'payment_request';
    case PaymentActivityKind.financialTransaction:
      return 'financial_transaction';
  }
}

PaymentActivityFlow paymentActivityFlowFromString(String value) {
  switch (value) {
    case 'income':
      return PaymentActivityFlow.income;
    case 'expense':
      return PaymentActivityFlow.expense;
    default:
      return PaymentActivityFlow.expense;
  }
}

String paymentActivityFlowToString(PaymentActivityFlow value) {
  switch (value) {
    case PaymentActivityFlow.income:
      return 'income';
    case PaymentActivityFlow.expense:
      return 'expense';
  }
}

class PaymentActivityItem {
  final int id;
  final PaymentActivityKind kind;
  final PaymentActivityFlow flow;

  /// Puede ser `partner_upgrade`, `coin_purchase`, `subscription`,
  /// o el tipo real de la transacción si el backend lo normaliza así.
  final String type;

  final String title;
  final ApprovalStatus status;
  final String statusLabel;

  final double amount;
  final String amountLabel;
  final String currency;

  final DateTime createdAt;
  final DateTime? updatedAt;

  final int? paymentId;
  final int? targetId;

  final String? description;
  final String? comment;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  final int? referenceId;
  final String? purpose;

  const PaymentActivityItem({
    required this.id,
    required this.kind,
    required this.flow,
    required this.type,
    required this.title,
    required this.status,
    required this.statusLabel,
    required this.amount,
    required this.amountLabel,
    required this.currency,
    required this.createdAt,
    this.updatedAt,
    this.paymentId,
    this.targetId,
    this.description,
    this.comment,
    this.reviewedBy,
    this.reviewedAt,
    this.referenceId,
    this.purpose,
  });

  bool get isPaymentRequest => kind == PaymentActivityKind.paymentRequest;
  bool get isFinancialTransaction =>
      kind == PaymentActivityKind.financialTransaction;

  bool get isPending => status == ApprovalStatus.pending;
  bool get isApproved => status == ApprovalStatus.approved;
  bool get isRejected => status == ApprovalStatus.rejected;

  bool get isIncome => flow == PaymentActivityFlow.income;
  bool get isExpense => flow == PaymentActivityFlow.expense;

  IconData get icon {
    if (isPending) {
      return Icons.hourglass_top_rounded;
    }

    if (isRejected) {
      return Icons.close_rounded;
    }

    if (isIncome) {
      return Icons.arrow_downward_rounded;
    }

    return Icons.arrow_upward_rounded;
  }

  Color get iconColor {
    if (isPending) {
      return Colors.orange;
    }

    if (isRejected) {
      return AppColors.error;
    }

    if (isIncome) {
      return Colors.green;
    }

    return AppColors.primary;
  }

  Color get amountColor {
    if (isPending) {
      return Colors.orange;
    }

    if (isRejected) {
      return AppColors.error;
    }

    if (isIncome) {
      return Colors.green;
    }

    return AppColors.primary;
  }

  String get subtitle => statusLabel;

  factory PaymentActivityItem.fromJson(Map<String, dynamic> json) {
    return PaymentActivityItem(
      id: _readInt(json, 'id') ?? 0,
      kind: paymentActivityKindFromString(
        _readString(json, 'kind') ??
            _readString(json, 'activity_kind') ??
            'payment_request',
      ),
      flow: paymentActivityFlowFromString(
        _readString(json, 'flow') ??
            _readString(json, 'movement') ??
            'expense',
      ),
      type: _readString(json, 'type') ?? '',
      title: _readString(json, 'title') ?? '',
      status: _readApprovalStatus(
        _readString(json, 'status') ?? 'pending',
      ),
      statusLabel:
      _readString(json, 'statusLabel') ?? _readString(json, 'status_label') ?? '',
      amount: _readDouble(json, 'amount') ?? 0,
      amountLabel:
      _readString(json, 'amountLabel') ?? _readString(json, 'amount_label') ?? '',
      currency: _readString(json, 'currency') ?? 'BOB',
      createdAt: _readDate(json, 'createdAt') ??
          _readDate(json, 'created_at') ??
          DateTime.now(),
      updatedAt: _readDate(json, 'updatedAt') ?? _readDate(json, 'updated_at'),
      paymentId: _readInt(json, 'paymentId') ?? _readInt(json, 'payment_id'),
      targetId: _readInt(json, 'targetId') ?? _readInt(json, 'target_id'),
      description: _readString(json, 'description'),
      comment: _readString(json, 'comment'),
      reviewedBy:
      _readString(json, 'reviewedBy') ?? _readString(json, 'reviewed_by'),
      reviewedAt: _readDate(json, 'reviewedAt') ??
          _readDate(json, 'reviewed_at'),
      referenceId:
      _readInt(json, 'referenceId') ?? _readInt(json, 'reference_id'),
      purpose: _readString(json, 'purpose'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': paymentActivityKindToString(kind),
      'flow': paymentActivityFlowToString(flow),
      'type': type,
      'title': title,
      'status': approvalStatusToString(status),
      'statusLabel': statusLabel,
      'amount': amount,
      'amountLabel': amountLabel,
      'currency': currency,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
      'paymentId': paymentId,
      'targetId': targetId,
      'description': description,
      'comment': comment,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt?.toUtc().toIso8601String(),
      'referenceId': referenceId,
      'purpose': purpose,
    };
  }

  PaymentActivityItem copyWith({
    int? id,
    PaymentActivityKind? kind,
    PaymentActivityFlow? flow,
    String? type,
    String? title,
    ApprovalStatus? status,
    String? statusLabel,
    double? amount,
    String? amountLabel,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? paymentId,
    int? targetId,
    String? description,
    String? comment,
    String? reviewedBy,
    DateTime? reviewedAt,
    int? referenceId,
    String? purpose,
  }) {
    return PaymentActivityItem(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      flow: flow ?? this.flow,
      type: type ?? this.type,
      title: title ?? this.title,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      amount: amount ?? this.amount,
      amountLabel: amountLabel ?? this.amountLabel,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentId: paymentId ?? this.paymentId,
      targetId: targetId ?? this.targetId,
      description: description ?? this.description,
      comment: comment ?? this.comment,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      referenceId: referenceId ?? this.referenceId,
      purpose: purpose ?? this.purpose,
    );
  }

  static String? _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    return value.toString();
  }

  static int? _readInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;

    if (value is int) return value;
    if (value is double) return value.toInt();

    return int.tryParse(value.toString());
  }

  static double? _readDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;

    if (value is num) return value.toDouble();

    return double.tryParse(value.toString());
  }

  static DateTime? _readDate(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null || value.toString().trim().isEmpty) return null;

    return LocalDateParser.tryParse(value);
  }

  static ApprovalStatus _readApprovalStatus(String value) {
    switch (value) {
      case 'pending':
        return ApprovalStatus.pending;
      case 'approved':
        return ApprovalStatus.approved;
      case 'rejected':
        return ApprovalStatus.rejected;
      case 'failed':
      case 'cancelled':
      case 'reversed':
      default:
        return ApprovalStatus.rejected;
    }
  }
}
