import 'dart:convert';

import '../services/auth_service.dart';
import 'api_error_translations.dart';

String userFacingError(Object error) {
  if (error is ApiException) return error.userMessage;

  var raw = error.toString().trim();
  if (raw.startsWith('Exception:')) {
    raw = raw.substring('Exception:'.length).trim();
  }

  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      raw =
          (decoded['message'] ?? decoded['error'] ?? decoded['details'] ?? raw)
              .toString()
              .trim();
    }
  } catch (_) {
    // No era JSON; usamos el texto ya normalizado.
  }

  final normalized = raw.toLowerCase();
  final translated = translateDomainError(raw);
  if (translated != null) return translated;

  if (normalized.contains('seller balance is insufficient to cancel')) {
    return 'El pedido no puede cancelarse automáticamente porque los fondos ya no están disponibles. Contacta a soporte.';
  }
  if (normalized.contains('network') ||
      normalized.contains('socket') ||
      normalized.contains('connection')) {
    return 'Revisa tu conexión e intenta nuevamente.';
  }
  if ((normalized.contains('insufficient') &&
          (normalized.contains('balance') ||
              normalized.contains('tinku') ||
              normalized.contains('fund'))) ||
      normalized.contains('saldo insuficiente') ||
      normalized.contains('tinkus insuficientes')) {
    return 'No tienes suficientes Tinkus.';
  }
  if (normalized.contains('canceled') ||
      normalized.contains('cancelled') ||
      normalized.contains('cancelado')) {
    return 'Pago cancelado.';
  }
  if (normalized.contains('card_declined') ||
      normalized.contains('declined') ||
      normalized.contains('tarjeta rechazada')) {
    return 'La tarjeta fue rechazada. Verifica los datos o intenta con otra tarjeta.';
  }
  if (normalized.contains('insufficient_funds')) {
    return 'La tarjeta no tiene fondos suficientes.';
  }
  if (normalized.contains('expired_card')) {
    return 'La tarjeta está vencida.';
  }
  if (normalized.contains('incorrect_cvc') ||
      normalized.contains('invalid_cvc')) {
    return 'El código de seguridad de la tarjeta no es válido.';
  }
  if (normalized.contains('authentication_required')) {
    return 'El banco necesita autenticar el pago. Intenta nuevamente.';
  }
  if (normalized.contains('payment_intent_unexpected_state')) {
    return 'Este pago ya no puede completarse. Inicia uno nuevo.';
  }
  if (normalized.contains('payment is still initializing')) {
    return 'El pago todavía se está iniciando. Espera unos segundos e intenta nuevamente.';
  }
  if (normalized.contains('american express') || normalized.contains('amex')) {
    return 'Esta tarjeta no está disponible para pagos en bolivianos. Intenta con otra tarjeta.';
  }
  if (normalized.contains('unauthorized')) return 'No autorizado.';
  if (normalized.contains('forbidden')) return 'No tienes permisos.';
  if (normalized.contains('not found')) return 'No se encontró el recurso.';
  if (normalized.contains('already')) return 'La solicitud ya fue procesada.';
  if (normalized.contains('payment proof')) {
    return 'Debes subir tu comprobante.';
  }
  if (normalized.contains('cannot buy your own product')) {
    return 'No puedes comprar un producto publicado por ti.';
  }
  if (normalized.contains('cannot be paid with tinkus')) {
    return 'Este producto no permite pago con Tinkus.';
  }
  if (normalized.contains('cannot be paid by card')) {
    return 'Este producto no permite pago con tarjeta.';
  }
  if (normalized.contains('insufficient published stock')) {
    return 'No hay stock suficiente para completar el pedido.';
  }
  if (normalized.contains('marketplace order cannot be rejected')) {
    return 'Este pedido ya no puede rechazarse.';
  }
  if (normalized.contains('marketplace order cannot transition')) {
    return 'El pedido cambió de estado. Actualiza la pantalla e intenta nuevamente.';
  }
  if (normalized.contains('business fulfillment must be configured')) {
    return 'Configura retiro en tienda o un almacén antes de publicar productos.';
  }
  if (normalized.contains('marketplace products must have a tinku price')) {
    return 'Configura el precio en Tinkus antes de publicar el producto.';
  }
  if (normalized.contains('pickup is not available') ||
      normalized.contains('warehouse delivery is not available')) {
    return 'Este producto todavía no tiene una opción de retiro disponible.';
  }
  if (normalized.contains('stripe')) {
    return 'No se pudo completar el pago. Intenta nuevamente.';
  }

  if (raw.isEmpty) return 'No se pudo completar la operación.';

  return raw;
}
