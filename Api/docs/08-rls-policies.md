# Seguridad De Base De Datos

`database/04-init.sql` ya no crea politicas RLS dependientes de Supabase. Tinku mantiene PostgreSQL como base de datos, pero el cliente movil no accede directo a la base: toda lectura/escritura pasa por la API.

## Estrategia Actual

- La API emite JWT propios en `/auth/register`, `/auth/login`, `/auth/google` y `/auth/refresh`.
- `authMiddleware` valida el bearer token y carga el usuario activo desde `users`.
- `roleMiddleware` protege rutas por rol cuando corresponde.
- Los DAOs usan un cliente PostgreSQL compatible con el estilo anterior de Supabase para reducir cambios de arquitectura.
- Las llamadas a DB pueden fijar `app.user_id` y `app.user_role` dentro de la transaccion mediante `set_config`.
- Las funciones SQL sensibles usan helpers como `current_app_user_id()`, `current_app_user_role()`, `is_admin()` e `is_master()`.

## Reglas Por Capa

### HTTP

- Rutas publicas: no usan `authMiddleware`.
- Rutas autenticadas: usan `authMiddleware`.
- Rutas administrativas: usan `authMiddleware` y `roleMiddleware(["admin", "master"])` o equivalente.

### Services

- Validan ownership y reglas de negocio que dependen de varios recursos.
- No deben confiar en datos enviados por cliente para owner/rol si se pueden obtener desde `req.user`.
- Gastos de Tinkus, reservas, cashout y aprobaciones deben pasar por RPC transaccionales.

### SQL/RPC

- Las funciones de cobro, reserva, cashout, pagos y auditoria son la ultima defensa de consistencia.
- Si una funcion depende del usuario actual, debe leer `current_app_user_id()`.
- Si una funcion depende del rol, debe leer `current_app_user_role()` o helpers derivados.
- `set_system_context()` queda reservado para jobs o flujos internos ejecutados por el backend.

## Puntos A Revisar Al Agregar Endpoints

1. Definir si la ruta es publica, autenticada o administrativa.
2. Verificar que el controller no acepte `user_id`, `owner_id` o `reviewed_by` desde el body cuando puede derivarlo de `req.user`.
3. Mantener operaciones economicas dentro de funciones SQL transaccionales.
4. Registrar auditoria para movimientos de Tinkus, aprobaciones, rechazos, eliminaciones y acciones administrativas sensibles.
5. Evitar devolver datos privados en endpoints publicos o agregados.

## Nota

PostgreSQL podria volver a usar RLS en el futuro, pero ya no debe depender de `auth.uid()`, `auth.jwt()` ni roles internos de Supabase. Si se activa RLS, debe basarse en el contexto que setea la API o en roles de conexion propios.
