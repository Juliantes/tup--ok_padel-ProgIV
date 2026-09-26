# Postman — API v1 Ok Padel

Colección y environment para probar la API JSON en desarrollo. La fuente principal para **Postman Desktop** son los YAML bajo `postman/` (workspace local en el repo).

La colección tiene **20 requests** (flujo de jugador + casos de error 401/404/422). La API documentada en OpenAPI tiene **15 operaciones**; los requests extra no son endpoints distintos, sino variantes y validaciones negativas del mismo contrato.

## Postman Desktop — configuración

1. Abrí **Postman Desktop** (no la extensión de Cursor).
2. Conectá el repo como workspace local:
   - **File → Open** (o *Connect to Git / local folder*, según tu versión).
   - Elegí la carpeta **`ok_padel`** (raíz del proyecto Rails).
   - **No** uses `docs/postman` ni `Programacion IV` como raíz.
3. En el sidebar deberías ver:
   - **Collections → Ok Padel API**
   - **Environments → Ok Padel Local**
4. Arriba a la derecha, activá el environment **Ok Padel Local**.

El manifiesto [`.postman/resources.yaml`](../../.postman/resources.yaml) apunta a `postman/collections/Ok Padel API` y al environment YAML. Si no ves la colección, cerrá Postman, volvé a abrir la carpeta `ok_padel` y esperá unos segundos a que indexe.

## Correr todos los requests en Desktop (Collection Runner)

1. App lista en local: seguí [README — instalación](../../README.md#instalación-paso-a-paso) (`bin/rails db:prepare`, `bin/rails db:seed`, `bin/rails s`).
2. Usuario demo del seed (también en **POST Login (happy)**): `player@okpadel.local` / `password123`.
3. En **Collections**, sobre **Ok Padel API** → **Run** (▶ / *Run collection*).
4. Environment: **Ok Padel Local**.
5. Dejá el orden por defecto (la colección ya está ordenada para una corrida completa) → **Run Ok Padel API**.

**Éxito esperado:** **20/20** requests en verde y **0** tests fallidos en el resumen del Collection Runner. Los scripts guardan `token`, `matchId` y `resultId` en el environment durante la corrida.

### Orden de la corrida (automático)

| Carpeta | Flujo |
|---------|--------|
| Auth | Login OK → login 401 |
| Profile | GET / PATCH / GET sin token |
| Courts | listado, detalle, 404 |
| Matches | listado → create (sin auto_join) → join → leave → create inválido → create (auto_join) → GET by id → mis partidos |
| Match results | listado → mark played → report → borrar propio reporte |

## Archivos en el repo

| Ruta | Uso |
|------|-----|
| [`postman/collections/Ok Padel API/`](../../postman/collections/Ok%20Padel%20API/) | Colección YAML (Postman Desktop, workspace local) |
| [`postman/environments/Ok Padel Local.environment.yaml`](../../postman/environments/Ok%20Padel%20Local.environment.yaml) | Variables de entorno |
| [`postman/Ok_Padel_API.postman_collection.json`](../../postman/Ok_Padel_API.postman_collection.json) | Mismo contenido en JSON (import clásico / CI) |
| [`postman/Ok_Padel_Local.postman_environment.json`](../../postman/Ok_Padel_Local.postman_environment.json) | Environment JSON |

Los JSON se mantienen alineados con la colección YAML para `bin/postman-run` y para importar sin workspace local.

## Alternativa por terminal (CI)

```bash
bin/postman-run
```

Usa [Newman](https://github.com/postmanlabs/newman) con los JSON de `postman/`. Requiere Node/npm. Con el servidor en `localhost:3000`, Newman debería terminar con **0 failed** en assertions.

## Variables de environment

| Variable | Valor inicial | Uso |
|----------|---------------|-----|
| `baseUrl` | `http://localhost:3000` | Host de la API |
| `token` | vacío | **POST Login (happy)** |
| `matchId` | vacío | Creación de partido (201) |
| `resultId` | vacío | **POST Report result** (201) |

## Tests automáticos

Cada request incluye tests (`pm.test`): status esperado, JSON, persistencia de variables y validaciones por endpoint.

## Ajustes habituales

- **`court_id`**: en el seed suele ser `1`; confirmá con **GET Courts**.
- **Fechas de partidos**: deben ser futuras; actualizá `date` en los POST si falla validación.
- **Join tras `auto_join: true`**: el creador ya está en el roster; la colección usa `auto_join: false` para join/leave.

## Más detalle de la API

- [README principal — API v1](../../README.md#api-v1)
- [OpenAPI / Swagger UI](../../README.md#documentación-de-la-api-swagger) — spec en [`swagger/v1/swagger.yaml`](../../swagger/v1/swagger.yaml); UI en `http://localhost:3000/api-docs` con el server levantado
- [Auditoría de API v1](../auditoria-api-v1.md) — inventario, seguridad, contrato y deuda pendiente

La colección apunta solo a `http://localhost:3000` (`baseUrl`); no incluye tokens ni secretos de producción. El `token` del environment se rellena en runtime tras el login de la corrida.
