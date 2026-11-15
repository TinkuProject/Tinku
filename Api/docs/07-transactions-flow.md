# Flujo De Transacciones

Toda operación que cambie Tinkus debe quedar trazada. El wallet es saldo operativo; `financial_transactions` es el historial económico.

## Estados

`transaction_status`:

- `pending`
- `approved`
- `rejected`
- `failed`
- `cancelled`
- `reversed`

Solo operaciones aprobadas deben impactar saldo. Reversos deben quedar explícitos.

## 1. Payment + Payment Request

Uso:

- upgrade a partner;
- compra de Tinkus;
- suscripción.

Flujo:

1. Usuario autenticado crea `payment`.
2. Usuario crea `payment_request`.
3. Admin/master aprueba o rechaza.
4. Al aprobar, `approve_payment_request` actualiza payment/request y aplica el efecto:
   - `partner_upgrade`: cambia rol a `partner` y otorga Tinkus de `upgrade_to_partner`;
   - `coin_purchase`: otorga Tinkus del `coin_package`;
   - `subscription`: crea `user_subscription` y otorga bonus si el plan lo define.

Rutas relacionadas:

- `POST /payments`
- `GET /payments/me`
- `POST /payment-requests`
- `GET /payment-requests/me`
- `PATCH /payment-requests/:id/approve`
- `PATCH /payment-requests/:id/reject`

## 2. Creación Con Cargo

Negocios:

- `POST /businesses`
- RPC: `create_business_with_charge`
- Config: `business_create_cost`

Eventos:

- `POST /events`
- RPC: `create_event_with_charge`
- Config: `event_create_cost`

Descuentos:

- `POST /discounts`
- RPC: `create_discount_with_charge`
- Config: `discount_create_cost`
- Costo = días * costo por día.

Boosts:

- `POST /boosts`
- RPC: `create_boost_with_charge`
- Config: `boost_create_cost`
- Costo = días * costo por día.

Regla común:

- si el usuario no tiene saldo suficiente, la entidad no debería quedar creada.

## 3. Reservas

Ruta:

- `POST /reservations`

RPC:

- `create_reservation_with_payment`

Flujo:

1. Usuario solicita reserva.
2. RPC valida autenticación, cantidad y evento.
3. Valida capacidad.
4. Calcula `event.tinku_price * quantity`.
5. Si el total es mayor que cero, transfiere Tinkus al owner del negocio o creador del evento.
6. Crea reserva `confirmed`.
7. Genera tickets de asistencia:
   - un ticket por unidad de `quantity`;
   - un ticket-día por cada día del evento;
   - los QR se emiten con `issue_event_ticket_day_qr`;
   - el check-in se confirma con `check_in_event_ticket`.

Pendiente a revisar:

- `attendees_count` se incrementa al escanear un QR válido, no al reservar.

## 4. Gasto Manual Controlado

RPC:

- `perform_tinku_spend`

Responsabilidades:

- lock de wallet;
- validar saldo;
- descontar balance;
- insertar `financial_transactions` tipo `spend`.

## 5. Reversos

RPC:

- `reverse_tinku_charge`
- `reverse_transaction`

Reglas:

- solo revertir transacciones aprobadas;
- no borrar historial;
- dejar motivo en descripción/auditoría;
- revisar efecto exacto porque `reverse_transaction` genera `refund`, mientras `reverse_tinku_charge` marca el spend como `reversed` y devuelve saldo.

## 6. Cashout

Flujo implementado:

- `cashout_packages`;
- `cashout_requests`;
- `transaction_type = cashout`.

1. Usuario lista paquetes activos con `GET /cashout-packages`.
2. Usuario crea solicitud con `POST /cashout-requests`.
3. El RPC `create_cashout_request` valida paquete activo, saldo suficiente y que el usuario no tenga otra solicitud pendiente.
4. Admin/master consulta pendientes con `GET /cashout-requests/pending`.
5. Admin/master aprueba con `PATCH /cashout-requests/:id/approve` o rechaza con `PATCH /cashout-requests/:id/reject`.
6. Al aprobar, `approve_cashout_request` bloquea la solicitud, verifica idempotencia, ejecuta `apply_transaction` con `transaction_type = cashout`, descuenta wallet y guarda `transaction_id`.
7. Al rechazar, `reject_cashout_request` conserva historial sin tocar wallet.
8. Ambos caminos escriben auditoría.

Pendiente operativo:

- conectar proveedor de pago externo;
- definir reverso/compensación si el pago externo falla después de aprobar.

## 7. Reglas Globales

1. No actualizar `wallets.balance` desde controllers.
2. No crear gastos sin `financial_transactions`.
3. No aceptar `amount <= 0`.
4. Bloquear wallet al descontar.
5. Validar `current_app_user_id()` en RPC sensibles.
6. Mantener idempotencia cuando haya referencias externas.
7. Auditar aprobaciones, rechazos, check-ins y cambios de ownership.

## Riesgos A Vigilar

- Funciones económicas duplicadas con efectos distintos.
- No agregar mutaciones genéricas de wallet fuera de RPC económicas versionadas.
- Falta de tests automatizados en operaciones atómicas.
- Cashout aún no confirma pago externo real.
