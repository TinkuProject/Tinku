# Roles y Permisos

## Descripción

El sistema de acceso de Tinku está diseñado para ser flexible, escalable y seguro.
Se basa en una combinación de:

* Roles base (definen el nivel general del usuario)
* Permisos (definen acciones específicas)
* Subroles o labels (agrupan permisos para facilitar gestión)

La implementación HTTP calcula los permisos efectivos al autenticar cada request. Combina los permisos de `role_permissions` con los provenientes de `user_labels` y `label_permissions`. `permissionMiddleware` aplica políticas por código y `roleMiddleware` se conserva como adaptador compatible para las rutas existentes.

Las verificaciones de propiedad se centralizan en `OwnershipService` y en los helpers de `role.helper.ts`. La interfaz nunca es la fuente de autorización.

---

## Roles base

### user
Usuario final que consume contenido.

Puede:
* ver negocios, eventos y productos
* realizar reservas
* dejar reseñas
* comprar y usar Tinkus

---

### partner
Usuario que gestiona contenido comercial.

Puede:
* crear y administrar negocios propios
* crear productos, eventos, promociones y boosts
* interactuar con usuarios desde su negocio

Restricción:
* solo puede operar sobre entidades propias

---

### admin
Usuario encargado de la operación del sistema.

Puede:
* gestionar contenido global
* crear usuarios de cualquier rol
* aprobar solicitudes (negocios, claims, etc.)
* moderar contenido
* crear contenido comercial sin cargo

Excepción:
* la creación de almacenes siempre cobra `business_create_cost`, también a admin/master

---

### master
Usuario con control sobre el sistema económico y configuraciones críticas.

Puede:
* gestionar coin_packages
* gestionar cashout_packages
* modificar configuraciones globales
* supervisar auditoría
* asignar permisos críticos
* crear usuarios de cualquier rol
* administrar contenido global sin cargo, excepto la creación de almacenes

---

## Usuarios no autenticados (guest)

Representa usuarios que acceden al sistema sin iniciar sesión.

Puede:
* ver negocios, eventos y contenido público
* explorar la plataforma

No puede:
* realizar reservas
* dejar reseñas
* interactuar con contenido
* comprar o usar Tinkus
* acceder a información privada

Regla:
Todas las acciones que impliquen interacción requieren autenticación obligatoria.

---

## Permisos

Los permisos representan acciones específicas dentro del sistema.

### Políticas HTTP base
* `account.access`
* `partner.access`
* `payment_request.create`
* `owned_content.manage`
* `administration.manage`
* `authorization.manage`

---

### Pagos (entrada de dinero)
* create_payment
* approve_payment
* view_payments

---

### Retiros (salida de dinero)
* approve_cashout

---

### Economía
* manage_coin_packages
* manage_cashout_packages
* manage_system_config
* create_admin_adjustment
* view_financial_transactions

---

## Principios de diseño
1. Los permisos son la fuente de verdad
2. Los roles son una base inicial
3. Los permisos son combinables
4. No se debe confiar en roles sin validación de permisos
5. Los permisos deben evaluarse en backend y reforzarse mediante RLS

`roleMiddleware([...])` ya no compara directamente el rol: traduce las combinaciones heredadas a estas políticas. Las rutas nuevas deben utilizar `permissionMiddleware` explícitamente.

---

## Subroles (Labels)

Los labels permiten agrupar permisos bajo una identidad visual.

Ejemplos:
* Operario
* Moderador
* Soporte
* Economía
* Finanzas

Características:
* No afectan la lógica de negocio directa
* Influyen en los permisos efectivos del usuario
* Son utilizados para organización en el panel administrativo

---

## Relación entre roles, permisos y labels

Permisos efectivos de un usuario:
* permisos del rol base
* permisos de los labels asignados

---

## Restricciones críticas

Algunos permisos no deben ser delegables:
* create_admin_adjustment
* manage_system_config
* manage_cashout_packages

---

## Seguridad

* Validación obligatoria en backend
* No confiar en frontend
* Auditoría obligatoria en acciones críticas
* Validar autenticación antes de permitir cualquier acción de escritura
* El registro público siempre crea un `user`, aunque el cliente intente enviar otro rol
* `user` y `partner` sólo pueden editar sus propios datos mediante `/users/me`; no pueden cambiar `role` ni `status`
* Los cambios de rol/estado y la creación de cuentas con roles elevados requieren admin/master
* Las entidades de partner se validan por ownership en la API, además de las restricciones visuales de App
* Sólo `master` puede modificar permisos o asignaciones de permisos a roles
* Admin/master omiten ownership donde la política lo permite; la edición directa de eventos continúa reservada al creador

---

# Matriz de permisos

## user
* create_payment
* view_payments

---

## partner

* create_business
* edit_business (propios)
* create_event
* edit_event (propios)
* manage_reviews (propios)

---

## admin (base)

* approve_business
* approve_claims
* manage_reviews
* view_payments
* view_financial_transactions

---

## admin + Operario

* create_business
* edit_business

---

## admin + Moderador

* manage_reviews
* approve_claims

---

## admin + Economía

* approve_payment
* view_payments
* view_financial_transactions

---

## admin + Finanzas

* approve_cashout

---

## master

* manage_coin_packages
* manage_cashout_packages
* manage_system_config
* create_admin_adjustment
* approve_payment
* approve_cashout
* view_payments
* view_financial_transactions

---

## Reglas de la matriz

1. Los roles base definen mínimos
2. Los labels expanden permisos
3. Ningún usuario debe tener permisos económicos críticos sin auditoría
4. El rol master tiene control total sobre economía
5. Admin nunca tiene control total sin labels

---

## Buenas prácticas

* No crear nuevos roles innecesarios
* Usar permisos para flexibilidad
* Usar labels para organización
* Auditar todas las acciones económicas
* Revisar periódicamente permisos asignados
