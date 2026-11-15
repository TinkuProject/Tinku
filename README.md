# Tinku Monorepo

Repositorio para la API Node.js, la aplicación Flutter para Android y la web pública (landing y panel) de Tinku.

## Componentes

- `Api/`: API persistente Node.js con PostgreSQL/PostGIS.
- `App/`: aplicación Flutter. El workflow compila y firma el APK Android de producción.
- `Web/`: landing y panel web desplegados juntos en Vercel. La URL estable de descarga es `/downloads/tinku-latest.apk` y redirige al release activo en el VPS.
- `config/domains.json`: dominios productivos y rutas estables.
- `config/environments/production.env`: valores públicos de build no relacionados con dominios. No guardar secretos aquí.
- `deploy/`: empaquetado, validaciones y despliegue del backend.
- `.github/workflows/deploy.yml`: validación de PR y despliegue de producción desde `main`.

## Flujo

Cada pull request y cada push a `main` ejecuta las comprobaciones de API, web y Flutter. En `main`, el despliegue de producción se activa cuando `TINKU_DEPLOY_ENABLED` vale `true` y se limita a los componentes afectados: `Api/` publica API, `App/` compila y publica APK, y `Web/` publica en Vercel. `config/domains.json` activa los tres destinos; un `workflow_dispatch` en `main` permite forzar el despliegue completo. La API aplica las migraciones y comprueba `/health/ready` antes de dar por bueno el cambio.

Para validar localmente, instala Node.js 22, Flutter 3.35.6 y las dependencias de cada componente. Los scripts raíz son `npm run check:api`, `npm run check:web` y `npm run check:app`.

## Puesta en marcha de producción

Antes de activar el despliegue, completa las variables y secretos que se enumeran en [la guía de despliegue](docs/migration/monorepo-deploy.md), configura Vercel con `Web/` como raíz del proyecto y prepara el VPS siguiendo los paths esperados por `deploy/server-deploy-api.sh`. Los únicos dominios productivos se configuran en `config/domains.json`.

Actions genera el APK firmado e identificado por commit y ejecución, valida firma, aplicación, versión y checksum, y publica el release en el VPS. El VPS cambia de forma atómica el release activo; Vercel mantiene una redirección fija y no se vuelve a desplegar al actualizar la app. Los binarios `.apk` y `.aab` se excluyen de Git.

Los dominios productivos se definen únicamente en `config/domains.json`. `config/environments/production.env` contiene valores públicos de build que no son dominios. Los `.env` y defines locales se ignoran en Git y se usan solo como overrides de desarrollo.

La promoción de web y APK ocurre después de comprobar la URL de staging. El despliegue de API realiza las migraciones antes de cambiar la release activa; si el healthcheck falla, restaura el código anterior. Restaurar código no revierte una migración de base de datos: prepara backups y revisa la compatibilidad de cada migración antes de habilitar producción.

Ver [el registro de repositorios de origen](docs/migration/original-repositories.md) para los repositorios y revisiones usados al crear esta copia.
