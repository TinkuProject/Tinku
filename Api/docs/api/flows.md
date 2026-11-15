# Flujos De Uso De La API

Este documento centraliza los flujos de punta a punta. Para ver el detalle ruta por ruta, usar `docs/api/routes.md`.

## Principios

- Los flujos de usuario empiezan con `auth` y siguen con contenido, interacción o pagos.
- Los flujos económicos deben pasar por `payments`, `payment_requests`, RPC o `financial_transactions`.
- Los flujos administrativos terminan en aprobación, rechazo, activación, desactivación o auditoría.
- No actualizar `wallets.balance` directamente desde controllers.
- Si una ruta escribe datos críticos, revisar también RLS y RPC asociados.

## 1. Onboarding De Usuario

Uso: alta de usuario final y preparación para consumir la app.

1. Registrar usuario: `POST /auth/register`.
2. Iniciar sesión: `POST /auth/login`.
3. Guardar `session.access_token` y usarlo como Bearer token.
4. Validar sesión: `GET /auth/me`.
5. Consultar wallet: `GET /wallets/me`.
6. Consultar contenido público: businesses, events, tourist places, transport, categories.

Rutas relacionadas:

- `/auth/register`
- `/auth/login`
- `/auth/google`
- `/auth/refresh`
- `/auth/logout`
- `/auth/change-password`
- `/auth/me`
- `/users/me/profile-picture`

Notas:

- El cambio a `partner` ocurre mediante aprobación de `payment_request` tipo `partner_upgrade`.
- `roleMiddleware` mantiene compatibilidad con las rutas existentes, pero traduce los roles declarados a políticas RBAC centrales.

## 2. Upgrade A Partner

Uso: convertir un usuario normal en partner mediante pago revisado.

1. Usuario consulta costo o paquete base:
   - `GET /coin-packages/basic`
   - o configuración relacionada en `system_config`.
2. Usuario crea pago:
   - `POST /payments`
   - `type = partner_upgrade`
3. Usuario sube comprobante si aplica:
   - `POST /storage/upload`
   - `POST /media` con `entity_type = payment`
4. Usuario crea solicitud:
   - `POST /payment-requests`
   - `type = partner_upgrade`
   - `target_id = null`
5. Admin/master revisa:
   - `GET /payment-requests`
   - `PATCH /payment-requests/:id/approve`
   - o `PATCH /payment-requests/:id/reject`
6. Si aprueba, `approve_payment_request`:
   - cambia `users.role` a `partner`;
   - crea wallet si falta;
   - otorga Tinkus según `system_config.upgrade_to_partner`;
   - aprueba payment y request.

## 3. Compra De Tinkus

Uso: cargar saldo interno al wallet.

1. Usuario consulta paquetes:
   - `GET /coin-packages`
   - `GET /coin-packages/:id/active`
2. Usuario crea pago:
   - `POST /payments`
   - `type = coin_purchase`
3. Usuario sube comprobante si aplica.
4. Usuario crea request:
   - `POST /payment-requests`
   - `type = coin_purchase`
   - `target_id = coin_package.id`
5. Admin/master aprueba o rechaza.
6. Usuario verifica:
   - `GET /wallets/me`
   - `GET /financial-transactions/me`
   - `GET /finance/me/activity`

## 4. Suscripción

Uso: activar un plan para un usuario.

1. Usuario consulta planes:
   - `GET /subscription-plans`
   - `GET /subscription-plans/:id`
2. Usuario crea payment.
3. Usuario crea request:
   - `POST /payment-requests`
   - `type = subscription`
   - `target_id = subscription_plan.id`
4. Admin/master aprueba.
5. RPC crea `user_subscriptions` y acredita `included_tinku` si aplica.
6. Usuario consulta:
   - `GET /user-subscriptions/me/current`

Administración:

- `POST /subscription-plans`
- `PATCH /subscription-plans/:id`
- `PATCH /subscription-plans/:id/archive`

## 5. Creación De Negocio

Uso: partner/admin crea negocio y luego se valida.

1. Partner revisa wallet:
   - `GET /wallets/me`
2. Partner consulta costo:
   - `GET /system-config/public/business_create_cost`
3. Partner crea negocio:
   - `POST /businesses`
4. RPC esperado:
   - `create_business_with_charge`
   - crea negocio `pending`;
   - cobra Tinkus con `perform_tinku_spend`.
5. Partner agrega complementos:
   - media: `/storage`, `/media`;
   - horarios: `/opening-hours`;
   - redes: `/social-links`;
   - certificaciones: `/certifications`;
   - transporte: `/entity-transport-relations`.
6. Admin/master revisa:
   - `GET /businesses/status`
   - `PATCH /businesses/:id/validate`
   - o `PATCH /businesses/:id/reject`

Creación administrativa:

- `POST /businesses/system` para cargar negocio desde sistema/admin.

## 6. Claim De Negocio

Uso: partner reclama un negocio existente.

1. Partner consulta negocio:
   - `GET /businesses/:id`
2. Partner crea claim:
   - `POST /business-claim-requests`
3. Partner consulta sus claims:
   - `GET /business-claim-requests/me`
4. Admin/master revisa:
   - `GET /business-claim-requests/pending`
   - `GET /business-claim-requests/business/:businessId`
5. Admin/master decide:
   - `PATCH /business-claim-requests/:id/review`

Resultado esperado al aprobar:

- se asigna `businesses.owner_id`;
- el negocio queda `validated = true` y `status = active`;
- claim pasa a `approved`;
- otros claims pendientes del mismo negocio se rechazan automáticamente;
- se debería registrar auditoría.

## 7. Actualización Moderada De Entidades

Uso: partner propone cambios que requieren revisión.

1. Partner crea update:
   - `POST /entity-updates`
2. Partner consulta:
   - `GET /entity-updates/me`
   - `GET /entity-updates/entity`
3. Admin/master revisa:
   - `GET /entity-updates`
   - `GET /entity-updates/:id`
4. Admin/master decide:
   - `PATCH /entity-updates/:id/approve`
   - `PATCH /entity-updates/:id/reject`

RPC actuales:

- `approve_business_update`
- `approve_event_update`
- `reject_entity_update`

Pendiente:

- si `product` y `certification` siguen como `update_entity_type`, faltan RPC o bloqueo explícito para aprobar esos tipos.

## 8. Productos, Descuentos Y Boosts

Uso: partner administra contenido comercial.

Productos:

1. Público consulta:
   - `GET /products`
   - `GET /products/business/:businessId`
   - `GET /products/:id`
2. Partner/admin gestiona:
   - `GET /products/my`
   - `POST /products`
   - `PUT /products/:id`
   - `DELETE /products/:id`

Descuentos:

1. Público consulta:
   - `GET /discounts`
   - `GET /discounts/business/:businessId`
   - `GET /discounts/business/:businessId/active`
2. Partner/admin crea:
   - `POST /discounts`
3. RPC esperado:
   - `create_discount_with_charge`
   - cobra por días según `discount_create_cost`.

Boosts:

1. Público consulta:
   - `GET /boosts/active`
   - `GET /boosts/entity/:entityType/:entityId`
2. Partner/admin crea:
   - `GET /boosts/promotable-businesses` para seleccionar negocios propios aprobados y activos.
   - `POST /boosts`
3. RPC esperado:
   - `create_boost_with_charge`
   - cobra por días según `boost_create_cost`.

### Marketplace Y Almacenes

Uso: partner publica productos en marketplace, configura retiro/almacenes y admin supervisa pedidos/entregas.

1. Admin/partner crea o gestiona almacenes:
   - `POST /warehouses`
   - `GET /warehouses/mine/list`
   - `GET /warehouses/admin/all`
   - `PATCH /warehouses/:id/status`
   - si lo crea un partner, se cobra `business_create_cost` y queda pendiente de aprobación.
   - el dueño puede crear secciones físicas con `POST /warehouses/:id/locations`.
2. Partner configura entrega de su negocio:
   - `PUT /warehouses/business/:businessId/fulfillment`
   - define `pickup_in_store`, `warehouse_delivery` y `warehouse_ids`.
3. Negocio solicita enviar producto a almacén:
   - `POST /warehouses/stock-requests`
   - el dueño del almacén revisa `GET /warehouses/stock-requests/received`.
   - al aprobar `PATCH /warehouses/stock-requests/:requestId/approve`, se crea/activa la relación negocio-almacén, se habilita `warehouse_delivery`, se suma inventario y queda historial; puede incluir `location_id`.
   - al rechazar `PATCH /warehouses/stock-requests/:requestId/reject`, se exige motivo y se notifica al negocio.
4. Partner publica producto:
   - `POST /marketplace/publications`
   - usa `create_product_publication_with_charge`;
   - cobra según `product_publication_base_cost`, `product_publication_stock_unit_cost` y `product_publication_price_rate`;
   - el marketplace acepta únicamente pago en Tinkus para compras de productos;
   - antes de publicar, `POST /marketplace/publications/estimate` devuelve el costo a cobrar por la publicación.
5. Partner actualiza stock publicado:
   - `PATCH /marketplace/publications/:id/stock`
   - permite actualizar stock y precio en Tinkus;
   - cobra solo el adicional si aumenta el costo calculado;
   - si reduce cantidad, no devuelve Tinkus.
6. Público consulta marketplace:
   - `GET /marketplace/publications`
   - `GET /marketplace/publications/:id`
7. Usuario crea pedido:
   - `POST /marketplace/orders`
   - envia un `client_request_id` UUID y conserva el mismo valor al reintentar; cambiar el contenido con esa clave devuelve conflicto;
   - valida retiro en tienda o almacén habilitado;
   - si elige almacén, suma el cargo logístico según `volume_tier` de cada producto y configs `warehouse_delivery_reward_small|medium|large`;
   - descuenta stock publicado;
   - debita al comprador y mantiene el precio base en custodia hasta completar la entrega.
8. Comprador o vendedor resuelven pedidos que no continuarán:
   - `POST /marketplace/orders/:id/cancel` permite al comprador cancelar un pedido elegible;
   - `POST /marketplace/orders/sales/:id/reject` permite al vendedor rechazarlo con un motivo obligatorio;
   - ambos flujos restituyen stock, liberan reservas de almacén, registran la incidencia y devuelven el total al comprador.
9. Admin/master gestiona operación:
   - `GET /marketplace/admin/orders`
   - `PATCH /marketplace/admin/orders/:id/status`
   - `PATCH /marketplace/admin/deliveries/:id/status`
10. El vendedor o el almacen autorizado marca el pedido como listo; solo el comprador recibe su codigo secreto de retiro.
11. Al validar el QR o codigo vigente de un pedido listo para retirar:
   - `settle_marketplace_order` acredita una sola vez el precio base al vendedor;
   - `reward_warehouse_delivery` acredita al almacén el `reward_tinkus` guardado en la entrega;
   - ambas operaciones quedan registradas en `financial_transactions` y auditoría.
12. Un proceso de mantenimiento cancela los retiros vencidos y reembolsa atomicamente los pedidos elegibles. Una incidencia historica sin fondos suficientes queda para conciliacion, sin fabricar saldo ni aplicar un reembolso parcial.

## 9. Creación Y Aprobación De Evento

Uso: partner crea evento monetizado y admin lo modera.

1. Partner consulta costo:
   - `GET /system-config/public/event_create_cost`
2. Partner crea evento:
   - `POST /events`
3. RPC esperado:
   - `create_event_with_charge`
   - crea evento `pending`;
   - cobra Tinkus.
4. Admin/master revisa:
   - `GET /events/admin`
   - `PATCH /events/:id/approve`
   - `PATCH /events/:id/reject`
5. Público consulta:
   - `GET /events`
   - `GET /events/:id`
   - `GET /events/:id/availability`

## 10. Reserva De Evento

Uso: usuario reserva cupo y paga en Tinkus si el evento tiene precio.

1. Usuario consulta evento:
   - `GET /events/:id`
   - `GET /events/:id/availability`
2. Usuario crea reserva:
   - `POST /reservations`
3. RPC esperado:
   - `create_reservation_with_payment`
   - valida cupo;
   - calcula `tinku_price * quantity`;
   - transfiere Tinkus al owner/creator si corresponde;
   - genera tickets con `generate_event_tickets_for_reservation`.
4. Usuario consulta:
   - `GET /reservations/me`
   - `GET /reservations/event/:eventId/me`
5. Usuario consulta tickets:
   - `GET /event-tickets/reservation/:reservationId`
   - `GET /event-tickets/me`
6. Usuario emite QR:
   - `POST /event-tickets/days/:ticketDayId/qr`
7. Organizador escanea QR:
   - `POST /event-tickets/check-in`
8. Admin/organizador consulta tickets del evento:
   - `GET /event-tickets/event/:eventId`
9. Admin consulta:
   - `GET /reservations`

Reglas de QR:

- El QR usa un token generado por RPC.
- La DB guarda solo `qr_token_hash`, no el token plano.
- En eventos de varios días, cada ticket tiene un ticket-día independiente.
- Al escanear un ticket-día se marca `used`; los demás días siguen activos.
- Al check-in válido se incrementa `events.attendees_count`.

## 11. Reviews, Visitas Y Favoritos

Uso: interacción social sobre entidades.

Reviews:

1. Público consulta:
   - `GET /reviews/entity/:entityType/:entityId`
   - `GET /reviews/entities`
2. Usuario gestiona:
   - `GET /reviews/my`
   - `POST /reviews`
   - `PUT /reviews/:id`
   - `DELETE /reviews/:id`
3. Admin modera:
   - `GET /reviews`
   - `GET /reviews/:id`

Los comentarios de creación/edición y las respuestas del dueño se validan en
la API contra `src/constants/review-blocked-terms.constants.ts`. La lista es
conservadora y no sustituye la moderación humana: admite críticas negativas
sin insultos, pero puede tener falsos positivos o no detectar todas las
variantes. Un texto rechazado responde `400` con un mensaje corregible; una
reseña sin comentario sigue siendo válida.

Visitas/favoritos:

- `POST /user-visits`
- `GET /user-visits/my`
- `GET /user-visits/entity/:entityType/:entityId`
- `DELETE /user-visits/:entityType/:entityId`

## 12. Notificaciones

Uso: bandeja de avisos por usuario.

1. Usuario consulta:
   - `GET /notifications/me`
   - `GET /notifications/unread-count`
2. Usuario marca lectura:
   - `PATCH /notifications/:id/read`
   - `PATCH /notifications/read-all`
3. Sistema/backend crea:
   - `POST /notifications`
4. Broadcast a admins:
   - `POST /notifications/broadcast/admins`
   - requiere admin/master.

## 13. Media Y Storage

Uso: subir archivo físico y asociarlo a una entidad.

1. Subir archivo:
   - `POST /storage/upload`
2. Crear registro:
   - `POST /media`
3. Consultar:
   - `GET /media/entity`
   - `GET /media/entity/primary`
   - `GET /media/entities`
   - `GET /media/:id`
4. Actualizar o eliminar:
   - `PUT /media/:id`
   - `DELETE /media/:id`
   - `DELETE /media/entity`
   - `DELETE /media/url`
   - `DELETE /storage/delete`
   - `DELETE /storage/entity`

Regla:

- Storage maneja archivo; `media` maneja metadata y relación con entidad.

## 14. Turismo

Uso: crear y consultar lugares turísticos.

1. Admin crea categoría:
   - `POST /categories` con `entity_type = tourist_place`
2. Admin crea lugar:
   - `POST /tourist-places`
3. Admin asigna tags:
   - `POST /tourist-place-tags`
   - `PUT /tourist-place-tags/place/:placeId`
4. Admin agrega media y horarios.
5. Público consulta:
   - `GET /tourist-places`
   - `GET /tourist-places/category/:categoryId`
   - `GET /tourist-places/:id`
   - `GET /tourist-place-tags/place/:placeId`
   - `GET /tourist-place-tags/tag/:tagId`
   - `GET /nearby`

## 15. Transporte

Uso: administrar líneas/rutas y asociarlas a entidades.

1. Admin crea tipo de vehículo:
   - `POST /vehicle-types`
2. Admin crea línea:
   - `POST /transport-lines`
3. Admin carga ruta:
   - `POST /transport-routes`
   - `POST /transport-routes/bulk`
4. Partner/admin asocia línea a entidad:
   - `POST /entity-transport-relations`
   - `PUT /entity-transport-relations/:entityType/:entityId`
5. Público consulta:
   - `GET /vehicle-types`
   - `GET /transport-lines`
   - `GET /transport-routes/line/:lineId`
   - `GET /entity-transport-relations/:entityType/:entityId`

Entidades soportadas:

- `business`
- `event`
- `tourist_place`

## 16. Administración Y Auditoría

Uso: revisar acciones críticas y mantener catálogos.

Catálogos:

- `/categories`
- `/vehicle-types`
- `/tags`
- `/charging-points`
- `/coin-packages`
- `/cashout-packages`
- `/subscription-plans`
- `/system-config`

Auditoría:

- `GET /audit-logs`
- `GET /audit-logs/filters`
- `GET /audit-logs/user/:userId`
- `GET /audit-logs/entity/:entityType/:entityId`
- `GET /audit-logs/:id`

Revisar:

- los clientes comunes no insertan directamente en `audit_logs`;
- los flujos críticos escriben auditoría desde RPC o servicios con cliente admin.

## 17. Cashout

Estado actual:

- existen `cashout_packages`;
- existe `transaction_type = cashout`;
- existe `cashout_requests`;
- el flujo HTTP está implementado para solicitud, aprobación y rechazo.

Flujo:

1. Usuario consulta paquetes: `GET /cashout-packages`.
2. Usuario solicita retiro: `POST /cashout-requests` con `cashout_package_id`.
3. Sistema valida paquete activo, saldo suficiente y que no haya otra solicitud pendiente.
4. Usuario puede consultar historial propio: `GET /cashout-requests/me`.
5. Admin/master consulta pendientes: `GET /cashout-requests/pending`.
6. Admin/master aprueba: `PATCH /cashout-requests/:id/approve`.
7. Al aprobar, se descuenta wallet mediante `apply_transaction` con tipo `cashout` y se guarda `transaction_id`.
8. Admin/master rechaza: `PATCH /cashout-requests/:id/reject`.
9. Se audita todo el proceso.

Nota RLS:

- la app/API no inserta directamente en `cashout_requests` desde controllers;
- `POST /cashout-requests` llama al RPC `create_cashout_request`, que es `SECURITY DEFINER`, valida `current_app_user_id()` y crea la fila dentro de la transacción;
- aprobación/rechazo funcionan igual: la tabla no se actualiza directo, se usan `approve_cashout_request` y `reject_cashout_request`.

Pendiente operativo:

- conectar pago externo real;
- definir reverso o compensación si el proveedor falla después de aprobar.

## Rutas Que Requieren Revisión Antes De Exponer En Frontend

- `/media` delete por `/entity` y `/url`: probar orden de rutas dinámicas en Express.
