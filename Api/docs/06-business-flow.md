# Flujo De Negocios

Este documento describe el ciclo de vida real de negocios en la API actual.

## Estados Relevantes

El estado de un negocio se deriva de varios campos:

- `owner_id`: define si tiene propietario.
- `status`: `pending`, `active`, `inactive`, `suspended`.
- `validated`: indica validación administrativa.
- claims pendientes en `business_claim_requests`.
- updates pendientes en `entity_updates`.

No existe un único campo que explique todo el estado operativo.

## Rutas Principales

Lectura pública:

- `GET /businesses`
- `GET /businesses/:id`
- `GET /businesses/category/:categoryId`

Lectura autenticada:

- `GET /businesses/mine`
- `GET /businesses/status` admin/master

Escritura:

- `POST /businesses` partner/admin/master
- `POST /businesses/system` admin/master
- `PUT /businesses/:id` admin/master
- `PATCH /businesses/:id/validate` admin/master
- `PATCH /businesses/:id/reject` admin/master
- `DELETE /businesses/:id` partner/admin/master

## Creación Por Partner

1. Usuario debe estar autenticado y tener rol `partner`, `admin` o `master`.
2. `POST /businesses` llama el flujo de service.
3. Para creación con cargo se usa `create_business_with_charge`.
4. El RPC:
   - valida `current_app_user_id()`;
   - lee `business_create_cost`;
   - crea negocio con `status = pending` y `validated = false`;
   - cobra Tinkus mediante `perform_tinku_spend`.

Resultado esperado:

- negocio pendiente;
- transacción `spend` aprobada;
- wallet descontado.

## Creación Por Sistema/Admin

`POST /businesses/system` permite crear negocio desde administración. Puede usarse para cargar negocios sin dueño inicial, dependiendo de la lógica del service.

## Validación Administrativa

Admin/master puede:

- validar negocio;
- rechazar negocio;
- cambiar estados administrativos.

Recomendación pendiente:

- registrar cada decisión en `audit_logs`.

## Claims De Propiedad

Rutas:

- `POST /business-claim-requests` partner
- `GET /business-claim-requests/me` partner
- `GET /business-claim-requests/pending` admin/master
- `PATCH /business-claim-requests/:id/review` admin/master
- `GET /business-claim-requests/business/:businessId` admin/master/partner

Flujo:

1. Partner solicita propiedad sobre un negocio.
2. Se crea `business_claim_requests` con `status = pending`.
3. Admin/master revisa.
4. Si se aprueba:
   - se asigna o actualiza `businesses.owner_id`;
   - el negocio queda `validated = true`;
   - el negocio queda `status = active`;
   - se marca request como `approved`;
   - se rechazan automáticamente otros claims pendientes sobre el mismo negocio.
5. Si se rechaza:
   - request queda `rejected`;
   - negocio no cambia de propietario.

Reglas:

- No eliminar claims.
- Mantener documentos (`documents`) como evidencia.
- Auditar aprobación/rechazo.

## Updates De Entidades

Rutas:

- `POST /entity-updates` partner
- `GET /entity-updates/me` partner
- `GET /entity-updates/entity` partner/admin/master
- `GET /entity-updates` admin/master
- `PATCH /entity-updates/:id/approve` admin/master
- `PATCH /entity-updates/:id/reject` admin/master

Flujo:

1. Partner propone cambios en `entity_updates.data`.
2. Admin/master aprueba.
3. RPC actual aplica cambios para:
   - `business`: `approve_business_update`;
   - `event`: `approve_event_update`.
4. Rechazo usa `reject_entity_update`.

Pendiente:

- si se aceptan `product` y `certification` como `update_entity_type`, faltan RPC/documentación de aprobación para esos tipos o debe bloquearse su creación.

## Reglas De Ownership

- Partner solo debe operar entidades propias.
- Admin/master puede operar globalmente.
- No cambiar `owner_id` por atajos fuera del flujo definido.
- Revisar RLS y services juntos; uno solo no basta.

## Cosas A Solucionar

- Auditar claims y validaciones.
- Alinear permisos granulares con middleware real.
- Completar aprobación de `entity_updates` para todos los tipos permitidos.
- Agregar tests de ownership y creación con cargo.
