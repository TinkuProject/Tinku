# Economía Tinku

La economía de Tinku maneja valor interno mediante wallets, pagos externos, solicitudes de pago y transacciones financieras. La regla de diseño sigue siendo: el wallet es saldo cacheado; la trazabilidad vive en `financial_transactions`.

## Tablas Principales

- `wallets`: saldo actual por usuario.
- `payments`: pago externo o comprobante.
- `payment_requests`: solicitud revisable asociada a un pago.
- `financial_transactions`: movimientos económicos.
- `coin_packages`: paquetes de compra de Tinkus.
- `cashout_packages`: paquetes de retiro configurables.
- `cashout_requests`: solicitudes de retiro revisadas por admin/master.
- `subscription_plans`: planes de suscripción.
- `user_subscriptions`: suscripciones de usuarios.
- `product_publications`: publicaciones pagadas de productos en marketplace.
- `system_config`: costos y valores dinámicos.
- `audit_logs`: auditoría.

## Configuración Económica

Claves esperadas en `system_config`:

- `upgrade_to_partner`: Tinkus otorgados al aprobar upgrade.
- `business_create_cost`: costo para crear negocio con cargo.
- `event_create_cost`: costo para crear evento.
- `discount_create_cost`: costo por día para descuento.
- `boost_create_cost`: costo por día para boost.
- `product_publication_base_cost`: costo base para publicar un producto en marketplace.
- `product_publication_stock_unit_cost`: costo por unidad de stock publicada.
- `product_publication_price_rate`: factor aplicado al precio para calcular costo adicional.
- `marketplace_service_fee_rate`: incremento aplicado al precio visible en marketplace.
- `warehouse_delivery_reward_tinkus`: recompensa para almacenes por entrega completada.

## RPC Económicos Actuales

- `create_wallet(p_user_id)`: crea wallet idempotente.
- `apply_transaction(...)`: inserta transacción y aplica efecto si está aprobada.
- `transfer_tinku(...)`: registra gasto para origen y recompensa para destino.
- `admin_adjustment(...)`: ajuste administrativo.
- `create_payment(...)`: crea payment pendiente.
- `approve_payment(...)`: aprueba payment y crea transacción.
- `approve_payment_request(...)`: aprueba upgrade, compra de Tinkus o suscripción.
- `reject_payment_request(...)`: rechaza request y payment.
- `perform_tinku_spend(...)`: descuenta wallet y registra spend.
- `reverse_tinku_charge(...)`: revierte un spend aprobado.
- `create_business_with_charge(...)`: crea negocio pending y cobra.
- `create_warehouse_with_charge(...)`: crea almacén pending y cobra el mismo costo de creación de negocio.
- `create_event_with_charge(...)`: crea evento pending y cobra.
- `create_discount_with_charge(...)`: crea descuento y cobra por días.
- `create_boost_with_charge(...)`: crea boost y cobra por días.
- `calculate_product_publication_cost(...)`: calcula el costo de publicación según stock y precio en Tinkus.
- `create_product_publication_with_charge(...)`: publica producto en marketplace y cobra.
- `update_product_publication_with_charge(...)`: actualiza stock y precio en Tinkus; cobra solo el adicional si corresponde.
- `reward_warehouse_delivery(...)`: acredita recompensa por entrega completada de almacén.
- `create_reservation_with_payment(...)`: crea reserva y transfiere Tinkus al dueño/creador del evento.
- `create_cashout_request(...)`: crea solicitud de retiro validando paquete activo, saldo y una sola pendiente por usuario.
- `approve_cashout_request(...)`: aprueba solicitud, registra transacción `cashout` y descuenta wallet.
- `reject_cashout_request(...)`: rechaza solicitud pendiente.
- `write_audit_log(...)`: inserta auditoría desde RPC/servicios confiables.

## Flujo De Compra O Suscripción

### Flujo manual

1. Usuario autenticado crea un `payment`.
2. Usuario crea `payment_request`:
   - `partner_upgrade`: sin `target_id`.
   - `coin_purchase`: `target_id` = `coin_packages.id`.
   - `subscription`: `target_id` = `subscription_plans.id`.
3. Admin/master aprueba o rechaza.
4. Si aprueba, el RPC:
   - valida estado pendiente;
   - valida coherencia con `payment.type`;
   - actualiza `payments.status`;
   - actualiza `payment_requests.status`;
   - crea wallet si hace falta;
   - aplica Tinkus o suscripción según el tipo.

### Flujo Stripe

1. Usuario autenticado llama `POST /stripe/payment-intents`.
2. La API calcula el monto desde `coin_packages`, `subscription_plans` o el paquete `partner_upgrade`.
3. La API crea `payment` con `method = gateway` y devuelve `clientSecret`.
4. Stripe confirma el cobro y envía `payment_intent.succeeded` a `/stripe/webhook`.
5. El webhook firmado crea la `payment_request` si no existe y ejecuta `approve_stripe_payment_request`, que valida `payments.external_reference` contra el `payment_intent.id` antes de acreditar Tinkus, activar suscripción o cambiar rol.

Detalles operativos:

- Si el usuario cancela PaymentSheet, la App llama `POST /stripe/payment-intents/:paymentIntentId/cancel` y la API marca el `payment` como `cancelled`.
- Al iniciar un nuevo pago Stripe, la API expira intentos gateway pendientes del mismo usuario y tipo con más de 30 minutos.
- Los webhooks se registran en `stripe_webhook_events` para que reintentos de Stripe no generen aprobaciones o notificaciones duplicadas.
- Los pagos gateway guardan `amount_minor` y `currency_minor_unit` para conservar el monto exacto enviado a Stripe; `amount` se mantiene por compatibilidad con App/Web y reportes existentes.

Para bases existentes, correr `database/10-stripe-payments.sql`.

## Flujo De Gasto

Los gastos no deberían hacer `UPDATE wallets` desde controllers.

Flujos actuales con cargo:

- Crear negocio.
- Crear almacén.
- Crear evento.
- Crear descuento.
- Crear boost.
- Publicar o ampliar stock de productos en marketplace.
- Reservar evento con precio.
- Comprar producto de marketplace con retiro por almacén, sumando el cargo logístico por volumen.

Regla administrativa:

- `admin` y `master` no pagan por crear negocios, eventos, promociones, boosts ni publicaciones de marketplace.
- La creación de almacenes es la única excepción: siempre cobra `business_create_cost`, sin importar el rol.
- En publicaciones administrativas se conserva el costo calculado y el historial, pero `charged_tinkus` y el cargo adicional quedan en `0`.
- Las compras, reservas y demás consumos personales no se vuelven gratuitos por tener rol administrativo.

Cada flujo usa RPC para que la creación de entidad y el cobro sean atómicos. Si falla el cobro, la creación debe revertirse por transacción de DB.

Recompensa de almacenes:

- `warehouse_delivery_reward_small`: cargo/recompensa por producto pequeño.
- `warehouse_delivery_reward_medium`: cargo/recompensa por producto mediano.
- `warehouse_delivery_reward_large`: cargo/recompensa por producto grande.
- El cliente paga este cargo al crear el pedido si elige retiro/gestión por almacén.
- La entrega guarda `reward_tinkus`; el dueño del almacén recibe esos Tinkus cuando la entrega pasa a `delivered`.

## Wallets

Reglas:

- `balance` no puede ser negativo.
- No escribir directamente desde endpoints.
- Validar saldo con lock cuando se descuenta.
- Mantener consistencia con `financial_transactions`.

Regla actual:

- El DAO de wallets no debe exponer incrementos/decrementos genéricos. Los cambios de saldo se hacen desde RPC económicas versionadas.

## Cashout

Flujo actual:

1. Usuario consulta paquetes activos: `GET /cashout-packages`.
2. Usuario crea solicitud: `POST /cashout-requests`.
3. El endpoint no inserta directo en `cashout_requests`; llama al RPC `create_cashout_request`.
4. `create_cashout_request` valida:
   - usuario autenticado;
   - paquete activo;
   - saldo suficiente;
   - que no exista otra solicitud pendiente.
5. Admin/master revisa pendientes: `GET /cashout-requests/pending`.
6. Admin/master aprueba o rechaza:
   - `PATCH /cashout-requests/:id/approve`;
   - `PATCH /cashout-requests/:id/reject`.
7. Al aprobar, `approve_cashout_request` ejecuta `apply_transaction(..., 'cashout', ..., 'approved', ...)`, descuenta wallet y guarda `transaction_id`.
8. Todo el ciclo escribe auditoría.

Pendiente:

- ejecución de pago externo;
- reverso o compensación si el proveedor externo falla después de aprobar.

## Auditoría

El sistema audita operaciones críticas:

- aprobaciones/rechazos de pagos;
- reservas y check-in de tickets QR;
- creación con cargo de negocio/evento/descuento/boost;
- cashout;
- claims de negocio y cambios de ownership.

La escritura se hace desde RPC (`write_audit_log`) o desde servicios usando cliente admin. Los clientes comunes no insertan directamente en `audit_logs`.

## Invariantes

1. Ninguna operación económica debe quedar sin `financial_transactions`.
2. Ningún gasto debe permitir saldo negativo.
3. `payments` registra dinero externo; `financial_transactions` registra Tinkus.
4. `payment_requests` modela revisión administrativa.
5. Las operaciones críticas deben ser idempotentes cuando sea posible.
6. Los costos deben salir de `system_config`, no de valores hardcodeados.
7. Una compra de marketplace debe debitar al comprador y mantener el precio base en custodia hasta completar la entrega.
8. Al completar la entrega, la liquidación acredita una sola vez al vendedor y, cuando corresponde, la recompensa del almacén.
9. Una cancelación o rechazo previo a la entrega devuelve al comprador el total debitado y no genera una liquidación al vendedor.
10. Cada compra incluye un UUID persistente `client_request_id`: un reintento conserva pedido y cobro, incluso si ya no queda stock.
11. El retiro exige estado listo y plazo vigente. Los no recogidos se cancelan y reembolsan por mantenimiento de la API; las notificaciones tienen cola push persistente.
12. Las reservas se cancelan mediante `cancel_reservation_with_refund`, conservando historial y tickets anulados. No se reconfirman sin validar una nueva reserva.
