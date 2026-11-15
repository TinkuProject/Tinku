# Repositorios de origen

La estructura de este monorepo se preparó copiando los componentes actuales sin modificar las carpetas originales:

| Componente | Carpeta de origen | Repositorio remoto | Revisión de origen |
| --- | --- | --- | --- |
| API | `TinkuProject/Api` | `https://github.com/TinkuProject/Api.git` | `16ca1f6` |
| App | `TinkuProject/App` | `https://github.com/TinkuProject/App.git` | `5ad6f00` |
| Web | `TinkuProject/Web` | `https://github.com/TinkuProject/Web.git` | `c2f32a4` |

Los binarios generados y carpetas de dependencias no forman parte de las copias. Las variables y credenciales locales ignoradas por Git se copian para poder ejecutar pruebas locales en el monorepo. El APK no se publica desde Vercel: Actions publica cada release firmado en el VPS, mientras que `/downloads/tinku-latest.apk` mantiene una URL estable.
