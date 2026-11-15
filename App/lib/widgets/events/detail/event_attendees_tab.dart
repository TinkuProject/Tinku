import 'package:flutter/material.dart';

import '../../../components/utils.dart';
import '../../../controllers/event/event_detail_controller.dart';
import '../../../helpers/error_message_helper.dart';
import '../../../models/event_ticket_model.dart';
import 'event_qr_scanner_page.dart';

class EventAttendeesTab extends StatefulWidget {
  final EventDetailController controller;

  const EventAttendeesTab({
    super.key,
    required this.controller,
  });

  @override
  State<EventAttendeesTab> createState() => _EventAttendeesTabState();
}

class _EventAttendeesTabState extends State<EventAttendeesTab> {
  Future<void> _openScanner() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Validar asistencia'),
        content: const Text(
          'Si el QR es válido, quedará marcado como usado y no podrá reutilizarse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    final token = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const EventQrScannerPage(),
      ),
    );

    if (token == null || token.trim().isEmpty) return;

    try {
      final result = await widget.controller.validateQrInput(token);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar(_checkInMessage(result), isError: result.status != 'valid'),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        tinkuSnackBar(userFacingError(e), isError: true),
      );
    }
  }

  String _checkInMessage(EventTicketCheckInResultModel result) {
    switch (result.status) {
      case 'valid':
        return 'Asistencia validada correctamente';
      case 'duplicate':
        return 'Este QR ya fue utilizado';
      case 'expired':
        return 'El QR expiró';
      case 'not_yet_valid':
        return 'El QR todavía no está vigente';
      default:
        return result.reason ?? 'QR inválido';
    }
  }

  String _ticketSubtitle(EventTicketModel ticket) {
    final used = ticket.days.where((day) => day.usedAt != null).length;
    final total = ticket.days.length;
    final ci = ticket.attendee?.ci;

    final parts = <String>[
      if (ci != null && ci.trim().isNotEmpty) 'CI: $ci',
      'Asistencias: $used/$total',
    ];

    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return RefreshIndicator(
      onRefresh: controller.loadAttendees,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asistentes confirmados: ${controller.attendeeTickets.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Un QR validado queda usado y no puede reutilizarse.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  icon: controller.validatingQr
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.qr_code_scanner),
                  label: const Text('Validar QR'),
                  onPressed: controller.validatingQr ? null : _openScanner,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (controller.loadingAttendees)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.attendeeTickets.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: Text('Todavía no hay asistentes.')),
            )
          else
            ...controller.attendeeTickets.map((ticket) {
              final attendee = ticket.attendee;
              final title = attendee?.displayName ?? ticket.userId;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    child: Text(
                      title.isNotEmpty ? title[0].toUpperCase() : '?',
                    ),
                  ),
                  title: Text(title),
                  subtitle: Text(_ticketSubtitle(ticket)),
                  trailing: ticket.days.any((day) => day.usedAt != null)
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.pending_actions),
                ),
              );
            }),
        ],
      ),
    );
  }
}
