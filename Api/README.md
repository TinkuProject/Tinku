# Tinku API

API backend de Tinku, construida con Express, TypeScript, PostgreSQL y Firebase Admin.

Tinku integra negocios, eventos, turismo, transporte, contenido multimedia, reservas e interacciones de usuarios con una economía interna basada en la moneda virtual Tinku.

## Estado Actual

- El proyecto compila con `npm run build`.
- La API corre en TypeScript durante desarrollo con `tsx watch`.
- La base de datos vive en PostgreSQL y usa PostGIS, funciones RPC y jobs opcionales con `pg_cron`.
- El backend usa un pool `pg` con contexto de usuario por transaccion y Firebase Admin para storage.
- La autorización HTTP combina `authMiddleware`, permisos efectivos de rol/labels y `permissionMiddleware`. `roleMiddleware` permanece como adaptador de compatibilidad y resuelve políticas, no comparaciones directas de roles.

## Cambios Documentados En Esta Revisión

- Se actualizó este README raíz para que funcione como punto de entrada para nuevos developers.
- Se corrigió `database/01-db.sql`:
  - `business_claim_requests.documents` tenía un `;` dentro del `CREATE TABLE`.
  - `media_entity_type` no incluía `charging_point`, aunque el backend sí lo acepta.
- Se actualizó la guía de desarrollo en `README-dev.md`.
- Se actualizó la documentación de base de datos en `docs/04-database.md`.
- Se actualizó la lista de enums en `docs/05-enums.md` para que coincida con `database/01-db.sql` y `src/constants/enums.constants.ts`.
- Se ajustaron las guías de economía, negocios, transacciones y RLS para reflejar los RPC y flujos actuales.
- Se actualizó la guía Postman en `docs/api/README.md`.
- Se agregó soporte de base para almacenes, marketplace, publicaciones con cargo, entregas recompensadas y métricas agregadas de vistas de negocios.

## Requisitos

- Node.js 20 o superior recomendado.
- npm.
- PostgreSQL con PostGIS y, si se usarán jobs, `pg_cron`.
- Firebase Admin service account para Storage.

## Instalación

```bash
npm install
```

Crear `.env` basado en `.env.example`:

```env
DATABASE_URL=postgres://postgres:postgres@localhost:5432/tinku
JWT_ACCESS_SECRET=
JWT_REFRESH_SECRET=
JWT_ACCESS_TTL=15m
JWT_REFRESH_TTL=30d
GOOGLE_CLIENT_ID=
RESEND_API_KEY=
RESEND_FROM_EMAIL=no-reply@tu-dominio.com
RESEND_FROM_NAME=Tinku
AUTH_CODE_PEPPER=
AUTH_CODE_TTL_MINUTES=15
AUTH_CODE_RESEND_SECONDS=60
AUTH_CODE_MAX_ATTEMPTS=5
AUTH_CODE_MAX_REQUESTS_PER_HOUR=5
AUTH_CODE_MAX_REQUESTS_PER_IP_HOUR=20
PORT=3003
NODE_ENV=development
TRUST_PROXY=loopback
CORS_ALLOWED_ORIGINS=http://localhost:5173
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX=300
AUTH_RATE_LIMIT_MAX=40
FIREBASE_ADMIN_KEY_B64=
FIREBASE_STORAGE_BUCKET=
```

## Ejecución

Desarrollo:

```bash
npm run dev
```

Build:

```bash
npm run build
```

Producción local:

```bash
npm run build
npm start
```

Seed de usuarios:

```bash
npm run seed
```

Este comando crea el revisor Stripe sin password interactiva. Los fixtures locales requieren `npm run seed -- --test-users`, `NODE_ENV=development` y `SEED_TEST_PASSWORD` propia de al menos 12 caracteres. Las passwords existentes no se restablecen.

Migraciones para bases existentes:

```bash
npm run db:migrate
```

## Healthchecks

Con la API levantada:

```bash
curl http://localhost:3003/health/live
```

Respuesta esperada:

```json
{ "status": "ok" }
```

Readiness valida además la conexión con PostgreSQL:

```bash
curl http://localhost:3003/health/ready
```

Devuelve HTTP `200` con `database: "up"` o HTTP `503` si la API todavía no
puede atender tráfico dependiente de la base.

## Seguridad De Producción

- `helmet` agrega headers HTTP defensivos y Express no publica `X-Powered-By`.
- CORS usa la allowlist `CORS_ALLOWED_ORIGINS`. En producción no se habilita
  ningún origen web por defecto; clientes nativos y server-to-server, que no
  envían `Origin`, siguen admitidos.
- `express-rate-limit` aplica un límite global por IP y uno más estricto sobre
  `/auth`. Los valores se configuran con `RATE_LIMIT_WINDOW_MS`,
  `RATE_LIMIT_MAX` y `AUTH_RATE_LIMIT_MAX`.
- Los cuerpos JSON se limitan a 1 MB y el webhook raw de Stripe a 256 KB.
- Los access tokens JWT son cortos y los refresh tokens se rotan y persisten
  de forma revocable. Las cuentas locales deben verificar su correo.
- Los controllers/services validan roles, ownership y estado; la interfaz no
  constituye una barrera de autorización.
- Los errores HTTP 500 se sanitizan y se identifican con `error_id`; el detalle
  queda únicamente en logs del servidor.
- Stripe verifica la firma del webhook y Firebase Admin/Stripe usan secretos
  exclusivos del servidor.
- `/health/ready` comprueba PostgreSQL. `SIGTERM` y `SIGINT` dejan de aceptar
  conexiones y cierran ordenadamente el pool `pg`, con timeout de seguridad.
- En producción se debe usar HTTPS en el proxy inverso y configurar
  `TRUST_PROXY` sólo para proxies realmente controlados.

CORS protege navegadores, pero no sustituye autenticación ni autorización. Los
límites en memoria son adecuados para una sola instancia; si la API se escala
a varias instancias, debe configurarse un store compartido, por ejemplo Redis.

## Base De Datos

Los scripts actuales están en `database/` y deben ejecutarse en este orden si se reconstruye el esquema:

1. `database/01-db.sql`: extensiones, enums, tablas e índices.
2. `database/02-functions.sql`: helpers, RPC económicos, creación con cargo, aprobación de pagos, updates y búsqueda nearby.
3. `database/03-triggers.sql`: triggers y funciones de trigger.
4. `database/04-init.sql`: inicializacion de seguridad para API propia; no crea políticas RLS dependientes de Supabase.
5. `database/05-jobs.sql`: jobs programados con `pg_cron`.

Notas importantes:

- `database/01-db.sql` contiene `DROP SCHEMA public CASCADE`; no ejecutarlo contra una base con datos que quieras conservar.
- `database/migrations/` contiene cambios incrementales para bases locales u hosteadas que ya existen.
- Las migraciones usan formato `0001_nombre_descriptivo.sql` y se ejecutan con `npm run db:migrate`.
- Cada migración y su registro en `schema_migrations` se confirman en una única transacción. Si falla, todos sus cambios se revierten.
- El runner serializa ejecuciones concurrentes con un bloqueo de PostgreSQL. Los archivos nuevos no necesitan incluir `BEGIN` ni `COMMIT`.
- Los scripts no se ejecutan automáticamente desde npm.
- La seguridad de usuario se aplica desde middleware Express, services y RPCs con contexto `app.user_id`/`app.user_role`.

## Mapa De Módulos

- Acceso: `users`, `permissions`, `role_permissions`, `labels`, `label_permissions`, `user_labels`.
- Economía: `wallets`, `payments`, `payment_requests`, `financial_transactions`, `coin_packages`, `cashout_packages`, `system_config`, `audit_logs`.
- Negocios: `categories`, `businesses`, `business_claim_requests`, `entity_updates`.
- Contenido: `products`, `product_publications`, `events`, `discounts`, `boosts`.
- Marketplace y logística: `warehouses`, `business_fulfillment_options`, `business_warehouses`, `charging_point_warehouses`, `warehouse_inventory`, `marketplace_orders`, `deliveries`.
- Interacción: `user_visits`, `reviews`, `reservations`, `event_tickets`, `event_ticket_days`, `notifications`.
- Transporte: `vehicle_types`, `transport_lines`, `transport_routes`, `entity_transport_relations`.
- Transporte cercano: las relaciones automáticas se calculan a 1000 m por defecto (radio opcional) del recorrido registrado de una línea activa, incluyendo los tramos entre puntos. `0024_transport_near_route_segments.sql` incorporó los tramos y `0025_transport_radius_1000m.sql` amplía el radio y recalcula los registros existentes.
- Turismo: `tourist_places`, `tags`, `tourist_place_tags`.
- Monetización: `subscription_plans`, `user_subscriptions`.
- Soporte: `social_links`, `opening_hours`, `charging_points`, `certifications`, `media`, `storage`.

## Rutas Principales

La API monta rutas sin prefijo global:

- `/auth`
- `/users`, `/permissions`, `/role-permissions`, `/labels`, `/label-permissions`, `/user-labels`
- `/wallets`, `/payments`, `/payment-requests`, `/financial-transactions`, `/coin-packages`, `/cashout-packages`, `/system-config`, `/audit-logs`, `/finance`
- `/businesses`, `/business-claim-requests`, `/categories`
- `/warehouses`
- `/products`, `/marketplace`, `/events`, `/entity-updates`, `/discounts`, `/boosts`
- `GET /events/paginated?limit=20&offset=0` devuelve `items`, `total` y `has_more` para cargar eventos en páginas; `GET /events` se mantiene para consumidores existentes.
- `/reviews`, `/reservations`, `/event-tickets`, `/user-visits`, `/notifications`
- `/vehicle-types`, `/transport-lines`, `/transport-routes`, `/entity-transport-relations`
- `/tourist-places`, `/tags`, `/tourist-place-tags`
- `/subscription-plans`, `/user-subscriptions`
- `/social-links`, `/opening-hours`, `/charging-points`, `/certifications`, `/media`, `/storage`
- `/nearby`

## Flujos Clave

- Registro/login: `/auth/register` envía un código mediante Resend; después de `/auth/email/verify-code` se habilita `/auth/login`. Google marca el email como verificado.
- Correo transaccional: verificar el dominio remitente en Resend y configurar `RESEND_API_KEY`, `RESEND_FROM_EMAIL` y `RESEND_FROM_NAME`. La API key permanece únicamente en el servidor.
- Recuperación: `/auth/password/recovery-code` envía un código y `/auth/password/reset-with-code` cambia la contraseña, verifica el correo y revoca sesiones anteriores.
- Wallet del usuario: `/wallets/me`.
- Compra o suscripción: crear `payment` + `payment_request`; admin aprueba/rechaza el request.
- Crear negocio con cargo: `POST /businesses` usa el RPC `create_business_with_charge`.
- Crear evento con cargo: `POST /events` usa el RPC `create_event_with_charge`.
- Crear descuento/boost con cargo: los módulos usan RPC con cobro atómico.
- Reservar evento: `POST /reservations` usa `create_reservation_with_payment` y genera tickets QR por día.
- Cashout: usuario crea y consulta solicitudes en `/cashout-requests`; admin/master confirma primero el pago externo manual y luego aprueba o rechaza con RPC transaccional. La App incluye ambas vistas.
- Updates pendientes: partner crea `entity_updates`; admin/master aprueba o rechaza.
- Registro público: `POST /auth/register` siempre crea rol `user`; el rol no se acepta desde el cliente.
- Gestión de usuarios: admin/master puede crear cualquier rol con `POST /users`; `PUT /users/me` nunca permite cambiar `role` ni `status`.
- Propiedad: las escrituras y lecturas privadas validan ownership en controllers/services; no dependen de restricciones de la interfaz.
- Gratuidad administrativa: admin/master no paga creaciones comerciales ni publicaciones de marketplace. La creación de almacenes es la excepción y cobra `business_create_cost` a todos los roles.
- Marketplace: cada pedido pertenece a un solo negocio. Al comprar se descuentan y retienen los Tinkus; el vendedor recibe su parte sólo al confirmar la entrega. El vendedor consulta `/marketplace/orders/sales/list`, prepara o rechaza el pedido con motivo obligatorio y valida el QR o clave de retiro.
- Cancelación marketplace: mientras el pedido siga pagado, revierte de forma atómica comprador, vendedor, stock y reservas de almacén.
- Notificaciones: guardan tipo, entidad y ruta interna para navegación directa desde push; los registros anteriores conservan compatibilidad por texto.
- Vistas de negocio: `business_view_totals` y `business_view_daily` son la fuente canónica, con consulta batch para paneles de gestión.

## Cosas Que Deberían Solucionarse

1. **Ampliar la granularidad cuando aparezcan nuevos cargos operativos.** La base RBAC ya utiliza permisos efectivos; los nuevos módulos deben declarar códigos de permiso y evitar nuevas comparaciones manuales de roles.
2. **Proveedor automático de cashout.** El flujo actual es de liquidación manual: el administrador realiza el pago externo, registra su referencia y recién entonces aprueba. Si se automatiza, deberá añadirse compensación ante fallos del proveedor.
3. **Seeds y fixtures.** Los usuarios de prueba son optativos y estan bloqueados en produccion. `npm run test:database` valida fixtures aislados, cobros, devoluciones, concurrencia y permisos.

## Cambios Recientes De Seguridad Y Flujos

- Auditoría centralizada con `write_audit_log(...)` para cashout, pagos, reservas, check-in de tickets QR, creaciones con cargo y claims de negocio.
- Cashout implementado con `cashout_requests`, autorización por dueño/admin en la API y aprobación/rechazo vía RPC.
- Rutas sensibles endurecidas: usuarios, suscripciones, broadcast de notificaciones y escrituras de horarios.
- Manejo de errores más uniforme mediante `AppError` y mapeo de errores conocidos.
- El perfil autenticado nunca devuelve `password_hash` ni `google_sub`.
- Claims y ediciones pendientes sólo son visibles para su solicitante/dueño o para admin/master.
- Las cuentas locales sin correo verificado no pueden iniciar ni renovar sesión. Los códigos tienen vencimiento, cooldown, límite por correo/IP y máximo de intentos persistidos en PostgreSQL.
- El pool PostgreSQL tiene límites y timeouts configurables con `DB_POOL_MAX`, `DB_IDLE_TIMEOUT_MS`, `DB_CONNECTION_TIMEOUT_MS` y `DB_STATEMENT_TIMEOUT_MS`.
- Las migraciones `0026` a `0029` corrigen expiración horaria de eventos, notificaciones estructuradas, búsquedas con `pg_trgm`, triggers uniformes de `updated_at` y retención/incidencias de Marketplace.
- `0030` agrega idempotencia de pedidos, validacion del ciclo de reservas, correo verificado, dias cobrados de impulsos y cola push persistente. Ver [despliegue de seguridad](docs/09-security-rollout.md) para documentos antiguos, cuentas heredadas y firma Android.
- Antes de ejecutar `0026` en una base existente, un superusuario debe habilitar `pg_trgm` con `CREATE EXTENSION IF NOT EXISTS pg_trgm;`; la migración se detiene sin registrarse si falta la extensión.
- Pruebas API: `npm test`. Las pruebas económicas reales se ejecutan con `TEST_DATABASE_URL` y `npm run test:integration`; esta URL debe apuntar a una base exclusiva ya migrada. La prueba de carga usa `/auth/login`, `/businesses` y `/notifications/unread-count`.

## Documentación

- `README-dev.md`: guía de desarrollo y onboarding.
- `docs/01-architecture.md`: módulos y responsabilidades.
- `docs/02-roles-permissions.md`: roles, permisos efectivos, RBAC y reglas de ownership.
- `docs/03-economy.md`: economía Tinku y RPC económicos.
- `docs/04-database.md`: estructura actual de DB.
- `docs/05-enums.md`: enums actuales.
- `docs/06-business-flow.md`: negocio, claims y updates.
- `docs/07-transactions-flow.md`: pagos, requests, wallet y reservas.
- `docs/08-rls-policies.md`: políticas RLS actuales y puntos a revisar.
- `docs/api/README.md`: uso de Postman.
- `docs/api/routes.md`: catálogo central de endpoints, acceso y uso.
- `docs/api/flows.md`: flujos de uso de punta a punta.

## Verificación Realizada

```bash
npm run build
```

Resultado: build exitoso.
