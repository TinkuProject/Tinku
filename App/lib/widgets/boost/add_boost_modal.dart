import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/utils.dart';
import '../../core/enums.dart';
import '../../providers/user_provider.dart';
import '../../services/boost_service.dart';
import '../../ui/themes/colors.dart';
import '../../utils/date/date_formatter.dart';
import '../common/actions/submit_button.dart';

class AddBoostModal extends StatefulWidget {
  final VisitEntity entityType;
  final int entityId;
  final double dailyCost;

  const AddBoostModal({
    super.key,
    required this.entityType,
    required this.entityId,
    required this.dailyCost,
  });

  @override
  State<AddBoostModal> createState() => _AddBoostModalState();
}

class _AddBoostModalState extends State<AddBoostModal> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _loading = false;

  int get _days {
    if (_startDate != null && _endDate != null) {
      final startDay = _dateOnly(_startDate!);
      final endDay = _dateOnly(_endDate!);
      return endDay.difference(startDay).inDays + 1;
    }
    return 0;
  }

  double get _totalCost => _days * widget.dailyCost;

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _effectiveStartDate(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) {
      return now;
    }

    return DateTime(date.year, date.month, date.day);
  }

  DateTime _effectiveEndDate(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  Future<void> _selectDate(bool isStart) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = today.add(const Duration(days: 365));

    final DateTime firstDate;
    DateTime initialDate;

    if (isStart) {
      firstDate = today;
      initialDate = _startDate != null
          ? DateTime(_startDate!.year, _startDate!.month, _startDate!.day)
          : today;
    } else {
      firstDate = _startDate != null
          ? DateTime(_startDate!.year, _startDate!.month, _startDate!.day)
          : today;
      initialDate = _endDate != null
          ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day)
          : (_startDate != null
              ? DateTime(_startDate!.year, _startDate!.month, _startDate!.day)
              : today);
    }

    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    }
    if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (_startDate == null || _endDate == null) {
      showSnackbar("Selecciona las fechas");
      return;
    }

    setState(() => _loading = true);

    try {
      final auth = context.read<UserProvider>().authService;
      final service = BoostService(auth);
      final startDate = _effectiveStartDate(_startDate!);
      final endDate = _effectiveEndDate(_endDate!);

      await service.createBoost(
        entityId: widget.entityId,
        entityType: widget.entityType,
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
      showSnackbar("Impulso creado");
    } catch (_) {
      showSnackbar("Error al crear impulso");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user!;
    final isPartner = user.role == UserRole.partner;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "Crear impulso",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: _startDate != null
                        ? DateFormatter.formatDate(_startDate!)
                        : "Inicio *",
                    onPressed: () => _selectDate(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateButton(
                    label: _endDate != null
                        ? DateFormatter.formatDate(_endDate!)
                        : "Fin *",
                    onPressed: () => _selectDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (isPartner)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.darkBlue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.darkBlue.withValues(alpha: 0.12),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Costo del impulso",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${widget.dailyCost.toStringAsFixed(0)} Tinkus por día",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (_days > 0) ...[
                      const SizedBox(height: 10),
                      Text(
                        "$_days días • ${_totalCost.toStringAsFixed(0)} Tinkus",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Si inicia hoy, comienza al confirmar. La fecha final cubre todo el día seleccionado.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 24),
            SubmitButton(
              loading: _loading,
              text: "Crear impulso",
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _DateButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: AppColors.darkBlue,
        side: BorderSide(
          color: AppColors.darkBlue.withValues(alpha: 0.25),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
