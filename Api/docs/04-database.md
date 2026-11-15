# Base De Datos

La base de datos de Tinku corre sobre PostgreSQL. El esquema usa UUIDs, PostGIS, funciones RPC, índices espaciales y jobs programados opcionales.

## Scripts Versionados

Ejecutar en este orden al reconstruir una base:

1. `database/01-db.sql`: borra y recrea `public`, crea extensiones, enums, tablas e índices.
2. `database/02-functions.sql`: funciones helper y RPC de negocio.
3. `database/03-triggers.sql`: triggers.
4. `database/04-init.sql`: inicializacion de seguridad para API propia.
5. `database/05-jobs.sql`: jobs con `pg_cron`.

`database/01-db.sql` contiene `DROP SCHEMA public CASCADE`; usarlo solo en entornos descartables o con respaldo.

Para bases ya creadas, los cambios incrementales nuevos viven en `database/migrations/`.
Cada migración debe ser idempotente cuando sea razonable y debe tener su equivalente reflejado en los scripts numerados para que una base nueva nazca actualizada.

## Extensiones

- `pgcrypto`: UUIDs/funciones criptográficas.
- `postgis`: columnas `geography(Point, 4326)` y búsquedas geográficas.
- `pg_cron`: jobs programados, opcional segun el entorno.

## 1. Acceso

### users

Perfil del usuario autenticado por la API.

Campos clave:

- `id uuid`: identificador primario generado por PostgreSQL.
- `role user_role`: `user`, `partner`, `admin`, `master`.
- `status user_status`.
- `location geography(Point, 4326)`.

Relaciones:

- 1:1 con `wallets`.
- 1:N con `payments`, `financial_transactions`, `reviews`, `reservations`, `notifications`.
- N:M con `labels` vía `user_labels`.

### permissions

Catálogo de acciones del sistema (`code`, `description`). Existe para autorización granular, aunque el middleware HTTP actual valida roles.

### role_permissions

Asocia permisos a roles base.

### labels, label_permissions, user_labels

Labels agrupan permisos y se asignan a usuarios. `authMiddleware` combina estos permisos con los del rol en cada autenticación HTTP.

## 2. Economía

### wallets

Saldo cacheado por usuario.

Reglas:

- PK: `user_id`.
- `balance >= 0`.
- No debe ser la fuente de verdad.
- Debe modificarse solo mediante funciones controladas.

### payments

Pagos externos o comprobantes de pago.

Campos clave:

- `method payment_method`: `qr`, `gateway`, `cash_point`.
- `status payment_status`.
- `type payment_type`: `partner_upgrade`, `coin_purchase`, `subscription`.
- `amount`, `currency`, `external_reference`.

### payment_requests

Solicitud revisable asociada a un `payment`.

Uso actual:

- upgrade a partner;
- compra de paquetes de Tinkus;
- suscripciones.

Restricción:

- `partner_upgrade` no requiere `target_id`.
- `coin_purchase` y `subscription` sí requieren `target_id`.
- Solo puede existir una solicitud pendiente por usuario y tipo.

### financial_transactions

Fuente de verdad económica.

Campos clave:

- `type transaction_type`.
- `status transaction_status`.
- `amount int`.
- `purpose text`.
- `reference_id bigint`.
- `payment_id bigint`.

Reglas:

- No eliminar transacciones.
- Evitar updates directos.
- El wallet solo debe cambiar cuando la operación queda aprobada o revertida mediante RPC.

### coin_packages

Paquetes de compra de Tinkus.

### cashout_packages

Paquetes de retiro de Tinkus a dinero real.

### cashout_requests

Solicitudes de retiro creadas por usuarios y revisadas por admin/master.

Campos clave:

- `user_id`: solicitante.
- `cashout_package_id`: paquete usado.
- `status`: `pending`, `approved` o `rejected`.
- `tinkus_amount` y `cash_amount`: snapshot del paquete al crear la solicitud.
- `reviewed_by`, `reviewed_at`, `comment`: datos de revisión.
- `transaction_id`: transacción `cashout` generada al aprobar.

Reglas:

- solo una solicitud pendiente por usuario;
- el descuento de wallet ocurre únicamente al aprobar vía RPC;
- aprobar/rechazar escribe auditoría.

### system_config

Configuraciones dinámicas. Claves usadas por RPC:

- `upgrade_to_partner`
- `business_create_cost`
- `event_create_cost`
- `discount_create_cost`
- `boost_create_cost`
- `product_publication_base_cost`
- `product_publication_stock_unit_cost`
- `product_publication_price_rate`
- `marketplace_service_fee_rate`
- `warehouse_delivery_reward_tinkus`

### audit_logs

Auditoría de acciones críticas. La escritura se centraliza desde RPC (`write_audit_log`) o servicios con cliente admin; los clientes comunes no insertan directo.

## 3. Negocios

### categories

Categorías por tipo de entidad (`business`, `event`, `tourist_place`, `product`) y opcionalmente por `business_type`.

### businesses

Negocios/servicios.

Campos clave:

- `owner_id uuid`: puede ser `NULL`.
- `business_type business_type`.
- `location geography(Point, 4326)`.
- `validated boolean`.
- `status business_status`: incluye `pending`.

Creación con cargo:

- `create_business_with_charge`.

### business_claim_requests

Solicitudes de propiedad de negocios.

Campos clave:

- `status approval_status`.
- `documents text[]`.
- `reviewed_by`, `reviewed_at`.

Índice:

- solo un claim pendiente por usuario y negocio.

### entity_updates

Solicitudes de cambios pendientes para entidades.

Soporta:

- `business`
- `event`
- `product`
- `certification`

RPC actuales de aprobación:

- `approve_business_update`
- `approve_event_update`
- `reject_entity_update`

## 4. Contenido

### products

Productos de negocios. Para marketplace se compra con Tinkus (`tinku_price`). `volume_tier` clasifica el volumen logístico: `small`, `medium` o `large`.

### product_publications

Publicaciones activas o históricas de productos dentro del marketplace.

Campos clave:

- `product_id`, `business_id`, `created_by`.
- `published_stock`: stock ofrecido en marketplace.
- `unit_tinku_price`: snapshot del precio en Tinkus al publicar/actualizar.
- `unit_price`: queda nulo para publicaciones nuevas; se conserva por compatibilidad histórica.
- `payment_mode`: `tinkus`.
- `calculated_cost_tinkus`: costo calculado según catálogo.
- `charged_tinkus`: total efectivamente cobrado.
- `status marketplace_publication_status`.

RPC:

- `calculate_product_publication_cost`: calcula costo base + stock + factor por precio en Tinkus.
- `create_product_publication_with_charge`: crea publicación y cobra Tinkus.
- `update_product_publication_with_charge`: actualiza stock/precio en Tinkus; cobra solo adicional si aumenta el costo y no devuelve Tinkus si se reduce stock.

### product_publication_history

Historial de cambios de stock y costo de una publicación. Permite auditar cuánto se cobró al crear o actualizar.

### warehouses

Almacenes externos que pueden recibir productos para entrega.

Campos clave:

- `owner_id uuid`: responsable del almacén; puede ser `NULL` hasta asignación.
- `location geography(Point, 4326)`.
- `status warehouse_status`.
- `phone`, `email`, `address`, `notes`.

Los almacenes no se modelan como `business_type`; tienen tabla propia para separar operación logística de comercios/servicios.

Creación con cargo:

- `create_warehouse_with_charge`: crea almacén pendiente y cobra `business_create_cost` al usuario autenticado, incluidos admin/master.

### Códigos de autenticación

`auth_verification_codes` conserva únicamente el hash HMAC del código. También registra `attempt_count`, `max_attempts` y `requested_ip` para aplicar vencimiento, límite de intentos y rate limiting aunque la API se reinicie. La migración incremental correspondiente es `0020_auth_code_security.sql`.

La migración `0023_centralize_rbac_permissions.sql` registra las políticas RBAC base y sus asignaciones por rol. Los scripts de creación desde cero incluyen la misma matriz en `01-db.sql`.

### business_fulfillment_options

Opciones de entrega/retiro por negocio.

Campos clave:

- `business_id`.
- `pickup_in_store`.
- `warehouse_delivery`.
- `notes`.

### business_warehouses

Relación entre negocios/tiendas y almacenes habilitados para enviar productos.

### charging_point_warehouses

Relación entre tiendas de recarga y almacenes asociados.

### warehouse_inventory

Stock de productos por almacén. Mantiene estado por producto/almacén y permite reservar, entregar o cancelar unidades. `location_id` es opcional y apunta a una ubicación interna del almacén.

### warehouse_locations

Secciones físicas internas de cada almacén. Permiten representar estantes, niveles, zonas o divisiones propias de cada almacén.

- `warehouse_id`: almacén dueño de la estructura.
- `parent_id`: ubicación padre opcional para jerarquías simples.
- `code`: código visible, único dentro del almacén, por ejemplo `E1`.
- `name`, `description`, `sort_order`.
- `status basic_status`: se desactiva en vez de eliminar físicamente cuando ya fue usada.

### warehouse_stock_requests

Solicitudes para que un negocio envíe productos a un almacén. El negocio crea la solicitud y el dueño del almacén la aprueba o rechaza. Al aprobar, se activa la relación negocio-almacén, se habilita entrega por almacén para el negocio, se suma inventario, opcionalmente se asigna ubicación interna y se registra historial.

### warehouse_product_history

Historial operativo de movimientos de inventario de almacén.

### marketplace_orders y marketplace_order_items

Pedidos de marketplace y sus items. Soportan retiro en tienda o entrega desde almacén (`fulfillment_method`).

- `marketplace_orders.warehouse_delivery_fee_tinkus`: cargo logístico total cobrado al comprador cuando retira por almacén.
- `marketplace_order_items.warehouse_reward_tinkus`: porción del cargo logístico calculada por producto/cantidad según `products.volume_tier`.

### deliveries

Entregas asociadas a pedidos y almacenes. Guardan `reward_tinkus` al crear la entrega. Al completarse, `reward_warehouse_delivery` acredita esa recompensa en Tinkus al dueño del almacén y guarda `reward_transaction_id`.

### events

Las ediciones que modifiquen `start_date` o `end_date` combinan los valores
enviados con los valores persistidos. El resultado debe finalizar en el futuro,
tener fin posterior al inicio y durar al menos 30 minutos. La función
`approve_event_update` repite esta validación dentro de la transacción.

Eventos creados por usuarios/partners/admin.

Campos clave:

- `business_id` opcional.
- `creator_id`.
- `capacity`, `attendees_count`, `tinku_price`.
- `status event_status`.
- `location geography(Point, 4326)`.

Creación con cargo:

- `create_event_with_charge`.

### discounts

Promociones asociadas a negocios. Creación con cargo mediante `create_discount_with_charge`.

### boosts

Impulsos de visibilidad para `business`, `event` o `tourist_place`. Creación con cargo mediante `create_boost_with_charge`.

## 5. Interacción

### user_visits

Registra visitas y favoritos por usuario y entidad. Índice único para evitar duplicados por tipo.

### reviews

Reseñas sobre `tourist_place`, `business`, `event` o `product`.

### reservations

Reservas de eventos.

RPC:

- `create_reservation_with_payment`: valida usuario, capacidad, saldo, transfiere Tinkus si el evento tiene precio y genera tickets.

### event_tickets

Tickets generados a partir de una reserva confirmada.

Reglas:

- Una reserva con `quantity = N` genera N tickets.
- Cada ticket pertenece a un usuario, reserva y evento.
- No guarda el token QR plano.
- `attendee_index` identifica la entrada dentro de la reserva.

### event_ticket_days

Entradas escaneables por día.

Reglas:

- Un evento de un día genera un ticket-día por ticket.
- Un evento de varios días genera un ticket-día por cada día del evento.
- Cada ticket-día tiene su propia ventana `valid_from` / `valid_until`.
- El QR se emite/rota mediante RPC y solo se guarda `qr_token_hash`.
- Al escanear se marca `used`; si ya fue usado devuelve duplicado.

RPC:

- `issue_event_ticket_day_qr`: emite un token QR para el usuario dueño del ticket-día.
- `check_in_event_ticket`: valida token, permisos del organizador, vigencia y marca asistencia.

### notifications

Notificaciones por usuario, con `sender_id` opcional.

### business_view_daily y business_view_totals

Métricas agregadas de vistas de negocios.

Regla recomendada:

- Dueño, admin y master pueden ver totales y tendencia diaria.
- No guardar ni mostrar identidad del visitante salvo que más adelante exista un caso legal/productivo muy claro.
- Registrar la vista mediante `register_business_view` al abrir el detalle público de un negocio activo.

## 6. Transporte

### vehicle_types

Catálogo de tipos de transporte.

### transport_lines

Líneas de transporte.

### transport_routes

Puntos geográficos ordenados por línea y dirección (`outbound`, `return`).

### entity_transport_relations

Relación entre una línea y una entidad (`business`, `event`, `tourist_place`).

## 7. Turismo

### tourist_places

Lugares turísticos con ubicación geográfica y categoría.

### tags

Etiquetas turísticas.

### tourist_place_tags

Relación N:M entre lugares turísticos y tags.

## 8. Monetización

### subscription_plans

Planes de suscripción con precio, duración e incentivo en Tinkus.

### user_subscriptions

Suscripciones activas/históricas de usuarios.

## 9. Soporte Y Metadata

### social_links

Redes sociales por negocio.

### opening_hours

Horarios por entidad (`business`, `event`, `tourist_place`, `charging_point`).

### charging_points

Puntos físicos geolocalizados.

### certifications

Certificaciones de negocios.

### media

Recursos multimedia asociados a entidades.

`media_entity_type` actual:

- `business`
- `event`
- `tourist_place`
- `product`
- `user`
- `review`
- `certification`
- `category`
- `payment`
- `coin_package`
- `subscription`
- `discount`
- `transport_line`
- `charging_point`
- `warehouse`
- `product_publication`

## RPC Principales

- `create_wallet`
- `apply_transaction`
- `transfer_tinku`
- `admin_adjustment`
- `create_payment`
- `approve_payment`
- `reverse_transaction`
- `approve_payment_request`
- `reject_payment_request`
- `perform_tinku_spend`
- `reverse_tinku_charge`
- `create_business_with_charge`
- `create_warehouse_with_charge`
- `create_event_with_charge`
- `create_discount_with_charge`
- `create_boost_with_charge`
- `create_reservation_with_payment`
- `calculate_product_publication_cost`
- `create_product_publication_with_charge`
- `update_product_publication_with_charge`
- `reward_warehouse_delivery`
- `register_business_view`
- `generate_event_tickets_for_reservation`
- `issue_event_ticket_day_qr`
- `check_in_event_ticket`
- `approve_business_update`
- `approve_event_update`
- `reject_entity_update`
- `get_nearby_entities`

## Índices Importantes

- Índices GIST sobre ubicaciones: businesses, events, tourist_places, transport_routes, charging_points.
- Unicidad de visita/review por usuario y entidad.
- Unicidad de media primaria por entidad.
- Unicidad de claims, payment requests y entity updates pendientes.
- Índices por `status`, `created_at`, `user_id`, `entity_type/entity_id` en tablas de alto uso.

## Pendientes Técnicos

- Agregar triggers `updated_at` a todas las tablas que tienen ese campo.
- Validar que todos los RPC versionados existan en Supabase real.
- Mantener wallet como saldo derivado/cacheado; cualquier nuevo cambio de balance debe agregarse como RPC versionada en `database/02-functions.sql`.
- Añadir pruebas de reconstrucción de schema.
