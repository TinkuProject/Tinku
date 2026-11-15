# Despliegue De Seguridad

La migracion `0030_security_and_order_lifecycle.sql` actualiza bases existentes. Los archivos `01` a `05` mantienen la creacion desde cero actualizada. No usar `db:init` para actualizar una base con datos: recrea el esquema.

## Actualizacion

1. Respaldar la base y verificar `DATABASE_URL` y `MIGRATION_DATABASE_URL`.
2. Ejecutar `npm ci`, `npm run db:migrate` y `npm run build`, luego reiniciar la API.
3. Publicar la App actualizada. Cada compra requiere `client_request_id`, un UUID persistente por operacion que se reutiliza despues de un timeout. Los consumidores Web deben incorporar ese dato sin generar una clave nueva en cada reintento.
4. Con la API nueva activa, aplicar la proteccion de documentos y cuentas heredadas descrita abajo.

Si falta `pg_trgm` para los indices de busqueda de la migracion 0026, instalarlo con el administrador de PostgreSQL antes de migrar:

```bash
sudo -u postgres psql -d tinku -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
```

`MIGRATION_DATABASE_URL` tiene prioridad sobre `DATABASE_URL`: debe apuntar a la misma base con credenciales validas y permisos de propietario. No usar permanentemente un superusuario como usuario de ejecucion de la API.

Las columnas nuevas aceptan NULL para conservar registros historicos. La migracion rota los codigos de retiro de pedidos no finalizados que versiones anteriores podian devolver al vendedor; Mis compras obtiene el nuevo codigo al refrescar. Para pedidos listos antiguos sin plazo, otorga un plazo completo desde la migracion.

## Pagos Y Entregas

- Stripe guarda `gateway_target_id` al crear el pago. El webhook verifica usuario, tipo, importe, moneda y paquete contra el PaymentIntent. Las solicitudes manuales no aceptan gateway.
- Los eventos sin `processed_at` pueden recuperarse. Un bloqueo de sesion PostgreSQL impide procesar simultaneamente el mismo evento y se libera si el worker cae. Los ya procesados son idempotentes. Un intento fallido de tarjeta no cancela un PaymentIntent reutilizable.
- El UUID de compra serializa peticiones concurrentes, compara su contenido y devuelve el pedido existente sin volver a cobrar ni descontar stock.
- Solo el comprador recibe el codigo de retiro. Validarlo exige `ready_for_pickup`, plazo vigente y propiedad del punto de retiro o rol administrativo. Los cambios administrativos de estado no reemplazan esa confirmacion.
- El mantenimiento de la API procesa retiros vencidos cada minuto, hasta 50 por ciclo: reembolsa, repone stock, libera inventario y conserva la incidencia. `marketplace_pickup_expiration_days` controla el plazo de nuevos pedidos listos. No depende de pg_cron.
- Las ventas historicas anteriores a la custodia que ya acreditaron al vendedor requieren conciliacion si ese saldo fue gastado; nunca se crea dinero ni se aplica una devolucion parcial silenciosa.

## Reservas, Impulsos Y Almacenes

- Reservar exige evento activo y vigente, negocio aprobado cuando corresponde, saldo y cupo. Una reserva cancelada no puede reconfirmarse directamente.
- `DELETE /reservations/:id` cancela y conserva historial. La devolucion revierte la transferencia del organizador y anula tickets atomicamente. Se informa si hubo uso del ticket, termino el evento o falta saldo del organizador para devolver; un fallo no aplica cambios parciales.
- Cancelar un evento procesa sus reservas y devoluciones dentro de la misma transaccion. Solo su creador puede cancelarlo.
- Las reservas nuevas registran `payee_id`. La migracion solo recupera destinatarios antiguos con una transferencia emparejada exacta; los casos ambiguos necesitan conciliacion.
- Un impulso no puede cambiar de objeto ni de fecha inicial. Extenderlo cobra dias adicionales; reducirlo no devuelve Tinkus. Admin/master conserva la gratuidad.
- El socio no puede editar aprobacion, estado u owner del almacen. Vincularlo a un negocio requiere una solicitud de stock aceptada; el inventario se crea al recibirla y las reservas de stock no son editables manualmente.
- `/marketplace/orders/warehouse/list` lista pedidos de almacenes propios y `/marketplace/orders/warehouse/:id/ready` permite prepararlos para retirar. Ventas e historial de compras conservan paginacion de 20 elementos.

## Documentos Privados

Los documentos de reclamos se suben privados. Solo el solicitante o administracion recibe enlaces firmados de 15 minutos. La App obtiene un enlace nuevo al abrir cada documento.

Para los archivos antiguos, incluidos uploads nunca adjuntados:

```bash
npm run storage:privatize-claims
npm run storage:privatize-claims -- --apply
```

El primer comando inventaria; el segundo cambia ACL en Firebase Storage y requiere permisos sobre los objetos. Con acceso uniforme de bucket, revisar IAM para impedir lectura publica: las ACL individuales no reemplazan una politica publica del bucket.

Rechazar una edicion solo limpia archivos del mismo objeto que no esten publicados. Las solicitudes revisadas no pueden repetir esa limpieza.

## Cuentas Y Firma

`npm run seed` crea el revisor Stripe sin password interactiva. No crea cuentas humanas conocidas. Los fixtures requieren `NODE_ENV=development` o `test`, y una `SEED_TEST_PASSWORD` propia de al menos 12 caracteres, con mayuscula y numero, compatible con la validacion de registro:

```bash
npm run seed -- --test-users
```

Para detectar y deshabilitar cuentas heredadas con la password antigua:

```bash
npm run security:seed-accounts
npm run security:seed-accounts -- --apply
```

El modo apply deshabilita esas cuentas y revoca refresh tokens. No elimina usuarios ni modifica saldos. Preparar un administrador con credenciales propias antes de aplicarlo en produccion.

Los keystores y `key.properties` estan excluidos de Git; los archivos locales se conservan para compilar. Los commits anteriores aun pueden contener copias: revisar accesos, conservar backup cifrado y gestionar rotacion si hubo exposicion. Con Play App Signing, usar el procedimiento de cambio de upload key; en APK distribuidos directamente, cambiar firma afecta actualizaciones. No se reescribe automaticamente el historial ni se reemplaza la firma existente.

## Sesion, Hora Y Push

- La rotacion de refresh tokens es transaccional y admite un unico uso concurrente.
- Cambiar correo exige codigo en la nueva direccion: `POST /auth/email/change-code` y `POST /auth/email/change`. La edicion comun no puede sustituirlo.
- Al salir, la App desregistra FCM antes de borrar credenciales y cancela la suscripcion de renovacion del token.
- La API usa UTC al escribir y leer PostgreSQL. La App presenta el plazo de retiro en hora local.
- `notification_push_queue` conserva entregas pendientes con reintentos y espera creciente. La notificacion de compra se inserta junto con el cobro: un fallo push no revierte una compra confirmada.

## Pruebas

```bash
npm test
npm run test:database
npm audit --omit=dev
```

`test:database` solo permite PostgreSQL local: crea una base temporal aleatoria, valida esquema y migracion, ejecuta pruebas economicas y elimina exclusivamente esa base temporal. Requiere permisos para crear bases y extensiones. No reinicializa `DATABASE_URL`.
