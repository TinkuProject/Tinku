import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../components/utils.dart';
import '../../../controllers/event/event_detail_controller.dart';
import '../../../models/event_ticket_model.dart';

class AttendSection extends StatelessWidget {
  final EventDetailController controller;

  const AttendSection({
    super.key,
    required this.controller,
  });

  Widget _statusBox(String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _showQrDialog(
    BuildContext context,
    EventTicketQrModel qr,
  ) async {
    final eventDay = DateTime.tryParse(qr.eventDate)?.toLocal();
    final dateLabel = eventDay != null
        ? DateFormat('dd MMM yyyy', 'es').format(eventDay)
        : qr.eventDate;
    final validUntilLabel = DateFormat(
      'dd MMM yyyy HH:mm',
      'es',
    ).format(qr.validUntil);

    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QR de asistencia',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Presenta este QR para validar tu asistencia. Cada QR se usa una sola vez; después de validarlo no podrá reutilizarse.',
                ),
                const SizedBox(height: 12),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: QrImageView(
                      data: qr.qrToken,
                      version: QrVersions.auto,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Válido para el día $dateLabel hasta $validUntilLabel',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
              ),
    );
  }

  @override
  Widget build(BuildContext context) {

    if (controller.isFinished) {
      return _statusBox("Este evento ya finalizó", Colors.grey);
    }

    if (controller.isConfirmed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _statusBox("Ya estás asistiendo", Colors.green),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: controller.issuingQr
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.qr_code_2),
            label: Text(
              controller.issuingQr
                  ? 'Generando...'
                  : 'Generar QR de asistencia',
            ),
            onPressed: controller.issuingQr
                ? null
                : () async {
                    try {
                      final qr = await controller.issueQrForFirstAvailableDay();

                      if (!context.mounted) return;

                      if (qr == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          tinkuSnackBar(
                            'No hay tickets activos para emitir QR',
                            isError: true,
                          ),
                        );
                        return;
                      }

                      await _showQrDialog(context, qr);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        tinkuSnackBar(
                          'No se pudo generar QR: $e',
                          isError: true,
                        ),
                      );
                    }
                  },
          ),
        ],
      );
    }

    if (controller.isFull) {
      return _statusBox("Evento lleno", Colors.red);
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: controller.loadingReservation
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const Icon(Icons.event_available),
        label: Text(
          controller.loadingReservation
              ? "Procesando..."
              : (controller.isFree ? "Reservar" : "Reservar y pagar"),
        ),
        onPressed: controller.loadingReservation
            ? null
            : () async {
          final (success, message) =
          await controller.reserveAndPay();

          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            tinkuSnackBar(message, isError: !success),
          );
        },
      ),
    );
  }
}
