# Tinku App

La revision de seguridad agrega compras idempotentes con UUID persistente, retiro QR solo cuando esta listo y vigente, historiales paginados, pedidos de almacenes propios y cambio de correo con codigo. Los documentos de reclamos obtienen enlaces privados nuevos al abrirse. Al cerrar sesion, FCM se desregistra antes de borrar credenciales. Los keystores locales se conservan para compilar y estan excluidos de Git. Ver [despliegue de API y seguridad](../Api/docs/09-security-rollout.md).

Aplicacion movil de Tinku construida con Flutter. Consume la API de Tinku, usa autenticacion propia con JWT, Google Maps para mapas y ubicacion, y servicios nativos para camara, archivos, geolocalizacion y almacenamiento seguro.

## Que Contiene

La app cubre estos modulos principales:

- Autenticacion: login, registro con verificacion por correo, recuperacion y cambio de password, Google Sign-In y sesion persistente.
- Home y exploracion: negocios, servicios, eventos, lugares turisticos, categorias, boosts, favoritos y busqueda.
- Negocios: creacion, administracion, productos, promociones, certificaciones, horarios, redes sociales, transporte y multimedia.
- Eventos: listado publico, gestion propia, calendario, detalle, reservas/asistencia.
- Turismo: lugares turisticos, tags, detalle, visitados y relaciones de transporte.
- Wallet/economia: balance, transacciones, compra de monedas, solicitud para volverse socio, puntos de carga.
- Usuario: perfil, notificaciones con navegación directa, favoritos, ayuda y acerca de.
- Marketplace: compra con Tinkus, seguimiento, QR/clave de retiro, pago retenido hasta la entrega y cancelación/rechazo con devolución antes de completar el pedido.
- Socio: publicaciones, pedidos recibidos, preparación y validación de entregas.
- Monedero: compra, suscripciones, historial y solicitudes de retiro de Tinkus.
- Administración: aprobaciones y revisión manual de solicitudes de retiro.

## Tecnologias

- Flutter / Dart.
- `provider` para estado y dependencias.
- `http` para llamadas REST a la API.
- `connectivity_plus` para detectar cambios de conectividad del dispositivo.
- `google_sign_in` para login con Google.
- `google_maps_flutter`, `geolocator` y `geocoding` para mapas/ubicacion.
- `image_picker`, `file_picker`, `flutter_image_compress` y `path_provider` para archivos e imagenes.
- `flutter_secure_storage` y `shared_preferences` para persistencia local.
- `cached_network_image`, `overlay_support`, `table_calendar`, `url_launcher`.
- `qr_flutter` para mostrar pases QR de asistencia a eventos.
- `flutter_stripe` para pagos con tarjeta mediante PaymentSheet.

## Estructura

```text
lib/
  config/        configuracion de endpoints y claves cliente
  core/          inicializacion, navegacion, enums, sesion y observers
  controllers/   estado y orquestacion por modulo
  domain/        validaciones de dominio compartidas
  extensions/    helpers sobre modelos
  helpers/       utilidades de media, roles, transporte, suscripciones
  mappers/       conversiones entre modelos de UI/dominio
  models/        modelos Dart usados por servicios y vistas
  providers/     providers globales de usuario/notificaciones
  services/      clientes REST y servicios externos
  ui/            temas, colores y enums de UI
  utils/         utilidades de fecha, mapas, dialogos, parsers, archivos
  views/         pantallas
  widgets/       componentes reutilizables
```

## Configuracion

La API se configura en `lib/config/config.dart`.

Por defecto apunta al servidor actual:

```text
http://82.25.66.67:3003
```

La app lee sus variables cliente desde `dart-define`. Para pruebas puntuales se puede pasar una variable directa:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

Para habilitar pagos con Stripe en la app, pasar tambien la publishable key:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000 --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxx
```

Para no escribir las variables en cada comando, crear un archivo local
`dart_defines.local.json` tomando como base `dart_defines.example.json`:

```json
{
  "API_BASE_URL": "http://localhost:3003",
  "SERVER_GOOGLE_CLIENT_ID": "google_web_client_id.apps.googleusercontent.com",
  "STRIPE_PUBLISHABLE_KEY": "pk_test_xxx"
}
```

Ese archivo esta ignorado por Git y debe contener tus valores reales. Luego ejecutar:

```bash
flutter run --dart-define-from-file=dart_defines.local.json
```

En Android emulador, si la API corre en la maquina host, cambiar `API_BASE_URL` dentro de `dart_defines.local.json` a:

```text
http://10.0.2.2:3000
```

Notas:

- Android release bloquea trafico HTTP mediante
  `android:usesCleartextTraffic="false"`. El manifest de debug lo habilita
  únicamente para probar una API local en emulador o dispositivo.
- `config.dart` solo lee variables. Google Sign-In server client ID y Stripe deben ir en `dart_defines.local.json`.
- Las claves nativas como Google Maps Android siguen en `AndroidManifest.xml`. Si se rotan, actualizar ahi y en las consolas correspondientes.
- `google-services.json` ya esta dentro de `android/app/`.
- Stripe usa `STRIPE_PUBLISHABLE_KEY` desde `--dart-define`; las claves secretas y webhook secret viven solo en la API.

## Seguridad

La seguridad efectiva se reparte entre la App, la API y la configuración de
los proveedores:

- **Transporte:** la compilación Android release sólo acepta HTTPS. HTTP queda
  disponible exclusivamente en debug para desarrollo local.
- **Sesión:** access y refresh tokens se guardan con `flutter_secure_storage`.
  La App comparte una sola renovación de token entre requests simultáneos y
  elimina la sesión local al confirmar credenciales inválidas, no ante un fallo
  temporal de red.
- **Autorización:** la App oculta acciones según sesión y rol para mejorar la
  experiencia, pero la API vuelve a validar rol, ownership, estado y permisos
  en cada operación protegida.
- **Identidad:** las cuentas locales requieren verificación de correo. Google
  Sign-In entrega un ID token que la API valida contra el client ID del
  servidor; no se confía sólo en el email enviado por el dispositivo.
- **Red:** el cliente central aplica timeouts, reintenta únicamente lecturas
  idempotentes ante fallos transitorios y no reintenta escrituras para evitar
  cargos u operaciones duplicadas. Las búsquedas reemplazan requests antiguos.
  Cuando el dispositivo queda sin Wi-Fi ni datos móviles, una pantalla global
  conserva la navegación actual, informa el problema y se retira al recuperar
  la conexión.
- **Secretos:** la App sólo incluye credenciales públicas de cliente, como la
  publishable key de Stripe. Secret keys, JWT secrets, SMTP, Firebase Admin y
  el webhook secret permanecen en el entorno de la API.
- **Pagos:** Stripe PaymentSheet usa la publishable key en el dispositivo; la
  acreditación se confirma en el servidor mediante webhook firmado.
- **Notificaciones:** FCM registra por usuario tokens de dispositivo revocables.
  El contenido recibido sólo navega a rutas conocidas por la App.
- **Permisos Android:** se solicitan cámara, imágenes, notificaciones y
  ubicación sólo para sus funciones visibles. No se solicita ubicación en
  segundo plano.
- **Datos locales:** no deben almacenarse contraseñas, secret keys ni datos de
  tarjeta. Los datos de tarjeta los captura Stripe, no Tinku.

Configuraciones que deben mantenerse fuera del repositorio:

- `dart_defines.local.json` con valores cliente del entorno.
- `.env` de la API con secretos y allowlist CORS.
- Keystore Android y su contraseña.
- Credenciales Firebase Admin.

La clave de Google Maps incluida en Android debe restringirse en Google Cloud
por nombre de paquete, huellas SHA autorizadas y API permitida. La seguridad de
release también depende de servir la API detrás de HTTPS válido y mantener las
dependencias actualizadas.

## Instalacion

Desde `App/`:

```bash
flutter pub get
```

Si hay problemas con caches:

```bash
flutter clean
flutter pub get
```

## Comandos

Ejecutar en dispositivo/emulador:

```bash
flutter run --dart-define-from-file=dart_defines.local.json
```

Ejecutar usando una API local:

```bash
flutter run --dart-define-from-file=dart_defines.local.json
```

Para eso, mantener todas las variables y cambiar solo `API_BASE_URL` dentro de `dart_defines.local.json`:

```json
{
  "API_BASE_URL": "http://10.0.2.2:3000",
  "SERVER_GOOGLE_CLIENT_ID": "google_web_client_id.apps.googleusercontent.com",
  "STRIPE_PUBLISHABLE_KEY": "pk_test_xxx"
}
```

Ejecutar con archivo local de variables:

```bash
flutter run --dart-define-from-file=dart_defines.local.json
```

Analizar:

```bash
flutter analyze
```

Tests:

```bash
flutter test
```

Build Android debug:

```bash
flutter build apk --debug --dart-define-from-file=dart_defines.local.json
```

Build Android release:

```bash
flutter build apk --release --dart-define-from-file=dart_defines.local.json
```

El build Android de desarrollo no requiere `android/key.properties`. Si ese archivo existe, el build release usa el keystore configurado allí; si no, el APK release local queda sin firma de producción. El workflow del monorepo genera `key.properties` temporalmente desde los secretos de GitHub y valida la firma antes de publicar.

Build web, si se usa el target Flutter web:

```bash
flutter build web
```

## Flujo De Arranque

1. `main.dart` crea las dependencias locales con `AppInitializer.create()` y muestra inmediatamente la aplicacion.
2. `MultiProvider` registra la instancia compartida de `AuthService`, `UserProvider` y notificaciones.
3. `AppInitializer.initializeDeferred()` inicia en segundo plano Firebase, permisos push, Stripe, locale completo y orientacion.
4. `UserProvider.loadSession()` restaura la sesion en paralelo sin borrar credenciales ante fallos temporales de red.
5. `AuthService` concentra la renovacion de tokens para que las consultas simultaneas compartan una sola rotacion.
6. `MaterialApp` define rutas principales y usa `MenuZoom` como wrapper de varias pantallas.

## Contrato Con La API

Los servicios en `lib/services/` usan rutas REST sin prefijo global, por ejemplo:

- `/auth`
- `/users`
- `/businesses`
- `/products`
- `/events`
- `/media`
- `/reviews`
- `/payment-requests`
- `/wallets`
- `/nearby`

La mayoria extiende `BaseService<T>`, que centraliza:

- `baseUrl`
- headers JSON
- token bearer via `AuthService.getValidAccessToken()`
- manejo basico de errores
- timeout de 15 segundos por intento para solicitudes normales y 90 segundos para cargas de archivos
- un reintento automatico para lecturas idempotentes ante errores transitorios
- cancelacion de solicitudes anteriores en flujos marcados como `latest`, como la busqueda del marketplace
- CRUD generico

Las escrituras (`POST`, `PUT`, `PATCH` y `DELETE`) no se reintentan automaticamente para evitar operaciones duplicadas.

Algunas rutas publicas usan llamadas sin token en servicios especificos.

## Rendimiento

Se optimizaron cargas que antes hacian llamadas por item:

- Exploracion general: imagenes por entidad via `/media/entities`.
- Extras de negocios: reviews via `/reviews/entities` y productos via `/products/businesses`.
- Productos propios y carrusel: imagenes de productos via `/media/entities`.
- Certificaciones: media de certificaciones via `/media/entities`.
- Certificaciones de varios negocios: `/certifications/businesses`.
- Favoritos y boosts: entidades por lote via `/businesses/batch`, `/events/batch` y `/tourist-places/batch`.
- Reseñas: perfiles publicos via `/users/batch` y avatars via `/media/entities`.
- Transporte asociado: rutas de varias lineas via `/transport-routes/lines`.
- Soporte para futuras listas/detalles agregados: `/opening-hours/entities`, `/entity-transport-relations/entities`, `/discounts/businesses` y `/social-links/businesses`.
- Asistencia a eventos: tickets via `/event-tickets`, emision QR via `/event-tickets/days/:ticketDayId/qr` y check-in via `/event-tickets/check-in`.

Pendientes recomendados si la app sigue lenta:

- Reemplazar `FutureBuilder` por categoria individual en listas largas por mapas precargados con `/categories/batch`.
- Agregar paginacion/filtros server-side en pantallas que hoy piden `getAll()`.
- Evaluar endpoints agregados para home/nearby si se necesita navegar sin pedir la entidad completa al tocar.

## Problemas Conocidos

- `flutter analyze` y `dart format` pueden quedarse colgados en algunos entornos Windows/OneDrive. Si ocurre, cerrar procesos `dart.exe` residuales y volver a intentar desde una terminal limpia.
- Hay claves cliente en archivos del repo. Las claves publicas de cliente pueden vivir en app, pero cualquier secreto de servidor debe quedarse fuera del repo.
- Algunas pantallas de detalle todavia combinan varias rutas por seccion; conviene evaluar endpoints agregados si siguen siendo lentas.

## Checklist Al Cambiar La API

- Actualizar el servicio en `lib/services/`.
- Revisar controllers que consumen ese servicio.
- Confirmar que los nombres de query/body coincidan con Zod en la API.
- Evitar loops de requests si existe endpoint batch.
- Correr `flutter analyze` y probar la pantalla afectada.
