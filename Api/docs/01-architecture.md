# Arquitectura

## Descripción general

La arquitectura de Tinku está diseñada como un conjunto de módulos desacoplados que interactúan entre sí mediante contratos claros. El objetivo es permitir crecimiento del sistema, facilitar mantenimiento y garantizar control sobre operaciones críticas, especialmente las económicas.

El sistema permite acceso público a contenido sin autenticación, restringiendo las acciones de interacción y operaciones económicas a usuarios autenticados.

Implementación actual:

* API HTTP con Express en `src/index.ts`.
* Separación por `routes`, `controllers`, `services`, `dao`, `validation` y `dto`.
* PostgreSQL como base de datos y RPC.
* Autenticacion propia con JWT y soporte de Google Sign-In.
* Firebase Admin para storage.
* Validación de entrada con Zod.
* Autorización HTTP principalmente por roles mediante `authMiddleware` y `roleMiddleware`.
* Middleware, services y funciones `SECURITY DEFINER` para proteger operaciones críticas.

Se prioriza:

* Separación de responsabilidades
* Trazabilidad de acciones
* Escalabilidad horizontal
* Consistencia de datos

---

## Módulos del sistema

### 1. Acceso

Responsable de la identidad, autenticación y autorización.

Incluye:

* Usuarios (users)
* Roles base (user, partner, admin, master)
* Permisos granulares
* Subroles (labels)

Responsabilidades:

* Definir qué puede hacer cada usuario
* Permitir configuración flexible de permisos
* Evitar lógica rígida basada únicamente en roles

Regla clave:
El backend valida permisos efectivos. `authMiddleware` combina `role_permissions` con los permisos de labels y los expone al middleware de autorización. Las rutas heredadas con `roleMiddleware` se traducen a políticas centrales.

---

### 2. Economía

Módulo central que gestiona la moneda Tinku y todas las operaciones financieras.

Incluye:

* Wallets
* Transacciones financieras
* Pagos externos
* Configuración económica
* Paquetes de retiro (cashout_packages)
* Auditoría

Responsabilidades:

* Registrar todos los movimientos económicos
* Garantizar que el saldo sea derivado de transacciones
* Controlar tanto la entrada como salida de dinero del sistema
* Permitir configuración dinámica mediante paquetes de compra y retiro (coin_packages, cashout_packages)
* Evitar manipulación directa de balances

Reglas clave:

* Toda operación económica genera una financial_transaction.
* Las operaciones externas de pago se registran en payments.
* Toda acción crítica genera un registro en audit_logs
* No existen cambios directos de saldo sin trazabilidad

---

### 3. Negocios

Gestiona la presencia de negocios dentro de la plataforma.

Incluye:

* Registro de negocios
* Reclamo de propiedad
* Validación por administradores

Responsabilidades:

* Permitir creación inicial (incluso sin dueño)
* Gestionar transferencia de propiedad
* Validar autenticidad mediante procesos administrativos

Flujo clave:
Creación → Reclamo → Validación → Asignación

---

### 4. Contenido

Encargado de todo lo que el usuario consume dentro de la aplicación.

Incluye:

* Productos
* Eventos
* Promociones (discounts)
* Impulsos (boosts)

Responsabilidades:

* Permitir monetización
* Generar interacciones económicas
* Servir como base de interacción del usuario

Relación con economía:
Cualquier acción sobre contenido puede generar financial_transactions.

---

### 5. Interacción

Gestiona la participación del usuario dentro del sistema.

Incluye:

* Reseñas
* Visitas y favoritos
* Reservas
* Notificaciones

Responsabilidades:

* Registrar comportamiento del usuario
* Generar engagement
* Servir como base para recompensas (tinkus)

Ejemplos:

* Comentar → genera recompensa
* Reservar evento → genera transacción

---

### 6. Transporte

Gestiona las líneas de transporte y su relación con entidades.

Incluye:

* Tipos de vehículo
* Líneas de transporte
* Rutas (puntos geográficos)
* Relación con entidades

Responsabilidades:

* Mostrar qué líneas pasan cerca de una entidad
* Mejorar la accesibilidad para el usuario
* Permitir filtrado y descubrimiento por ubicación
* Proveer información pública sobre accesibilidad a negocios y eventos

Estado actual:

* Asociación manual por parte del administrador o creador

Evolución futura:

* Cálculo automático basado en geolocalización
* Uso de consultas espaciales (PostGIS)

---

### 7. Turismo

Extiende el sistema para incluir puntos de interés no comerciales.

Incluye:

* Lugares turísticos
* Etiquetas
* Relación entre lugares y etiquetas

Responsabilidades:

* Enriquecer contenido del sistema
* Permitir categorización flexible

---

### 8. Monetización

Gestiona ingresos y modelos de negocio adicionales.

Incluye:

* Suscripciones
* Paquetes de compra de monedas (coin_packages)
* Paquetes de retiro de monedas (cashout_packages)

Responsabilidades:

* Generar ingresos recurrentes
* Facilitar adquisición de Tinkus

---

### 9. Soporte y Metadatos

Información complementaria para entidades.

Incluye:

* Redes sociales
* Horarios
* Certificaciones
* Puntos físicos
* Media (imágenes y videos asociados a entidades)

Responsabilidades:

* Completar la información de negocios
* Mejorar experiencia del usuario

---

## Relación entre módulos

### Flujo principal del usuario

users → contenido (businesses/events/products) → interacción → financial_transactions → wallets

### Flujo económico

payments / acciones del sistema → financial_transactions → wallets → audit_logs

En la implementación actual, varios flujos económicos pasan por RPC: `approve_payment_request`, `perform_tinku_spend`, `create_business_with_charge`, `create_event_with_charge`, `create_discount_with_charge`, `create_boost_with_charge` y `create_reservation_with_payment`.

### Flujo administrativo

admin/master → permisos/configuración → impacto en contenido/economía → audit_logs

### Flujo de transporte

entidad (business/event/place) → relación transporte → visualización para usuario

---

## Principios de diseño

1. Separación de responsabilidades
   Cada módulo tiene un propósito claro y limitado.

2. Trazabilidad
   Toda acción relevante queda registrada.

3. Configuración dinámica
   El sistema evita valores hardcodeados.

4. Escalabilidad
   La arquitectura permite agregar nuevas funcionalidades sin romper las existentes.

5. Consistencia
   Los datos críticos (especialmente económicos) tienen una única fuente de verdad.

6. Auditoría transversal  
   Todas las acciones críticas, tanto económicas como administrativas, deben registrarse en audit_logs.

