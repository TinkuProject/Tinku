import 'package:flutter_test/flutter_test.dart';
import 'package:tinkuapp/core/enums.dart';
import 'package:tinkuapp/helpers/notification_history_helper.dart';
import 'package:tinkuapp/models/notification_model.dart';

void main() {
  NotificationModel notification({
    String? title,
    String message = 'Mensaje de prueba',
  }) {
    return NotificationModel(
      id: 1,
      userId: 'user-id',
      title: title,
      message: message,
      read: false,
      createdAt: DateTime(2026, 9, 23, 10),
    );
  }

  test('agrupa en hoy, esta semana y anteriores', () {
    final now = DateTime(2026, 9, 23, 15);

    expect(
      NotificationHistoryHelper.sectionFor(
        DateTime(2026, 9, 23, 8),
        now: now,
      ),
      NotificationHistorySection.today,
    );
    expect(
      NotificationHistoryHelper.sectionFor(
        DateTime(2026, 9, 20),
        now: now,
      ),
      NotificationHistorySection.thisWeek,
    );
    expect(
      NotificationHistoryHelper.sectionFor(
        DateTime(2026, 9, 10),
        now: now,
      ),
      NotificationHistorySection.older,
    );
  });

  test('resuelve acciones directas sin aceptar rutas arbitrarias', () {
    final order = NotificationHistoryHelper.actionFor(
      notification(
        title: 'Pedido pagado',
        message: 'Tu pedido marketplace fue confirmado.',
      ),
      UserRole.user,
    );
    final review = NotificationHistoryHelper.actionFor(
      notification(title: 'Nueva reseña en tu negocio'),
      UserRole.partner,
    );
    final claim = NotificationHistoryHelper.actionFor(
      notification(message: 'Nuevo reclamo pendiente para un negocio.'),
      UserRole.admin,
    );
    final unknown = NotificationHistoryHelper.actionFor(
      notification(message: 'Contenido no categorizado'),
      UserRole.user,
    );

    expect(order?.label, 'Ver pedido');
    expect(order?.route, '/myMarketplaceOrders');
    expect(review?.label, 'Responder reseña');
    expect(review?.route, '/manageReviews');
    expect(claim?.label, 'Revisar solicitud');
    expect(claim?.route, '/adminBusinessClaims');
    expect(unknown, isNull);
  });
}
