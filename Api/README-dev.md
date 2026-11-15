# API - Guía De Desarrollo

Esta guía explica cómo levantar, entender y modificar la API de Tinku sin depender de conocimiento tribal.

## 1. Requisitos

- Node.js 20 o superior recomendado.
- npm.
- PostgreSQL local u hosteado con las extensiones usadas por los scripts de `database/`.
- Credenciales de Firebase Admin si se probará Storage.

## 2. Instalación

```bash
npm install
```

## 3. Variables De Entorno

Crear `.env` a partir de `.env.example`:

```env
DATABASE_URL=postgres://postgres:postgres@localhost:5432/tinku
JWT_ACCESS_SECRET=
JWT_REFRESH_SECRET=
JWT_ACCESS_TTL=15m
JWT_REFRESH_TTL=30d
GOOGLE_CLIENT_ID=
PORT=3000
FIREBASE_ADMIN_KEY_B64=
FIREBASE_STORAGE_BUCKET=
```

### Firebase Admin

`FIREBASE_ADMIN_KEY_B64` debe ser la clave JSON de Firebase convertida a base64.

PowerShell:

```powershell
$path = "C:\ruta\firebase-key.json"
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes($path))
```

Linux/macOS:

```bash
base64 -w 0 firebase-key.json
```

No subir `.env`, claves JSON ni valores base64 al repositorio.

## 4. Comandos

Desarrollo con recarga al cambiar archivos en `src`:

```bash
npm run dev
```

Compilar TypeScript:

```bash
npm run build
```

Ejecutar compilado:

```bash
npm start
```

Seed:

```bash
npm run seed
```

Migraciones sobre bases existentes:

```bash
npm run db:migrate
```

## 5. Base De Datos

Scripts actuales:

- `database/01-db.sql`: extensiones, enums, tablas e índices.
- `database/02-functions.sql`: RPC y funciones de negocio.
- `database/03-triggers.sql`: triggers.
- `database/04-init.sql`: inicializacion de seguridad para API propia.
- `database/05-jobs.sql`: jobs `pg_cron`.
- `database/migrations/`: cambios incrementales para bases locales u hosteadas que ya existen.
- `database/db.sql`: snapshot/archivo de referencia; no asumir que reemplaza a la serie numerada sin compararlo.

Orden sugerido para reconstrucción:

```text
01-db.sql
02-functions.sql
03-triggers.sql
04-init.sql
05-jobs.sql
```

Advertencia: `01-db.sql` borra el schema `public`.

Para bases existentes, no ejecutar la serie numerada completa salvo que se quiera reconstruir todo. Usar la migración puntual correspondiente, por ejemplo:

```bash
npm run db:migrate
```

Las migraciones deben nombrarse con formato `0001_nombre_descriptivo.sql`, `0002_otro_cambio.sql`, etc. El runner crea `schema_migrations` y registra checksum para evitar repetir o editar migraciones ya aplicadas.

## 6. Estructura Del Código

```text
src/
  config/        clientes externos: PostgreSQL, Firebase, media
  constants/     enums compartidos en backend
  controllers/   capa HTTP
  dao/           acceso a tablas/RPC mediante cliente PostgreSQL compatible
  dto/           tipos de entidades
  helper/        utilidades de dominio
  middlewares/   auth y roles
  routes/        endpoints Express
  services/      reglas de negocio
  types/         tipos globales Express/media/location
  utils/         helpers generales
  validation/    schemas Zod
```

Flujo estándar:

```text
Route -> Middleware -> Controller -> Service -> DAO -> PostgreSQL
```

## 7. Autenticación Y Roles

`authMiddleware`:

- lee `Authorization: Bearer <token>`;
- valida JWT propio emitido por `/auth/login`, `/auth/register` o `/auth/google`;
- busca el `role` del usuario en `users`;
- setea `req.user = { id, role }`.

`roleMiddleware([...])`:

- exige que `req.user.role` esté dentro de los roles permitidos.

Importante: aunque existen tablas de permisos y labels, el middleware HTTP actual no calcula permisos efectivos. Si se requiere autorización granular, hay que implementarla de forma explícita o actualizar las expectativas del producto.

## 8. Cómo Agregar Una Entidad

Seguir el patrón existente:

```text
src/dto/<entity>.dto.ts
src/validation/<entity>.validation.ts
src/dao/<entity>.dao.ts
src/services/<entity>.service.ts
src/controllers/<entity>.controller.ts
src/routes/<entity>.routes.ts
```

Después registrar la ruta en `src/index.ts`.

Checklist:

- Validar input con Zod en controller o service.
- Mantener lógica de negocio en service.
- Mantener queries/RPC en DAO.
- Revisar permisos en middleware/service/RPC si la tabla maneja datos protegidos.
- Actualizar `docs/04-database.md` y `docs/05-enums.md` si cambia DB.
- Crear una migración en `database/migrations/` cuando el cambio de DB deba aplicarse sobre bases existentes.
- Actualizar `docs/api` o Postman si cambia la API pública.

## 9. Flujos Que Requieren Cuidado

- Wallets no deben editarse directamente desde controllers.
- Gastos de Tinkus deben pasar por RPC como `perform_tinku_spend`.
- Creación con cargo usa RPC:
  - `create_business_with_charge`
  - `create_event_with_charge`
  - `create_discount_with_charge`
  - `create_boost_with_charge`
  - `create_product_publication_with_charge`
- Pagos y suscripciones pasan por `payment_requests`.
- Reservas con pago usan `create_reservation_with_payment`.
- Updates de negocio/evento pasan por `entity_updates` y aprobación admin.

## 10. Deploy Con PM2

```bash
npm run build
pm2 start dist/index.js --name tinku-api
```

Reinicio:

```bash
pm2 restart tinku-api
```

## 11. Problemas Conocidos Para Revisar

- Wallet queda como lectura/creación idempotente; los cambios de saldo deben seguir pasando por RPC económicas como `apply_transaction`, `perform_tinku_spend`, `transfer_tinku` o flujos específicos.
- Cashout ya tiene solicitud, aprobación/rechazo y auditoría; queda pendiente integrar proveedor externo real y definir reverso operativo si el pago externo falla después del descuento.
- No se agrega validación automática de SQL ni scripts de test fuera de seeds por decisión del proyecto; el SQL de `database/01-db.sql`, `02-functions.sql`, `04-init.sql` y `05-jobs.sql` sigue siendo la fuente para migraciones.
- Las rutas críticas revisadas quedaron restringidas por rol donde corresponde, pero cualquier ruta nueva debe revisarse contra `docs/api/routes.md` y RLS antes de exponerse.
- El manejo de errores quedó más consistente con `handleError` y `AppError`; al agregar services nuevos, usar mensajes conocidos o `AppError` para evitar respuestas 500 innecesarias.
