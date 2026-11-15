# Configuración de GitHub, Vercel y servidor

## GitHub

El workflow `.github/workflows/deploy.yml` corre validaciones en pull requests y en `main`. Los trabajos de producción solo arrancan cuando el push fue a `main` y la variable de repositorio `TINKU_DEPLOY_ENABLED` tiene el valor `true`. Déjala en `false` hasta que Vercel, los secretos y el servidor estén listos.

Las pruebas de los tres componentes corren en cada PR y push a `main`, pero los despliegues de producción son selectivos: `Api/` activa API; `App/` activa APK; `Web/` activa Vercel. Cambios en `config/domains.json` activan los tres. Los scripts de `deploy/` se asignan al componente correspondiente en el detector del workflow; cambios documentales no despliegan. Un `workflow_dispatch` desde `main` fuerza un despliegue completo. Si un cambio de API requiere publicar también un cliente, incluye los cambios de ese cliente en el mismo push; el detector se basa en rutas.

Configura un environment de GitHub llamado `production` y añade estos secretos:

| Secreto | Uso |
| --- | --- |
| `TINKU_ANDROID_KEYSTORE_BASE64` | Keystore Android existente, codificado en Base64 |
| `TINKU_ANDROID_KEYSTORE_PASSWORD` | Contraseña del keystore |
| `TINKU_ANDROID_KEY_ALIAS` | Alias de la clave de firma |
| `TINKU_ANDROID_KEY_PASSWORD` | Contraseña de la clave |
| `VPS_HOST` | Host o IP del VPS |
| `VPS_PORT` | Puerto SSH del VPS |
| `VPS_USER` | Usuario SSH de despliegue |
| `VPS_SSH_KEY` | Clave privada SSH de Actions |
| `VPS_KNOWN_HOSTS` | Línea verificada de `known_hosts` del VPS |
| `VERCEL_TOKEN` | Token para la CLI de Vercel |
| `VERCEL_ORG_ID` | Identificador del equipo Vercel |
| `VERCEL_PROJECT_ID` | Identificador del proyecto web Vercel |

Añade estas variables de repositorio para compilar y verificar Android:

| Variable | Uso |
| --- | --- |
| `TINKU_ANDROID_CERT_SHA256` | Huella SHA-256 esperada del certificado de firma actual |
| `TINKU_GOOGLE_WEB_CLIENT_ID` | Client ID público de Google Sign-In usado por la app |
| `TINKU_STRIPE_PUBLISHABLE_KEY` | Clave pública de Stripe usada por la app |

Los valores de Google y Stripe son identificadores/llaves públicas de cliente, nunca claves secretas. Los secretos API, JWT, OAuth privados y de base de datos se configuran directamente en el servidor.

## Vercel

En Vercel crea un proyecto para el repositorio GitHub de Tinku y configura `Web` como **Root Directory** y Next.js como framework. En la sección **Root Directory**, activa **Include source files outside of the Root Directory in the Build Step**: `Web/next.config.mjs` importa la configuración compartida desde `deploy/` y `config/`, que están fuera de `Web/`.

El archivo `Web/vercel.json` desactiva los deployments automáticos disparados directamente por Git. Mantén el repositorio conectado para administrar el proyecto; producción se despliega desde el workflow de GitHub Actions, que filtra cambios por carpeta y corre `vercel build` y `vercel deploy --prebuilt`. El workflow prepara el deployment sin mover el dominio, verifica landing y redirección de APK y luego promueve ese deployment. La CLI puede desplegar el proyecto aunque tenga el repositorio conectado.

En **Settings → General** copia el **Project ID**. El **Organization ID** aparece en la configuración del equipo o en `.vercel/project.json` después de vincular el proyecto con la CLI. Crea un **Vercel Access Token** y guarda los tres valores en el environment `production` del repositorio GitHub como `VERCEL_TOKEN`, `VERCEL_ORG_ID` y `VERCEL_PROJECT_ID`. No hacen falta variables API duplicadas en Vercel: el workflow deriva el origen desde `config/domains.json`.

El proyecto web usa `https://tinku-web.vercel.app` como dominio público. `config/domains.json` debe tener en `webOrigin` el origen público final de la landing/panel, porque se usa para construir la URL pública del APK. El dominio API definido actualmente es `https://api-tinku.duckdns.org`.

Los únicos dominios productivos están en `config/domains.json`. CI deriva de allí `NEXT_PUBLIC_API_URL`, la URL API de la app y el destino de la redirección estable del APK. No dupliques los dominios en variables de producción de Vercel.

## VPS de API

El flujo espera Node.js 22, `npm`, `pm2`, `curl`, `flock`, `tar` y Bash, además de conectividad saliente a PostgreSQL/PostGIS. El directorio esperado es `/var/www/tinku/monorepo/deploy`, con `inbox/`, `releases/` y `shared/api.env`; el último contiene las variables privadas de runtime. PM2 ejecuta la API en `127.0.0.1:3300`; el proxy HTTPS existente debe dirigir el dominio API allí y publicar `/health/ready`.

El usuario SSH necesita permisos para colocar los paquetes y ejecutar el script remoto, y el usuario de proceso necesita acceso a las carpetas compartidas y a la base de datos. El aprovisionamiento del servidor y la configuración de proxy quedan para la siguiente etapa; esta carpeta solo deja listo el mecanismo del lado del repositorio.

El workflow ejecuta `Api` migrations antes de activar la nueva release. El mecanismo restaura el enlace de código anterior si el proceso no inicia o no responde al healthcheck, pero no puede deshacer cambios de esquema. Revisa las migraciones y confirma un backup restaurable antes de habilitar despliegues automáticos.

## APK y redirección estable

La landing y el panel usan `/downloads/tinku-latest.apk`. Vercel responde con una redirección al endpoint estable del API en el VPS. El API lee el release activo y redirige a `/downloads/releases/<releaseId>/Tinku.apk`; cada release firmado, su metadata y checksum quedan en una carpeta propia. Actions verifica el certificado, la aplicación, versión y SHA-256 antes de subirlos, y el VPS cambia el enlace `deploy/apks/current` de forma atómica. Actualizar la app no requiere un nuevo deployment de Vercel.

En el VPS hay que crear `deploy/apks/releases/` con permisos para el usuario de Actions/API y configurar el proxy HTTPS del dominio API para enviar `GET /downloads/tinku-latest.apk` a Node en `127.0.0.1:3300`. Configura además la ruta estática `/downloads/releases/` con alias de solo lectura a `/var/www/tinku/monorepo/deploy/apks/releases/`, deshabilita el listado de directorios y permite APK grandes con streaming. Esta ruta estática evita pasar el binario por Express. El workflow necesita los secretos `VPS_HOST`, `VPS_PORT`, `VPS_USER`, `VPS_SSH_KEY` y `VPS_KNOWN_HOSTS`, compartidos con el despliegue API.

## Habilitar producción

El workflow valida API, app y web en `main`, pero no despliega mientras `TINKU_DEPLOY_ENABLED` no sea `true`. Añade primero los secretos de Vercel y GitHub, prepara los secretos Android y VPS, configura en el VPS el dominio API, TLS, proxy y rutas del APK, y verifica los despliegues de prueba. Cuando todo esté listo, crea o confirma la variable de repositorio `TINKU_DEPLOY_ENABLED=true`. A partir de ahí, cada push a `main` valida los tres componentes y despliega solo los componentes afectados.
