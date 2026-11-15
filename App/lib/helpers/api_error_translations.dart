String? translateDomainError(String message) {
  const messages = <String, String>{
    'email changes require verification':
        'Verifica el nuevo correo antes de guardar el cambio.',
    'stripe payment target mismatch':
        'Los datos del pago no coinciden. Contacta a soporte.',
    'gateway payments must be processed by stripe':
        'Este pago debe completarse con tarjeta.',
    'marketplace order is not ready for pickup':
        'El pedido todavía no está listo para retirar.',
    'marketplace pickup expired':
        'El plazo de retiro venció. Se procesará la devolución de tus Tinkus.',
    'idempotency key reused with different data':
        'La compra pendiente tiene otros datos. Revisa tus compras antes de continuar.',
    'warehouse must accept a stock request first':
        'El almacén debe aceptar primero tu solicitud de productos.',
    'business must be approved before configuring fulfillment':
        'El negocio debe estar aprobado para configurar sus retiros.',
    'receive a stock request before adjusting inventory':
        'Primero debes recibir los productos de una solicitud aprobada.',
    'reserved stock cannot be changed manually':
        'El stock reservado se actualiza automáticamente con los pedidos.',
    'event is not available for reservations':
        'Este evento no está disponible para reservas.',
    'invalid reservation transition':
        'No se puede realizar ese cambio en la reserva.',
    'used or finished reservations cannot be cancelled':
        'No se puede cancelar una reserva utilizada o de un evento finalizado.',
    'reservation refund requires review':
        'Esta reserva necesita una revisión para devolver los Tinkus. Contacta a soporte.',
    'organizer balance is insufficient for refund':
        'La devolución necesita revisión porque el organizador no tiene saldo disponible. Contacta a soporte.',
    'boost target and start date cannot be changed':
        'El negocio y la fecha de inicio del impulso no se pueden cambiar.',
  };
  final normalized = message.toLowerCase();
  for (final entry in messages.entries) {
    if (normalized.contains(entry.key)) return entry.value;
  }
  return null;
}
