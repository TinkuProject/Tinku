# Catálogo Central De Rutas

Este documento centraliza para qué sirve cada ruta de la API. La fuente técnica es `src/routes`; si cambia una ruta, actualizar este archivo y el flow correspondiente.

Convenciones:

- `Público`: no requiere token en Express.
- `Auth`: requiere `Authorization: Bearer <token>`.
- `Admin`: requiere rol `admin` o `master`.
- `Master`: requiere rol `master`.
- `Partner`: requiere rol `partner`, salvo que se indique admin/master.
- Las rutas están montadas sin prefijo global. Ejemplo: `auth.routes.ts` se monta en `/auth`.

## Auth

| Método | Ruta | Acceso | Uso |
|---|---|---:|---|
| POST | `/auth/register` | Público | Registra siempre rol `user`, crea wallet y envía código mediante Resend; no devuelve sesión hasta verificar el correo. |
| POST | `/auth/login` | Público | Inicia sesión con email/password sólo si la cuenta está activa y el correo está verificado. |
| POST | `/auth/google` | Público | Login con token/proveedor Google. |
| POST | `/auth/refresh` | Público | Renueva sesión usando refresh token. |
| POST | `/auth/logout` | Público | Cierra sesión del usuario. |
| POST | `/auth/email/verification-code` | Público | Reenvía el código de verificación con cooldown y rate limit persistente. |
| POST | `/auth/email/verify-code` | Público | Verifica el correo; cada código tiene intentos limitados. |
| POST | `/auth/password/recovery-code` | Público | Envía código de recuperación sin revelar si el correo existe. |
| POST | `/auth/password/reset-with-code` | Público | Restablece contraseña, verifica el correo y revoca refresh tokens previos. |
| POST | `/auth/change-password` | Auth | Cambia contraseña del usuario autenticado. |
| POST | `/auth/email/change-code` | Auth | Envia un codigo al nuevo correo; todavia no modifica la cuenta. |
| POST | `/auth/email/change` | Auth | Confirma email y codigo, vincula el nuevo correo verificado. |
| GET | `/auth/me` | Auth | Devuelve usuario autenticado actual. |

Flujo típico: register/login -> guardar token -> `/auth/me`.

## Users, Roles Y Permisos

| Método | Ruta | Acceso | Uso |
|---|---|---:|---|
| GET | `/users` | Admin | Lista usuarios. |
| GET | `/users/batch` | Público | Obtiene perfiles públicos sanitizados por lista de UUIDs (`ids`). |
| GET | `/users/me/profile-picture` | Auth | Obtiene foto de perfil del usuario autenticado. |
| POST | `/users/me/profile-picture` | Auth | Actualiza foto de perfil del usuario autenticado. |
| PUT | `/users/me` | Auth | Actualiza únicamente datos personales propios; rechaza `role`, `status`, `id` y campos técnicos. |
| POST | `/users` | Admin | Crea un usuario local de cualquier rol y su wallet. |
| GET | `/users/:id` | Admin | Obtiene usuario por id. |
| PUT | `/users/:id` | Admin | Actualiza usuario por id, incluido rol/estado. |
| DELETE | `/users/:id` | Admin | Elimina/desactiva usuario por id. |
| GET | `/permissions/me` | Auth | Devuelve permisos efectivos/visibles del usuario autenticado. |
| GET | `/permissions` | Admin | Lista permisos disponibles. |
| GET | `/permissions/code/:code` | Admin | Busca permiso por código. |
| GET | `/permissions/:id` | Admin | Obtiene permiso por id. |
| POST | `/permissions` | Master | Crea permiso. |
| PUT | `/permissions/:id` | Master | Actualiza permiso. |
| DELETE | `/permissions/:id` | Master | Elimina permiso. |
| GET | `/role-permissions/:role` | Master | Lista permisos asignados a un rol base. |
| POST | `/role-permissions/assign` | Master | Asigna permiso a rol. |
| DELETE | `/role-permissions/:role/:permission_id` | Master | Remueve permiso de rol. |
| GET | `/labels` | Master | Lista labels/subroles. |
| GET | `/labels/:id` | Master | Obtiene label. |
| POST | `/labels` | Master | Crea label. |
| PUT | `/labels/:id` | Master | Actualiza label. |
| DELETE | `/labels/:id` | Master | Elimina label. |
| GET | `/label-permissions/:label_id` | Master | Lista permisos de un label. |
| POST | `/label-permissions` | Master | Asigna permiso a label. |
| DELETE | `/label-permissions/:label_id/:permission_id` | Master | Quita permiso específico de un label. |
| DELETE | `/label-permissions/:label_id` | Master | Quita todos los permisos de un label. |
| GET | `/user-labels/me` | Auth | Lista labels del usuario autenticado. |
| GET | `/user-labels/:user_id` | Master | Lista labels de un usuario. |
| POST | `/user-labels/assign` | Master | Asigna label a usuario. |
| DELETE | `/user-labels/remove` | Master | Remueve label de usuario. |

Nota: las rutas heredadas que declaran roles pasan por el adaptador RBAC y se traducen a permisos efectivos.

## Inicio Por Rol

| Método | Ruta | Acceso | Uso |
|---|---|---:|---|
| GET | `/home-dashboard` | Partner/Admin | Devuelve en una sola consulta el resumen del inicio. Para socios incluye ventas, publicaciones, tareas y operación de almacenes propios; para admin/máster incluye negocios, eventos, almacenes y reclamos pendientes de aprobación. |

El endpoint devuelve únicamente contadores relacionados con el usuario autenticado, salvo en el modo administrativo, donde los roles `admin` y `master` reciben los pendientes globales necesarios para moderación.

## Economía, Pagos Y Wallet

| Método | Ruta | Acceso | Uso |
|---|---|---:|---|
| GET | `/wallets/me` | Auth | Obtiene wallet del usuario autenticado. |
| POST | `/payments` | Auth | Crea pago pendiente para compra, suscripción o upgrade. |
| GET | `/payments/me` | Auth | Lista pagos del usuario autenticado. |
| GET | `/payments/:id` | Auth | Obtiene pago por id si pertenece al usuario o si RLS/service lo permite. |
| PATCH | `/payments/:id` | Auth | Soft delete/cancelación lógica de pago. |
| POST | `/stripe/payment-intents` | Auth | Crea un PaymentIntent de Stripe para `partner_upgrade`, `coin_purchase` o `subscription`; la API calcula el monto desde paquetes/planes. |
| POST | `/stripe/payment-intents/:paymentIntentId/cancel` | Auth | Cancela un PaymentIntent gateway pendiente del usuario autenticado. |
| POST | `/stripe/webhook` | Stripe | Recibe eventos firmados de Stripe y aprueba/rechaza automáticamente el pago gateway con control idempotente por evento. |
| POST | `/payment-requests` | User/Partner | Crea solicitud revisable asociada a payment. |
| GET | `/payment-requests/me` | User/Partner | Lista solicitudes propias. |
| GET | `/payment-requests/mine/partner-upgrade/pending` | Auth | Indica si el usuario tiene upgrade a partner pendiente. |
| GET | `/payment-requests` | Admin | Lista solicitudes para revisión. Acepta filtros `status` y `method` (`qr`, `gateway`, `cash_point`) para separar manuales de Stripe. |
| GET | `/payment-requests/:id` | Admin | Obtiene solicitud por id. |
| PATCH | `/payment-requests/:id/approve` | Admin | Aprueba solicitud y ejecuta RPC económico. |
| PATCH | `/payment-requests/:id/reject` | Admin | Rechaza solicitud y pago relacionado. |
| GET | `/financial-transactions/me` | Auth | Lista transacciones económicas propias. |
| GET | `/financial-transactions/me/latest` | Auth | Devuelve últimas transacciones propias. |
| GET | `/financial-transactions/:id` | Auth | Obtiene transacción por id. |
| GET | `/finance/me/activity` | Auth | Devuelve actividad financiera agregada del usuario. |
| GET | `/coin-packages` | Público | Lista paquetes de compra visibles. |
| GET | `/coin-packages/basic` | Público | Obtiene paquete/config usado para pago inicial de partner upgrade. |
| GET | `/coin-packages/:id/active` | Público | Obtiene paquete activo por id. |
| GET | `/coin-packages/admin` | Admin | Lista paquetes incluyendo inactivos/archivados. |
| GET | `/coin-packages/filters` | Admin | Busca paquetes por filtros administrativos. |
| GET | `/coin-packages/:id` | Público | Obtiene paquete por id. |
| POST | `/coin-packages` | Admin | Crea paquete de Tinkus. |
| PATCH | `/coin-packages/:id` | Admin | Actualiza paquete. |
| PATCH | `/coin-packages/:id/softDelete` | Admin | Archiva paquete. |
| PATCH | `/coin-packages/:id/activate` | Admin | Activa paquete. |
| PATCH | `/coin-packages/:id/deactivate` | Admin | Desactiva paquete. |
| GET | `/cashout-packages` | Público | Lista paquetes de retiro visibles. |
| GET | `/cashout-packages/:id/active` | Público | Obtiene paquete de retiro activo. |
| GET | `/cashout-packages/admin` | Admin | Lista paquetes de retiro para administración. |
| GET | `/cashout-packages/:id` | Público | Obtiene paquete de retiro por id. |
| POST | `/cashout-packages` | Admin | Crea paquete de retiro. |
| PATCH | `/cashout-packages/:id` | Admin | Actualiza paquete de retiro. |
| PATCH | `/cashout-packages/:id/softDelete` | Admin | Archiva paquete. |
| PATCH | `/cashout-packages/:id/deactivate` | Admin | Desactiva paquete. |
| PATCH | `/cashout-packages/:id/activate` | Admin | Activa paquete. |
| POST | `/cashout-requests` | Auth | Crea solicitud de retiro usando un paquete activo; valida saldo y pendiente único por usuario. |
| GET | `/cashout-requests/me` | Auth | Lista solicitudes de retiro del usuario autenticado. |
| GET | `/cashout-requests/pending` | Admin | Lista solicitudes pendientes para revisión. |
| GET | `/cashout-requests` | Admin | Lista solicitudes de retiro con paginación. |
| GET | `/cashout-requests/:id` | Admin | Obtiene solicitud de retiro por id. |
| PATCH | `/cashout-requests/:id/approve` | Admin | Aprueba solicitud, descuenta wallet con transacción `cashout` y audita. |
| PATCH | `/cashout-requests/:id/reject` | Admin | Rechaza solicitud pendiente y audita. |
| GET | `/system-config/public/:key` | Auth | Lee valor numérico público permitido por service/RLS. |
| GET | `/system-config/:key` | Admin | Lee configuración por key. |
| GET | `/system-config` | Admin | Lista configuraciones. |
| PUT | `/system-config/:key` | Admin | Actualiza configuración. |

Flujo típico de compra/suscripción: `/payments` -> `/storage/upload` opcional -> `/payment-requests` -> admin aprueba/rechaza.

## Negocios Y Claims

| Método | Ruta | Acceso | Uso |
|---|---|---:|---|
| GET | `/businesses` | Público / Admin | Público: sólo `active + validated`; admin/máster autenticado: todos los estados. |
| GET | `/businesses/batch` | Público / Admin | Obtiene negocios por ids aplicando la misma visibilidad por rol. |
| GET | `/businesses/category/:categoryId` | Público / Admin | Lista por categoría aplicando la misma visibilidad por rol. |
| GET | `/businesses/mine` | Auth | Lista negocios del usuario autenticado. |
| GET | `/businesses/status` | Admin | Lista/filtra negocios por estado. |
| GET | `/businesses/:id` | Público / Admin | Público: sólo aprobado; admin/máster puede consultar cualquier estado. |
| POST | `/businesses/system` | Admin | Crea negocio desde administración/sistema. |
| POST | `/businesses` | Partner/Admin | Crea negocio propio; puede usar cargo en Tinkus. |
| PUT | `/businesses/:id` | Admin | Actualiza negocio directamente. |
| PATCH | `/businesses/:id/validate` | Admin | Valida/aprueba negocio. |
| PATCH | `/businesses/:id/reject` | Admin | Rechaza negocio. |
| DELETE | `/businesses/:id` | Partner/Admin | Soft delete/suspensión lógica de negocio. |
| POST | `/business-claim-requests` | Partner | Solicita propiedad de negocio. |
| GET | `/business-claim-requests/me` | Partner | Lista claims propios. |
| GET | `/business-claim-requests/pending` | Admin | Lista claims pendientes. |
| PATCH | `/business-claim-requests/:id/review` | Admin | Aprueba/rechaza claim; al aprobar asigna owner, activa/valida el negocio y rechaza otros claims pendientes del mismo negocio. |
| GET | `/business-claim-requests` | Admin | Lista todos los claims. |
| GET | `/business-claim-requests/business/:businessId` | Partner/Admin | Admin ve todos; partner sólo ve sus propios claims de ese negocio. |
| GET | `/business-claim-requests/:id` | Partner/Admin | Admin ve cualquiera; partner sólo puede consultar su propio claim y documentos. |
| GET | `/warehouses` | Público | Lista almacenes activos y validados. |
| GET | `/warehouses/:id` | Público | Obtiene almacén por id. |
| GET | `/warehouses/business/:businessId/fulfillment` | Público | Consulta retiro en tienda y almacenes habilitados de un negocio. |
| GET | `/warehouses/mine/list` | Partner/Admin | Lista almacenes del usuario autenticado. |
| GET | `/warehouses/admin/all` | Admin | Lista almacenes con filtro opcional `status`. |
| POST | `/warehouses` | Partner/Admin | Crea almacén propio pendiente y cobra `business_create_cost` a cualquier rol, incluidos admin/master. |
| PUT | `/warehouses/:id` | Partner/Admin | Actualiza almacén propio o administrado. |
| PATCH | `/warehouses/:id/status` | Admin | Cambia estado/validación de almacén. |
| POST | `/warehouses/stock-requests` | Partner/Admin | Crea solicitud para enviar un producto de un negocio propio a un almacén activo. |
| GET | `/warehouses/stock-requests/received` | Partner/Admin | Lista solicitudes recibidas por los almacenes propios. Filtro opcional `status`. |
| GET | `/warehouses/stock-requests/sent` | Partner/Admin | Lista solicitudes enviadas por los negocios propios. Filtro opcional `status`. |
| PATCH | `/warehouses/stock-requests/:requestId/approve` | Partner/Admin | El dueño del almacén aprueba la solicitud; puede enviar `location_id`, se habilita la relación negocio-almacén, se suma inventario y se escribe historial. |
| PATCH | `/warehouses/stock-requests/:requestId/reject` | Partner/Admin | El dueño del almacén rechaza la solicitud con motivo obligatorio. |
| GET | `/warehouses/:id/locations` | Partner/Admin | Lista ubicaciones internas del almacén propio o administrado. |
| POST | `/warehouses/:id/locations` | Partner/Admin | Crea una ubicación interna del almacén. |
| PATCH | `/warehouses/:id/locations/:locationId` | Partner/Admin | Actualiza ubicación interna del almacén. |
| DELETE | `/warehouses/:id/locations/:locationId` | Partner/Admin | Desactiva ubicación interna del almacén. |
| GET | `/warehouses/:id/inventory` | Partner/Admin | Lista inventario de un almacén propio o administrado. |
| PUT | `/warehouses/:id/inventory` | Partner/Admin | Crea/actualiza inventario de producto en almacén y escribe historial. |
| PATCH | `/warehouses/:id/inventory/:inventoryId/location` | Partner/Admin | Asigna o limpia ubicación interna de un item de inventario. |
| GET | `/warehouses/:id/product-history` | Partner/Admin | Lista historial de productos del almacén. |
| PUT | `/warehouses/business/:businessId/fulfillment` | Partner/Admin | Configura retiro en tienda, entrega por almacén y almacenes seleccionados del negocio. |
| POST | `/entity-updates` | Partner | Propone update de entidad propia. |
| GET | `/entity-updates/me` | Partner | Lista updates propios. |
| GET | `/entity-updates/entity` | Partner/Admin | Admin busca cualquiera; partner sólo consulta updates de entidades propias. |
| GET | `/entity-updates` | Admin | Lista updates pendientes/históricos. |
| GET | `/entity-updates/:id` | Admin | Obtiene update por id. |
| PATCH | `/entity-updates/:id/approve` | Admin | Aprueba update y aplica RPC según entidad. |
| PATCH | `/entity-updates/:id/reject` | Admin | Rechaza update. |

Flujos: creación con cargo, validación administrativa, claim de propiedad y edición mediante solicitud.

## Categorías Y Catálogos

| Método | Ruta | Acceso | Uso |
|---|---|---:|---|
| GET | `/categories` | Público | Lista categorías. |
| GET | `/categories/active/:id` | Público | Obtiene categoría activa por id. |
| GET | `/categories/active` | Público | Lista categorías activas por tipo/filtro. |
| GET | `/categories/filters` | Admin | Busca categorías con filtros administrativos. |
| GET | `/categories/admin` | Admin | Lista categorías incluyendo inactivas. |
| GET | `/categories/batch` | Público | Obtiene categorías por lista de ids. |
| GET | `/categories/:id` | Público | Obtiene categoría por id. |
| POST | `/categories` | Admin | Crea categoría. |
| PATCH | `/categories/:id` | Admin | Actualiza categoría. |
| PATCH | `/categories/:id/softDelete` | Admin | Archiva categoría. |
| PATCH | `/categories/:id/deactivate` | Admin | Desactiva categoría. |
| PATCH | `/categories/:id/activate` | Admin | Activa categoría. |
| GET | `/vehicle-types` | Público | Lista tipos de vehículo. |
| GET | `/vehicle-types/:id` | Público | Obtiene tipo de vehículo. |
| POST | `/vehicle-types` | Admin | Crea tipo de vehículo. |
| PUT | `/vehicle-types/:id` | Admin | Actualiza tipo de vehículo. |
| DELETE | `/vehicle-types/:id` | Admin | Elimina tipo de vehículo. |
| GET | `/tags` | Público | Lista tags turísticos. |
| GET | `/tags/:id` | Público | Obtiene tag. |
| POST | `/tags` | Admin | Crea tag. |
| PUT | `/tags/:id` | Admin | Actualiza tag. |
| PUT | `/tags/:id/soft-delete` | Admin | Archiva tag. |

## Contenido Comercial

| Método | Ruta | Acceso | Uso |
|---|---|---:|---|
| GET | `/products` | Público / Admin | Público: productos activos de negocios aprobados; admin/máster: todos. |
| GET | `/products/business/:businessId` | Público / Admin | Lista por negocio aplicando visibilidad por rol. |
| GET | `/products/businesses` | Público / Admin | Lista batch aplicando visibilidad por rol. |
| GET | `/products/my` | Partner/Admin | Lista productos administrables del usuario. |
| GET | `/products/:id` | Público / Admin | Público: producto activo de negocio aprobado; admin/máster: cualquier estado. |
| POST | `/products` | Partner/Admin | Crea producto en negocio propio o administrado. |
| PUT | `/products/:id` | Partner/Admin | Actualiza producto. |
| DELETE | `/products/:id` | Partner/Admin | Soft delete de producto. |
| GET | `/products/admin/all` | Admin | Lista productos para administración. |
| GET | `/products/admin/business/:businessId` | Admin | Lista productos de un negocio para admin. |
| GET | `/marketplace/publications` | Público | Lista publicaciones activas de marketplace con paginación (`limit`, `offset`) y búsqueda `q`. |
| GET | `/marketplace/publications/:id` | Público | Obtiene detalle público de una publicación activa. |
| POST | `/marketplace/businesses/:businessId/views` | Público | Registra una vista agregada del negocio. |
| GET | `/marketplace/publications/mine/list` | Partner/Admin | Lista publicaciones del usuario autenticado. |
| POST | `/marketplace/publications/estimate` | Partner/Admin | Estima el costo en Tinkus de publicar o ampliar stock. |
| POST | `/marketplace/publications` | Partner/Admin | Publica producto para compra exclusiva con Tinkus y cobra el costo de publicación. |
| PATCH | `/marketplace/publications/:id/stock` | Partner/Admin | Actualiza stock/precio en Tinkus y cobra sólo el adicional si sube el costo. |
| PATCH | `/marketplace/publications/:id/status` | Partner/Admin | Pausa, reactiva o archiva publicación propia o administrada. |
| GET | `/marketplace/publications/:id/history` | Partner/Admin | Lista historial de cambios de una publicación. |
| POST | `/marketplace/orders` | Auth | Crea y cobra pedido con Tinkus. Requiere `client_request_id` UUID estable durante los reintentos del mismo pedido. |
| GET | `/marketplace/orders/mine/list` | Auth | Lista pedidos del usuario autenticado. |
| GET | `/marketplace/orders/sales/list` | Partner/Admin | Lista ventas pertenecientes a negocios propios. |
| GET | `/marketplace/orders/warehouse/list` | Partner/Admin | Lista pedidos de los almacenes propios, sin exponer el codigo de retiro del comprador. |
| PATCH | `/marketplace/orders/warehouse/:id/ready` | Partner/Admin | El propietario del almacen marca un pedido recibido como listo para retirar. |
| PATCH | `/marketplace/orders/sales/:id/status` | Partner/Admin | Avanza una venta propia a preparación o lista para retiro. |
| POST | `/marketplace/orders/sales/:id/reject` | Partner/Admin | Rechaza una venta con motivo obligatorio, devuelve Tinkus y restituye stock. |
| GET | `/marketplace/orders/:id` | Auth | Obtiene pedido propio; admin/master pueden ver cualquiera. |
| GET | `/marketplace/businesses/:businessId/view-stats` | Partner/Admin | Muestra métricas agregadas de vistas del negocio propio o administrado. |
| GET | `/marketplace/admin/publications` | Admin | Lista publicaciones con filtros administrativos. |
| GET | `/marketplace/admin/orders` | Admin | Lista pedidos con filtro opcional por estado. |
| PATCH | `/marketplace/admin/orders/:id/status` | Admin | Avanza estados operativos; no permite finalizar, cancelar ni retroceder un pedido. |
| PATCH | `/marketplace/admin/deliveries/:id/status` | Admin | Avanza la asignacion y transporte; completar entrega requiere validar el codigo de retiro. |
| GET | `/events` | Público / Admin | Público: sólo eventos activos; admin/máster autenticado: todos los estados. |
| GET | `/events/category/:categoryId` | Público / Admin | Lista por categoría aplicando visibilidad por rol. |
| GET | `/events/business/:businessId` | Público / Admin | Lista por negocio aplicando visibilidad por rol. |
| GET | `/events/:id/availability` | Público / Admin | Público: sólo eventos activos; admin/máster puede consultar cualquier estado. |
| GET | `/events/batch` | Público / Admin | Obtiene eventos por ids aplicando visibilidad por rol. |
| GET | `/events/me` | Auth | Lista eventos creados/relacionados al usuario. |
| GET | `/events/admin` | Admin | Lista eventos por estado para revisión. |
| GET | `/events/:id` | Público / Admin | Público: sólo activo; admin/máster puede consultar cualquier estado. |
| POST | `/events` | Partner/Admin | Crea evento; puede cobrar Tinkus por creación. |
| DELETE | `/events/:id` | Partner/Admin | Soft delete/cancelación lógica de evento. |
| PATCH | `/events/:id/approve` | Admin | Aprueba evento pendiente. |
| PATCH | `/events/:id/reject` | Admin | Rechaza evento pendiente. |
| GET | `/discounts` | Público | Lista descuentos visibles. |
| GET | `/discounts/businesses` | Público | Lista descuentos agrupados por varios negocios (`business_ids`, `active=true` opcional). |
| GET | `/discounts/business/:businessId` | Público | Lista descuentos de un negocio. |
| GET | `/discounts/business/:businessId/active` | Público | Lista descuentos activos de un negocio. |
| GET | `/discounts/my` | Partner/Admin | Lista descuentos propios. |
| GET | `/discounts/:id` | Público | Obtiene descuento. |
| POST | `/discounts` | Partner/Admin | Crea descuento; cobra por días según config. |
| PUT | `/discounts/:id` | Partner/Admin | Actualiza descuento. |
| DELETE | `/discounts/:id` | Partner/Admin | Soft delete de descuento. |
| GET | `/boosts/active` | Público | Lista boosts activos. |
| GET | `/boosts/entity/:entityType/:entityId` | Público | Lista boosts de una entidad. |
| GET | `/boosts` | Público | Lista boosts visibles. |
| GET | `/boosts/mine` | Partner/Admin | Lista boosts propios. |
| GET | `/boosts/promotable-businesses` | Partner/Admin | Lista negocios propios aprobados y activos que pueden impulsarse. |
| GET | `/boosts/:id` | Público | Obtiene boost. |
| POST | `/boosts` | Partner/Admin | Crea boost; cobra por días según config. |
| PUT | `/boosts/:id` | Partner/Admin | Actualiza boost. |
| PATCH | `/boosts/:id/softDelete` | Partner/Admin | Archiva boost. |

## Interacción De Usuarios

| Método | Ruta | Acceso | Uso |
|---|---|---:|---|
| GET | `/reviews/entity/:entityType/:entityId` | Público | Lista reseñas públicas de una entidad. |
| GET | `/reviews/entities` | Público | Lista reseñas para varias entidades. |
| GET | `/reviews/my` | Auth | Lista reseñas del usuario autenticado. |
| POST | `/reviews` | Auth | Crea reseña. |
| PUT | `/reviews/:id` | Auth | Actualiza reseña propia. |
| DELETE | `/reviews/:id` | Auth | Oculta/elimina reseña propia. |
| GET | `/reviews` | Admin | Lista reseñas para moderación. |
| GET | `/reviews/:id` | Admin | Obtiene reseña para moderación. |
| POST | `/user-visits` | Auth | Registra visita o favorito. |
| GET | `/user-visits/my` | Auth | Lista visitas/favoritos propios. |
| GET | `/user-visits/entity/:entityType/:entityId` | Auth | Consulta interacción del usuario con entidad. |
| DELETE | `/user-visits/:entityType/:entityId` | Auth | Elimina visita/favorito de entidad. |
| POST | `/reservations` | Auth | Crea reserva; puede transferir Tinkus si el evento tiene precio. |
| GET | `/reservations/me` | Auth | Lista reservas propias. |
| GET | `/reservations/event/:eventId/me` | Auth | Obtiene reserva propia para un evento. |
| GET | `/reservations/event/:eventId` | Auth | Lista reservas de un evento según permisos/service. |
| GET | `/reservations/:id` | Auth | Obtiene reserva por id. |
| PUT | `/reservations/:id` | Auth | Permite cancelar una reserva elegible; no cambia titular, evento, cantidad ni monto. |
| DELETE | `/reservations/:id` | Auth | Cancela y reembolsa atomicamente una reserva elegible, sin eliminar su historial. |
| GET | `/reservations` | Admin | Lista todas las reservas. |
| GET | `/event-tickets/me` | Auth | Lista tickets del usuario autenticado con sus días escaneables. |
| GET | `/event-tickets/reservation/:reservationId` | Auth | Lista tickets generados para una reserva. |
| GET | `/event-tickets/event/:eventId` | Organizador/Admin | Lista tickets de un evento para control de asistencia. |
| POST | `/event-tickets/days/:ticketDayId/qr` | Auth | Emite/rota el QR de un ticket-día del usuario. |
| POST | `/event-tickets/check-in` | Organizador/Admin | Escanea token QR y confirma asistencia. |
| GET | `/event-tickets/:id` | Auth | Obtiene ticket por id con sus días. |
| POST | `/notifications` | Auth | Crea notificación. |
| GET | `/notifications/me` | Auth | Lista notificaciones propias. |
| GET | `/notifications/unread-count` | Auth | Cuenta no leídas. |
| PATCH | `/notifications/read-all` | Auth | Marca todas como leídas. |
| POST | `/notifications/broadcast/admins` | Admin | Envía notificación broadcast a admins. |
| GET | `/notifications/:id` | Auth | Obtiene notificación. |
| PATCH | `/notifications/:id/read` | Auth | Marca notificación como leída. |
| PUT | `/notifications/:id` | Auth | Actualiza notificación. |
| DELETE | `/notifications/:id` | Auth | Elimina notificación. |

## Transporte Y Nearby

| Método | Ruta | Acceso | Uso |
|---|---|---:|---|
| GET | `/nearby` | Público | Busca negocios/eventos/lugares cercanos por lat/lng/radio. |
| GET | `/transport-lines` | Público | Lista líneas de transporte. |
| GET | `/transport-lines/batch` | Público | Obtiene líneas por ids. |
| GET | `/transport-lines/vehicle/:vehicleTypeId` | Público | Lista líneas por tipo de vehículo. |
| GET | `/transport-lines/:id` | Público | Obtiene línea. |
| POST | `/transport-lines` | Admin | Crea línea. |
| PUT | `/transport-lines/:id` | Admin | Actualiza línea. |
| PATCH | `/transport-lines/:id/archive` | Admin | Archiva línea. |
| GET | `/transport-routes/line/:lineId` | Público | Lista puntos de ruta de una línea. |
| GET | `/transport-routes/lines` | Público | Lista puntos de ruta agrupados por varias líneas (`line_ids`, `direction` opcional). |
| GET | `/transport-routes/line/:lineId/:direction` | Público | Lista puntos por línea y dirección. |
| POST | `/transport-routes` | Admin | Crea punto de ruta. |
| POST | `/transport-routes/bulk` | Admin | Inserción masiva de puntos de ruta. |
| DELETE | `/transport-routes/:id` | Admin | Elimina punto de ruta. |
| GET | `/entity-transport-relations/:entityType/:entityId` | Público | Lista líneas asociadas a entidad. |
| GET | `/entity-transport-relations/entities` | Público | Lista líneas asociadas agrupadas por varias entidades (`entity_type`, `entity_ids`). |
| PUT | `/entity-transport-relations/:entityType/:entityId` | Partner/Admin | Reemplaza líneas asociadas a entidad. |
| POST | `/entity-transport-relations` | Partner/Admin | Crea relación entidad-línea. |
| DELETE | `/entity-transport-relations/:entityType/:entityId/:lineId` | Partner/Admin | Elimina relación puntual. |
| DELETE | `/entity-transport-relations/:entityType/:entityId` | Partner/Admin | Elimina todas las relaciones de una entidad. |

## Turismo

| Método | Ruta | Acceso | Uso |
|---|---|---:|---|
| GET | `/tourist-places` | Público | Lista lugares turísticos. |
| GET | `/tourist-places/batch` | Público | Obtiene lugares turísticos por lista de ids. |
| GET | `/tourist-places/category/:categoryId` | Público | Lista lugares por categoría. |
| GET | `/tourist-places/:id` | Público | Obtiene lugar turístico. |
| POST | `/tourist-places` | Admin | Crea lugar turístico. |
| PUT | `/tourist-places/:id` | Admin | Actualiza lugar turístico. |
| PATCH | `/tourist-places/:id/archive` | Admin | Archiva lugar turístico. |
| GET | `/tourist-place-tags/place/:placeId` | Público | Lista tags de un lugar. |
| GET | `/tourist-place-tags/tag/:tagId` | Público | Lista lugares asociados a tag. |
| POST | `/tourist-place-tags` | Admin | Asocia tag a lugar. |
| PUT | `/tourist-place-tags/place/:placeId` | Admin | Reemplaza tags de un lugar. |
| DELETE | `/tourist-place-tags/:placeId/:tagId` | Admin | Elimina asociación tag-lugar. |

## Monetización Y Suscripciones

| Método | Ruta | Acceso | Uso |
|---|---|---:|---|
| GET | `/subscription-plans` | Público | Lista planes visibles. |
| GET | `/subscription-plans/:id` | Público | Obtiene plan. |
| POST | `/subscription-plans` | Admin | Crea plan. |
| PATCH | `/subscription-plans/:id` | Admin | Actualiza plan. |
| PATCH | `/subscription-plans/:id/archive` | Admin | Archiva plan. |
| GET | `/user-subscriptions/user/:userId` | Auth | Lista suscripciones de usuario. Revisar service/RLS para alcance. |
| GET | `/user-subscriptions` | Auth | Lista suscripciones. Recomendado admin. |
| GET | `/user-subscriptions/me/current` | Auth | Obtiene suscripción activa del usuario autenticado. |
| GET | `/user-subscriptions/:id` | Auth | Obtiene suscripción por id. |
| POST | `/user-subscriptions` | Admin | Crea suscripción manualmente. |
| PATCH | `/user-subscriptions/:id` | Admin | Actualiza suscripción. |
| PATCH | `/user-subscriptions/:id/cancel` | Admin | Cancela suscripción. |
| DELETE | `/user-subscriptions/:id` | Admin | Elimina suscripción. |

Flujo recomendado de usuario: comprar plan mediante `payments` + `payment-requests`; no crear `user-subscriptions` directo desde cliente.

## Soporte, Metadata, Media Y Storage

| Método | Ruta | Acceso | Uso |
|---|---|---:|---|
| GET | `/social-links/business/:businessId` | Público | Lista redes sociales de un negocio. |
| GET | `/social-links/businesses` | Público | Lista redes sociales agrupadas por varios negocios (`business_ids`). |
| POST | `/social-links` | Partner/Admin | Crea red social para negocio. |
| PATCH | `/social-links/:id` | Partner/Admin | Actualiza red social. |
| DELETE | `/social-links/:id` | Partner/Admin | Elimina red social. |
| GET | `/opening-hours/:entityType/:entityId` | Público | Lista horarios de una entidad. |
| GET | `/opening-hours/entities` | Público | Lista horarios agrupados por varias entidades (`entity_type`, `entity_ids`). |
| GET | `/opening-hours/id/:id` | Público | Obtiene horario por id. |
| POST | `/opening-hours` | Auth | Crea horario. |
| PATCH | `/opening-hours/:id` | Auth | Actualiza horario. |
| DELETE | `/opening-hours/:id` | Auth | Elimina horario. |
| DELETE | `/opening-hours/:entityType/:entityId` | Auth | Elimina horarios de una entidad. |
| PUT | `/opening-hours/:entityType/:entityId` | Auth | Reemplaza todos los horarios de una entidad. |
| GET | `/charging-points` | Público | Lista puntos físicos. |
| GET | `/charging-points/active` | Público | Lista puntos activos. |
| GET | `/charging-points/:id` | Público | Obtiene punto físico. |
| POST | `/charging-points` | Admin | Crea punto físico. |
| PATCH | `/charging-points/:id` | Admin | Actualiza punto físico. |
| PATCH | `/charging-points/:id/softDelete` | Admin | Archiva punto físico. |
| GET | `/certifications` | Público / Admin | Público: activas de negocios aprobados; admin/máster: todos los estados. |
| GET | `/certifications/businesses` | Público / Admin | Lista batch aplicando visibilidad por rol (`business_ids`). |
| GET | `/certifications/:id` | Público / Admin | Público: activa y perteneciente a negocio aprobado; admin/máster: cualquiera. |
| GET | `/certifications/business/:businessId` | Público / Admin | Lista por negocio aplicando visibilidad por rol. |
| POST | `/certifications` | Partner/Admin | Crea certificación. |
| PATCH | `/certifications/:id` | Partner/Admin | Actualiza certificación. |
| PATCH | `/certifications/:id/softDelete` | Admin | Archiva certificación. |
| PATCH | `/certifications/:id/activate` | Admin | Activa certificación. |
| PATCH | `/certifications/:id/deactivate` | Admin | Desactiva certificación. |
| GET | `/certifications/filters` | Admin | Busca certificaciones por filtros. |
| GET | `/media` | Admin | Lista completa de media; no se expone públicamente. |
| GET | `/media/entity` | Público / Admin | Público: sólo si la entidad es visible; admin/máster: cualquier estado. |
| GET | `/media/entity/primary` | Público / Admin | Obtiene media primaria aplicando visibilidad por rol. |
| GET | `/media/entities` | Público / Admin | Batch con visibilidad por rol. Acepta ids numéricos y UUID para `user`. |
| GET | `/media/:id` | Público / Admin | Público: sólo media de entidad visible; admin/máster: cualquiera. |
| POST | `/media` | Auth | Crea registro media. |
| PUT | `/media/:id` | Auth | Actualiza media. |
| DELETE | `/media/:id` | Auth | Elimina media por id. |
| DELETE | `/media/entity` | Auth | Elimina media de entidad. |
| DELETE | `/media/url` | Auth | Elimina media por URL. |
| POST | `/storage/upload` | Auth | Sube archivo a Firebase Storage y devuelve metadata/URL. Máximo 6 archivos por request, 60MB total; pagos y perfil aceptan un solo archivo. |
| DELETE | `/storage/delete` | Auth | Elimina archivo por ruta/URL. |
| DELETE | `/storage/entity` | Auth | Elimina archivos asociados a entidad. |

## Auditoría

| Método | Ruta | Acceso | Uso |
|---|---|---:|---|
| GET | `/audit-logs/filters` | Admin | Busca logs por filtros. |
| GET | `/audit-logs/user/:userId` | Admin | Lista logs de un usuario. |
| GET | `/audit-logs/entity/:entityType/:entityId` | Admin | Lista logs de una entidad. |
| GET | `/audit-logs` | Admin | Lista logs. |
| GET | `/audit-logs/:id` | Admin | Obtiene log por id. |

## Flujos Transversales Recomendados

### Alta De Negocio Por Partner

1. Login.
2. Verificar wallet: `GET /wallets/me`.
3. Revisar costo: `GET /system-config/public/business_create_cost`.
4. Crear negocio: `POST /businesses`.
5. Subir media: `POST /storage/upload` y `POST /media`.
6. Configurar horarios/redes/certificaciones.
7. Admin valida: `PATCH /businesses/:id/validate`.

### Compra De Tinkus

1. Listar paquetes: `GET /coin-packages`.
2. Crear pago: `POST /payments`.
3. Subir comprobante si aplica.
4. Crear request: `POST /payment-requests`.
5. Admin aprueba: `PATCH /payment-requests/:id/approve`.
6. Usuario verifica wallet/transacciones.

### Evento Con Reserva

1. Partner crea evento: `POST /events`.
2. Admin aprueba evento si corresponde.
3. Usuario consulta disponibilidad: `GET /events/:id/availability`.
4. Usuario reserva: `POST /reservations`.
5. La reserva confirmada genera tickets automáticamente.
6. Usuario consulta tickets: `GET /event-tickets/reservation/:reservationId`.
7. Usuario emite QR: `POST /event-tickets/days/:ticketDayId/qr`.
8. Organizador escanea: `POST /event-tickets/check-in`.

### Transporte Asociado A Entidad

1. Admin crea tipos, líneas y rutas.
2. Partner/admin relaciona líneas: `PUT /entity-transport-relations/:entityType/:entityId`.
3. Usuario consulta líneas asociadas desde la entidad o desde `/entity-transport-relations/:entityType/:entityId`.

### Turismo

1. Admin crea categorías/tags.
2. Admin crea lugar turístico.
3. Admin asigna tags.
4. Usuario consulta lugares por categoría, nearby o tags.

## Rutas A Revisar Con Cuidado

- `/media/delete...`: las rutas dinámicas y rutas `/entity`/`/url` deben probarse por orden de Express.
