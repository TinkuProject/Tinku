# Postman - Tinku API

Guía para probar la API local con Postman.

## 1. Preparación

1. Levantar API:

```bash
npm run dev
```

2. Importar environment:

```text
docs/api/postman/Tinku.postman_environment.json
```

3. Seleccionar el environment `Tinku Local`.

Si Postman muestra `No environment`, los tokens y variables no se guardarán.

## 2. Autenticación

Login:

```http
POST /auth/login
```

Body:

```json
{
  "email": "master@test.com",
  "password": "Pass1234"
}
```

Script obligatorio en `Scripts -> Post-response` del request de login:

```js
const res = pm.response.json();

pm.environment.set("token", res.session.access_token);
pm.environment.set("refresh_token", res.session.refresh_token);

if (res.user && res.user.id) {
  pm.environment.set("user_id", res.user.id);
}
```

En endpoints protegidos:

```text
Authorization -> Type: Bearer Token -> {{token}}
```

No pegar tokens manuales fijos en cada request; expiran y rompen las pruebas.

## 3. Flujo Básico

1. `POST /auth/login`
2. `GET /auth/me`
3. `GET /wallets/me`
4. Ejecutar endpoints según rol del usuario autenticado.

## 4. Orden Recomendado Para Datos Base

Crear primero catálogos:

1. Categories
2. Vehicle Types
3. Transport Lines
4. Transport Routes
5. Tags
6. Charging Points
7. Coin Packages
8. Subscription Plans
9. System Config

Claves importantes de `system_config`:

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

Sin estas claves, varios RPC de creación con cargo fallarán.

## 5. Flujos Para Probar

### Usuario

- registrar/login;
- ver categorías, negocios, eventos, turismo y transporte;
- crear payment;
- crear payment request;
- consultar wallet/transacciones;
- reservar evento.

### Partner

- crear negocio;
- crear evento;
- crear producto;
- crear descuento;
- crear boost;
- subir media;
- pedir updates de entidad;
- reclamar negocio.

### Admin/Master

- aprobar/rechazar payment requests;
- aprobar/rechazar negocios y eventos;
- revisar claims;
- gestionar catálogos;
- revisar audit logs;
- gestionar paquetes y config.

## 6. Errores Comunes

### 401 Unauthorized

- No hay token.
- Token expirado.
- Environment no seleccionado.
- Usuario existe en Auth pero no en tabla `users`.

### 403 Forbidden

- El rol de `users.role` no está autorizado por `roleMiddleware`.
- El rol de `users.role` no coincide con los roles requeridos por la ruta.

### 400 Bad Request

- Falló validación Zod.
- Faltan campos obligatorios.
- Enum inválido.

### Error RPC

- Falta clave en `system_config`.
- Saldo insuficiente.
- La función no existe en la base real.
- RLS/JWT no cumple el helper SQL.

### FK Error

- Falta crear primero categorías, usuarios, negocios, planes o paquetes requeridos.

## 7. Documentación De Flujos

- `docs/api/routes.md`
- `docs/api/flows.md`
- `docs/03-economy.md`
- `docs/06-business-flow.md`
- `docs/07-transactions-flow.md`
- `docs/08-rls-policies.md`
