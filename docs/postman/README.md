# Postman — API v1 Ok Padel

Colección y environment de ejemplo para probar la API JSON en desarrollo local.

## Archivos

| Archivo | Descripción |
|---------|-------------|
| `Ok_Padel_API.postman_collection.json` | Requests agrupados (Auth, Profile, Courts, Matches) |
| `Ok_Padel_Local.postman_environment.json` | Variables `baseUrl`, `token`, `matchId` |

## Requisitos

1. Servidor Rails en marcha: `bin/rails s` (puerto 3000 por defecto).
2. Base con datos demo: `bin/rails db:seed`.
3. [Postman Desktop](https://www.postman.com/downloads/) (o compatible con Collection v2.1).

Usuario de prueba del seed: **`player@okpadel.local`** / **`password123`**.

## Importar

1. Abrí Postman → **Import**.
2. Arrastrá o seleccioná ambos JSON de esta carpeta.
3. En el selector de environment (arriba a la derecha), elegí **Ok Padel Local**.

Documentación oficial: [Importing and exporting in Postman](https://learning.postman.com/docs/getting-started/importing-and-exporting/importing-and-exporting-overview/).

## Variables de environment

| Variable | Valor inicial | Uso |
|----------|---------------|-----|
| `baseUrl` | `http://localhost:3000` | Host de la API |
| `token` | vacío | Se completa con el test del request **POST Login (happy)** |
| `matchId` | vacío | Se completa al crear un partido (`POST` matches con status 201) |

Si corrés la API en otro host o puerto, editá solo `baseUrl`.

## Orden sugerido

1. **Auth → POST Login (happy)** — guarda el JWT en `token`.
2. **Profile / Courts / Matches** — el resto de requests autenticados usan `Authorization: Bearer {{token}}`.
3. Para **Join** y **Leave**:
   - Creá un partido con **POST Create match (auto_join: false)** (actualiza `matchId`).
   - **POST Join match** → **DELETE Leave match**.

**GET Match by id** usa `{{matchId}}`; si está vacío, setealo manualmente o creá un partido antes.

## Tests automáticos

Cada request incluye tests mínimos (`pm.test`):

- Status HTTP esperado (200, 201, 401, 404, 422, etc.).
- Login: persiste `token` en el environment activo.
- Alta de partido (201): persiste `matchId`.
- Respuestas de error: comprueba que exista `error` en el JSON.

Los tests son un punto de partida: podés ampliarlos, cambiar bodies (`court_id`, fechas) y re-exportar la colección al repo si querés compartir mejoras.

## Ajustes habituales

- **`court_id`**: en el seed suele ser `1`; confirmá con **GET Courts**.
- **Fechas de partidos**: deben ser futuras; si falla validación, actualizá el campo `date` en los POST.
- **Join tras `auto_join: true`**: el creador ya está en el roster; usar otro usuario o `auto_join: false`.

## Más detalle de la API

Contratos, ejemplos `curl` y códigos de error: [README principal — API v1](../../README.md#api-v1).
