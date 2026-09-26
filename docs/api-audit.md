# Auditoría de API v1 — Ok Padel

**Fecha:** 2026-09-26
**Commit:** 8e131b5
**Alcance:** 15 endpoints de api/v1

Este documento archiva la auditoría hecha en el chat sobre el código anterior a `16c00ad`, `7676b1e` y `8e131b5`. Esos commits ya aplicaron parte de las mejoras P1 y P2 de abajo (rate limit, códigos 401, N+1, nombre en el roster, errores 422 estructurados, cortes de tiempo, `request_id`, `public/500.json`, índice `(status, date)`). El hash del header es la revisión en la que se versionó el informe, no el árbol que se leyó.

## Resumen ejecutivo

La API v1 es un JSON REST chico y coherente: 15 operaciones, JWT con expiración, strong params acotados, errores en `{ "error": "..." }`, paginación con tope en partidos, OpenAPI generado desde request specs, y una colección Postman que recorre el flujo de jugador. No aparece un fallo de seguridad que Brakeman no haya visto ni un endpoint roto respecto de sus specs. Lo que la separa de una API de producción es la sesión (token opaco de 24 h, sin logout ni revocación), el rate limit que no cubre escrituras sin JWT válido, el N+1 en el listado de partidos, y una DX incompleta para el front (el roster no trae el nombre del jugador, y un 401 no dice si el token venció).

No se llamó a `https://ok-padel-tup.fly.dev`, no se reejecutó `rspec` ni Bullet, y no se midieron queries. Los N+1 y el Fail2Ban se infieren del código.

---

## 1. Inventario de endpoints

Definidos en `config/routes.rb` (líneas 26–44). Auth = header `Authorization: Bearer <token>`, salvo donde se salta `authenticate_api_user!`.

| # | Método | Path | Auth | Propósito | Éxito | Errores cubiertos en código |
|---|--------|------|------|-----------|-------|------------------------------|
| 1 | POST | `/api/v1/login` | No | Login; devuelve JWT + usuario | 200 | 401 credenciales inválidas o usuario inexistente (mismo mensaje) |
| 2 | GET | `/api/v1/profile` | Sí | Perfil del usuario del token | 200 | 401 |
| 3 | PATCH | `/api/v1/profile` | Sí | Actualiza `name`, `phone`, `self_level`, `bio` | 200 | 401, 422 |
| 4 | GET | `/api/v1/courts` | No | Canchas `active`, con club | 200 | — |
| 5 | GET | `/api/v1/courts/:id` | No | Detalle de cancha activa | 200 | 404 si no existe o no está activa |
| 6 | GET | `/api/v1/matches` | No | Partidos `open` y `full` | 200 + `meta` | Filtro inválido → lista vacía 200, no 400 |
| 7 | GET | `/api/v1/matches/:id` | No | Detalle (cualquier status) | 200 | 404 |
| 8 | POST | `/api/v1/matches` | Sí | Crea partido; `creator` = usuario actual | 201 | 401, 422 |
| 9 | POST | `/api/v1/matches/:id/join` | Sí | Inscripción (`team` obligatorio en `pairs`) | 200 | 401, 404, 422 |
| 10 | DELETE | `/api/v1/matches/:id/leave` | Sí | Baja lógica (`status: cancelled`) | 200 | 401, 404 si no está inscripto, 422 si el creador sale de un confirmado/completado |
| 11 | POST | `/api/v1/matches/:id/played` | Sí | Marca `completed` sin marcador | 200 | 401, 422 |
| 12 | GET | `/api/v1/matches/:match_id/match_results` | No | Reportes + consenso | 200 | 404 |
| 13 | POST | `/api/v1/matches/:match_id/match_results` | Sí | Reporta sets (jugador activo) | 201 | 401, 422 |
| 14 | DELETE | `/api/v1/matches/:match_id/match_results/:id` | Sí | Borra el propio reporte | 200 | 401, 403, 404 |
| 15 | GET | `/api/v1/me/matches` | Sí | Creados o con inscripción activa, cualquier status | 200 + `meta` | 401 |

No hay 204. El único 403 de la API es borrar el resultado de otro. No hay handler propio de 500.

### Parámetros

**Login.** Body: `email`, `password`.

**Profile PATCH.** Body: `name`, `phone`, `self_level`, `bio`. `email`, password y roles no se permiten.

**Courts.** Path `id`. Sin query.

**Matches index y `me/matches`.** Query: `status`, `court_id`, `date` (ISO 8601), `page` (default de Pagy, 1), `per_page` (default 20, mínimo efectivo 1, máximo 50). En el listado público, `status` solo acepta `open` y `full`; otro valor devuelve cero filas.

**Create match.** Body: `court_id`, `time_slot_id`, `date`, `duration` (entero 1–240), `roster_mode` (`pairs` | `individual`), `level_required`, `auto_join` (default `true`). El creador no se manda: lo asigna el controller.

**Join.** Body/query: `team` (`team_a` | `team_b`). Obligatorio si `roster_mode` es `pairs`.

**Played / leave.** Solo el id del partido.

**Report result.** Body: `sets: [{ team_a_games, team_b_games }]`. Sets con ambos juegos en blanco se descartan. Máximo 5 por validación de `MatchSet` (`order` 1–5).

### Forma de las respuestas

Login:

```json
{ "token": "<jwt>", "user": { "id": 1, "name": "...", "email": "...", "phone": "...", "self_level": 4, "category_label": "...", "bio": null, "average_level": "0.0", "average_stars": "0.0", "matches_played": 0 } }
```

Listado de partidos:

```json
{ "matches": [ { "id": 1, "date": "2026-09-26T21:00:00Z", "duration": 90, "status": "open", "roster_mode": "pairs", "level_required": "open", "join_policy": "auto", "court": { "id": 1, "name": "...", "club_id": 1 }, "creator": { "id": 2, "name": "..." }, "match_players": [ { "id": 1, "user_id": 2, "team": "team_a", "status": "confirmed", "joined_at": "..." } ], "players_count": 1, "max_players": 4 } ], "meta": { "current_page": 1, "per_page": 20, "total_pages": 1, "total_count": 1 } }
```

Detalle, create, join, leave y played envuelven `{ "match": { ... } }` y agregan `time_slot`, `match_results` y `consensus`.

Error:

```json
{ "error": "Unauthorized" }
```

### Reglas de negocio que el cliente tiene que conocer

- El listado público solo muestra `open` y `full`. El detalle y los resultados son públicos para cualquier id, incluso `cancelled` o `completed`.
- `join_policy` sale siempre `"auto"`. No existe el campo en base.
- `level_required` se guarda y se devuelve. Join no lo compara con `self_level`.
- No hay validación de “fecha futura” ni de ventana horaria para join, leave o `played`.
- En `pairs`, join sin `team` → 422 `"Team is required in pairs mode"`.
- Leave del creador en `confirmed` o `completed` → 422. Si el creador sale y no queda nadie activo, el partido pasa a `cancelled`.
- `played` lo puede llamar cualquier jugador activo y pone `completed` aunque no haya marcador. Si ya está `completed` y hay consenso → 422.
- Un jugador activo reporta una vez. Si el partido no está `reported`, el segundo reporte → 422. Un solo reporte ya es consenso provisional.
- Borrar un reporte no revierte `player_stats` (deuda ya documentada en el proyecto).

---

## 2. Diseño REST y consistencia

**Lo que está bien.** Recursos en plural y snake_case (`/courts`, `/matches`, `/match_results`), versión en el path, GET de lectura, POST de alta, PATCH de update parcial, DELETE de baja. 201 en create de partido y de resultado. 401 / 403 / 404 / 422 se usan con el significado correcto. El envoltorio es estable: recurso singular o plural (`user`, `court`/`courts`, `match`/`matches`) y el error siempre es `{ error: string }` vía `render_error`.

**Inconsistencias reales.**

- `login`, `profile`, `me/matches`, `join`, `leave` y `played` son acciones, no recursos. Para este tamaño es razonable. Google las nombraría como custom methods (`:join`). No hace falta reescribirlas.
- DELETE de leave y de resultado responden **200 con cuerpo**, no 204. El cuerpo es útil (partido actualizado). Hay que documentarlo como contrato, no cambiarlo por estética.
- `join_policy` está hardcodeado en el Jbuilder:

```7:7:app/views/api/v1/matches/_match.json.jbuilder
json.join_policy "auto"
```

- Un filtro inválido no es un error de cliente. `status` desconocido o `date` mal formada hacen `scope.none` y responden 200 con lista vacía (`matches_controller.rb`, líneas 123–144). El front no puede distinguir “no hay partidos” de “mandé `date=mañana`”.
- Paginación solo en `GET /matches` y `GET /me/matches`. Canchas y resultados no paginan. Con el volumen de un club es aceptable; el contrato no es uniforme.
- El 422 de modelo es un string concatenado, no una lista por campo:

```21:22:app/controllers/api/v1/base_controller.rb
      def unprocessable_entity(exception)
        render json: { error: exception.record.errors.full_messages.join(", ") }, status: :unprocessable_content
```

**Versionado.** `/api/v1` en la URL alcanza. No hace falta versionado por header hasta que exista un cliente que no se pueda actualizar junto con el server. Cuando haya un breaking change, se abre `/api/v2` y se deja v1 hasta que el front del TP2 deje de usarla.

---

## 3. Autenticación y autorización

El token se firma con `secret_key_base`, algoritmo por defecto de `JWT.encode` (**HS256**) y `exp` a 24 horas:

```1:16:app/services/json_web_token.rb
class JsonWebToken
  SECRET_KEY = Rails.application.secret_key_base

  def self.encode(payload, exp = 24.hours.from_now)
    payload = payload.dup
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    body = JWT.decode(token, SECRET_KEY)[0]
    ActiveSupport::HashWithIndifferentAccess.new(body)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end
end
```

`jwt` 3.2.0 trae `algorithms: ['HS256']` en su configuración de decode, así que un token `alg: none` no verifica aunque el controller no pase `algorithm:` explícito. La expiración se verifica (`verify_expiration = true`). Token ausente, inválido, vencido o de un usuario borrado responden todos **401** `"Unauthorized"`. El front no puede mostrar “tu sesión venció” distinto de “token mal formado”.

No hay refresh token, no hay `jti`, no hay denylist y no hay `DELETE /login`. Cambiar la contraseña en Devise no invalida JWTs ya emitidos. Logout en el cliente solo puede borrar el token local; el server lo acepta hasta `exp`.

No hay policies (Pundit/CanCan). La autorización está en el controller:

- Cualquier usuario autenticado crea partidos, se une y reporta.
- Solo un jugador activo marca `played` o reporta.
- Solo el autor borra su resultado (403).
- Roles `admin` / `club_owner` no cambian nada en la API. El back-office es HTML con Devise.

Login: mismo texto `"Invalid credentials"` si el mail no existe o la contraseña falla (`sessions_controller.rb` líneas 9–16), alineado con Devise `paranoid`. El límite es **5 POST /api/v1/login por minuto por IP**, con `Retry-After` y cuerpo JSON. No hay límite por cuenta: muchas IPs pueden probar la misma casilla.

---

## 4. Validaciones y manejo de errores

Strong params están acotados. No se puede asignar `creator_id`, `status`, `email`, password ni roles por la API.

| Capa | Qué cubre |
|------|-----------|
| Controller | Presencia de `sets`, equipo en pairs, jugador activo, autor del reporte, creador que no puede irse |
| Modelo | Duración, día del time slot, cupo (4), equipo en pairs, score de set, unicidad de teléfono y de reporte |
| DB | Checks de duración, precio, `self_level`, uniques de email/phone y de `(match_id, user_id)` |

Los 422 de `RecordInvalid` llegan al cliente. El texto sale de `I18n` con locale por defecto **`:es`** (`config/application.rb` línea 37), mientras los mensajes escritos a mano están en inglés (`"Unauthorized"`, `"Team is required in pairs mode"`, `"invalid set score"`). El README dice que los mensajes de la API están en inglés. Eso es cierto para los strings del controller, y no para `full_messages` de Active Record. Un `duration: 0` puede volver en español y un set inválido en inglés, en el mismo campo `error`.

404 de `RecordNotFound` es siempre `"Not found"`. Leave, si no hay inscripción, lanza ese mismo error a propósito (404, no 422).

`ParameterMissing` → 400 con `exception.message` (inglés de Rails). No hay spec de ese caso.

No hay `rescue_from` de `StandardError` ni `public/500.json` (sí hay `public/500.html`). La app no es API-only: también sirve el admin. Un 500 no capturado puede responder HTML según el `Accept`. El log de producción va a STDOUT con `request_id` y `consider_all_requests_local = false`, así que el stack no se filtra al cliente. El cuerpo exacto del 500 en Fly no se verificó en vivo.

`ActiveRecord::RecordNotUnique` (dos joins concurrentes) no está rescatado: sería 500, no 422.

---

## 5. Performance

No hay gem Bullet ni mediciones. Esto es lectura del código.

**N+1 en el listado.** El index hace `includes(:court, :creator, :match_players)`, pero el Jbuilder no usa esa colección: llama `match.active_match_players`, que es otra query (`where.not(status: :cancelled)`), y después `active_match_players.size`, que arma la relación de nuevo. En un page de 20 partidos son del orden de 40 queries extra de roster, más las 3 del include que el JSON no aprovecha.

```51:53:app/models/match.rb
  def active_match_players
    match_players.where.not(status: :cancelled)
  end
```

**N+1 en el detalle.** `load_match_for_detail` precarga `match_results: :reported_by` y no precarga `match_sets`. El partial recorre `match_result.match_sets`. `consensus_result` vuelve a cargar resultados con `includes(:match_sets)`.

**Canchas.** `Court.includes(:club)` está bien. `court.image.attached?` no usa `with_attached_image`: una query de Active Storage por cancha si el listado crece.

**Índices que sí sirven.** `matches(status)`, `matches(date, court_id)`, `matches(creator_id)`, `match_players(user_id)`, `match_players(match_id, user_id)` unique. El listado filtra por status y ordena por `date`; no hay índice compuesto `(status, date)`. Con el volumen del TP el planner alcanza. Haría falta `EXPLAIN` el día que el listado se note lento.

**Paginación.** `per_page` está limitado a 50 (`matches_controller.rb` líneas 146–149). No hay tope equivalente en canchas porque no paginan.

**Caché.** Solid Cache en producción se usa como backend de Rack::Attack. No hay `stale?`, ETag ni `Cache-Control` en respuestas JSON. `config.action_controller.perform_caching = true` no cachea estos Jbuilder.

**Jobs.** El request de la API hace el trabajo de dominio en línea (cupo, consenso, stats de como máximo 4 jugadores). Eso es barato. Lo pesado ya está en cola: mail de bienvenida (`deliver_later`) y `AutoApproveResultsJob`. No hay un endpoint que debería ser un job y no lo sea.

**Payload.** El listado omite `time_slot`, resultados y consenso. El detalle los incluye. El hueco de producto es el roster: solo `user_id`, sin `name`. No existe `GET /users/:id`, así que el front no puede resolver el nombre.

---

## 6. Seguridad

Brakeman en 0 warnings y bundler-audit en 0 vulnerabilidades, según el estado del repo. Esto es lo que el código muestra además de eso.

| Control | Estado |
|---------|--------|
| SQL crudo en `app/` | No aparece `find_by_sql` ni `where` con string interpolado |
| Mass assignment | `permit` corto; `creator` se setea en el server |
| CORS | Orígenes por `CORS_ORIGINS` (CSV). Default `localhost:3001` y `localhost:5173`. Sin `origins "*"`, sin `credentials: true`. Solo `/api/*` |
| Login throttle | 5/min/IP, testeado |
| Lectura anónima | 60/min/IP |
| Lectura con JWT válido | 100/min/usuario |
| Escritura con JWT válido | 30/min/usuario |
| Logs | `filter_parameters` incluye `:passw`, `:email`, `:token`, `:secret` |
| TLS | `force_ssl = true` en producción → HSTS. Fly además tiene `force_https = true` |
| Headers Rails | `config.load_defaults 8.1` deja `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`. No están redefinidos en el repo |
| CSP | El initializer está comentado |
| JWT | HS256, exp 24 h, secreto = `secret_key_base` |

**Escrituras sin token no entran en ningún throttle.** En `write/user`, si no hay Bearer el bloque devuelve `nil` y Rack::Attack no cuenta el request. `POST /api/v1/matches` sin token (o con token basura) responde 401 y no consume el cupo de 30 ni el de login. Un cliente puede martillar 401. El Fail2Ban del mismo initializer mira `rack.attack.match_type == :throttle` dentro del blocklist; Rack::Attack evalúa blocklists antes que throttles, así que esa condición es muy probable que nunca sea verdadera. No hay spec del blocklist: queda como hallazgo a confirmar con un test, no como bug demostrado.

`CORS_ORIGINS` no está en `fly.toml`. Sin esa variable en Fly, el browser solo acepta los dos localhost. curl al host de Fly funciona igual; una SPA en otro origen, no.

Active Storage en producción está en `:local` (`production.rb` línea 25). El disco de Fly no persiste entre deploys: `image_url` de una cancha puede morir después de un restart. Las imágenes no se suben por la API v1 (solo el admin).

No se inspeccionaron los logs reales de Fly para ver si el header `Authorization` aparece en algún access log de Thruster. Rails no lo imprime en la línea estándar de request.

---

## 7. Testing

Conteo por bloques `response` de rswag en `spec/requests/api/v1/` (no reejecuté la suite; el “303 examples, 0 failures” es el estado declarado del proyecto):

| Archivo | Examples de contrato |
|---------|----------------------|
| `sessions_spec.rb` | 3 |
| `users_spec.rb` | 6 |
| `courts_spec.rb` | 4 |
| `matches_spec.rb` | 25 |
| `match_results_spec.rb` | 11 |
| **Total v1** | **49** |

Cada example declara schema OpenAPI y casi todos assertan campos del JSON, no solo el status. Los flujos de create comprueban el cambio en base (`change(Match, :count)`).

Cobertura de status en esos 49:

| Status | Dónde está | Dónde falta |
|--------|------------|-------------|
| 200 / 201 | Todos los happy paths | — |
| 401 | Login, profile, create, join, leave, mine, played, report, destroy | Show/index públicos no necesitan 401 |
| 403 | Delete del resultado ajeno | No hay otro 403 |
| 404 | Court inactiva o inexistente, match, join, leave, results | — |
| 422 | Profile, create, join, leave, played, report | No se asserta el texto en español/inglés |
| 400 | — | `ParameterMissing` sin spec |
| 429 | Solo login, en `spec/requests/rate_limiting_spec.rb` | Throttles de lectura/escritura y el blocklist no tienen spec |

También hay `spec/requests/cors_spec.rb` (origen permitido y request sin `Origin`). No hay ejemplo de origen rechazado.

No hay spec de token vencido, de `per_page` > 50, de filtro `date` inválido, ni de que `PATCH /profile` ignore `email`. Las factories de usuario, cancha y partido se usan en estos specs y alcanzan para los casos que sí están escritos. No hay un request spec que encadene login → crear → unirse → reportar; ese recorrido está en la colección Postman (20 requests).

---

## 8. Documentación

Swagger cubre las 15 operaciones en `swagger/v1/swagger.yaml`, con `bearer_auth`, schemas de error y de paginación, y ejemplos de body en login, profile, create y results. Se regenera desde los mismos specs. Un dev puede abrir `/api-docs` y probar.

Huecos de la spec:

- `servers` solo tiene `http://localhost:3000`. La URL de Fly no está.
- `PATCH /profile` documenta `name`, `bio`, `self_level` y omite `phone`, que sí se permite.
- `POST /matches` documenta el body sin `time_slot_id`, que sí se permite.
- El 401 de login en el YAML queda descrito como “user does not exist”; el código no distingue ese caso.
- Swagger UI no tiene basic auth. En este TP es aceptable.

El README tiene la tabla de los 15 endpoints, el contrato de paginación, curl de login, profile, courts y results, y enlaza Postman. Con seed (`player@okpadel.local` / `password123`) y `docs/postman/README.md`, un dev nuevo consume la API en local en pocos minutos. La colección corre en orden: login, profile, courts, matches, results.

---

## 9. Estándares de la industria

| Práctica | JSON:API | Google AIP | Microsoft REST | Stripe | GitHub | Ok Padel |
|----------|----------|------------|----------------|--------|--------|----------|
| Versionado en URL | No lo exige | Major en path | En path o header | En path (`/v1`) | En path y header | `/api/v1` |
| Envoltorio de recurso | `{ data, type, id }` | Recurso directo | Recurso directo | Objeto de dominio | Objeto de dominio | `{ match: ... }` |
| Errores | `errors[]` con `source` | `google.rpc.Status` | `error.code` + `details` | `error.type`, `code`, `message` | `message` + `documentation_url` | `{ error: string }` |
| Paginación | `links` + `page[size]` | `page_size` / `page_token` | `@odata` o `nextLink` | cursor `starting_after` | `Link` header | `page` + `meta` |
| Auth | — | OAuth | Bearer | Bearer, API key | Bearer, scopes | Bearer JWT 24 h |
| Idempotencia | — | — | — | `Idempotency-Key` | — | No |
| Custom actions | Relaciones | `:join` | Acciones POST | `POST /v1/.../capture` | Rutas propias | `join`, `leave`, `played` |

Convenciones que ya siguen y conviene conservar: URL versioning, sustantivos en plural, verbos HTTP correctos, 401 vs 403, Bearer, paginación con metadatos en los dos listados grandes, y un único formato de error.

Lo que se puede adoptar sin reescribir clientes actuales:

1. **Código de error estable** al lado del mensaje: `{ "error": { "code": "token_expired", "message": "..." } }`. Es el salto de DX más parecido a Stripe/GitHub y el que más ayuda al front. Se puede introducir en v1 si el front todavía lee `error` como string, o solo en campos nuevos.
2. **400 en filtros inválidos** (`date`, `status`, `page`), en lugar de lista vacía.
3. **`algorithm: "HS256"` explícito** en `JsonWebToken.decode`, para no depender del default de la gema.
4. **Nombre del jugador en `match_players`**, que es un dato que el recurso ya podría incluir.
5. Dejar JSON:API y cursores para una v2. Migrar ahora rompe el TP2 sin ganar claridad en 15 endpoints.

---

## 10. Mejoras priorizadas

No hay un P0 confirmado: nada en el código revisado deja la API abierta a mass assignment, SQL injection, CORS `*`, o un JWT sin firma. Los ítems de abajo son deuda real, ordenada por impacto en el TP y en un deploy de verdad.

| Pri | Tipo | Mejora | Impacto | Esfuerzo | Archivos |
|-----|------|--------|---------|----------|----------|
| P1 | 🟡 | Contar también POST/PATCH/DELETE sin JWT (por IP), y cubrir con spec el throttle de escritura y el Fail2Ban | Alto | S | `config/initializers/rack_attack.rb`, `spec/requests/rate_limiting_spec.rb` |
| P1 | 🟡 | Access token corto + refresh, o al menos denylist en logout y al cambiar password. Hoy el JWT vive 24 h y no se puede invalidar | Alto | L | `app/services/json_web_token.rb`, `jwt_authenticatable.rb`, `sessions_controller.rb`, nueva tabla o Solid Cache |
| P1 | 🟡 | 401 con código `token_expired` vs `unauthorized` | Alto (DX) | S | `json_web_token.rb`, `jwt_authenticatable.rb`, specs y swagger |
| P1 | 🟡 | Eliminar el N+1 del roster: filtrar `match_players` ya cargados (o un scope precargable) y precargar `match_sets` en el detalle | Alto | S | `app/models/match.rb`, `matches_controller.rb`, `_match.json.jbuilder` |
| P1 | 🟡 | Incluir `name` (y solo eso) del jugador en `match_players` | Alto (DX) | S | `_match_player.json.jbuilder`, includes del controller, swagger |
| P1 | 🟡 | Fijar `CORS_ORIGINS` en el entorno de Fly con el origen real del front | Alto si hay SPA | S | `fly.toml` / secrets, `config/initializers/cors.rb` |
| P1 | 🟡 | Active Storage en producción fuera del disco local de la VM | Medio/alto si hay fotos | M | `config/environments/production.rb`, `config/storage.yml` |
| P2 | 🟡 | Errores de validación como lista por campo, en un solo idioma. Alinear el README | Medio | M | `base_controller.rb`, `config/locales`, README |
| P2 | 🟡 | Filtro inválido → 400, no 200 vacío | Medio | S | `matches_controller.rb`, specs |
| P2 | 🟢 | `JsonWebToken.decode(..., algorithm: "HS256")` explícito | Medio | S | `app/services/json_web_token.rb` |
| P2 | 🟡 | Reglas de tiempo para join / leave / played, y hacer cumplir `level_required` si el producto lo promete | Medio | M | `matches_controller.rb`, `match.rb`, `match_player.rb` |
| P2 | 🟡 | `public/500.json` (y 404/422 JSON) para que un error no capturado no caiga en HTML | Medio | S | `public/`, `config/application.rb` |
| P2 | 🟡 | Specs que faltan: token vencido, `per_page` > 50, origen CORS rechazado, mass assignment de `email` | Medio | S | `spec/requests/api/v1/`, `spec/requests/cors_spec.rb` |
| P2 | 🟢 | Swagger: server de Fly, `phone`, `time_slot_id` | Medio | S | specs rswag → `swagger/v1/swagger.yaml` |
| P2 | 🟡 | Reversión de stats al borrar un reporte (deuda ya anotada) | Medio | L | `match.rb`, admin y API de results |
| P3 | 🟢 | Índice `(status, date)` en `matches` cuando el listado crezca | Bajo | S | migración |
| P3 | 🟢 | ETag o cache corto de `GET /courts` | Bajo | S | `courts_controller.rb` |
| P3 | 🟢 | `request_id` dentro del JSON de error | Bajo | S | `base_controller.rb` |
| P3 | 🟢 | Sacar el hardcode de `join_policy` cuando exista el enum | Bajo | M | migración, `_match.json.jbuilder` |
| P3 | 🟢 | CSP para el admin y Swagger UI | Bajo | M | `content_security_policy.rb` |

`join_policy`, la ventana horaria y la reversión de stats ya están escritas como deuda en `AGENTS.md`. Esta auditoría no las redefine: las ubica en P2/P3 porque la API actual funciona con el contrato que documenta (`join_policy: "auto"`, stats que no se revierten).

---

## Anexos

### Auth y error base

```10:18:app/controllers/concerns/jwt_authenticatable.rb
  def authenticate_api_user!
    token = bearer_token
    return render_error("Unauthorized", status: :unauthorized) if token.blank?

    payload = JsonWebToken.decode(token)
    return render_error("Unauthorized", status: :unauthorized) if payload.blank?

    @current_user = User.find_by(id: payload[:user_id])
    render_error("Unauthorized", status: :unauthorized) unless @current_user
  end
```

```13:27:app/controllers/api/v1/base_controller.rb
      def render_error(message, status:)
        render json: { error: message }, status: status
      end
      # ...
      def unprocessable_entity(exception)
        render json: { error: exception.record.errors.full_messages.join(", ") }, status: :unprocessable_content
```

### Tope de página y throttle de escritura

```146:149:app/controllers/api/v1/matches_controller.rb
      def api_per_page
        value = params.fetch(:per_page, 20).to_i
        value = 20 if value < 1
        [ value, 50 ].min
```

```25:34:config/initializers/rack_attack.rb
  throttle("write/user", limit: 30, period: 1.minute) do |req|
    if req.post? || req.patch? || req.put? || req.delete?
      token = req.env["HTTP_AUTHORIZATION"]&.split(" ")&.last
      next nil if token.blank?

      payload = JsonWebToken.decode(token)
      payload[:user_id] if payload
    end
  end
```

### Referencias

- [JSON:API](https://jsonapi.org/)
- [Google API Design Guide](https://cloud.google.com/apis/design)
- [Microsoft REST API Guidelines](https://github.com/microsoft/api-guidelines)
- [Stripe API errors](https://docs.stripe.com/api/errors)
- [GitHub API versions](https://docs.github.com/en/rest/about-the-rest-api/api-versions)
- Contrato local: `README.md` sección API v1, `swagger/v1/swagger.yaml`, `docs/postman/README.md`

### Limitaciones de esta auditoría

- No se golpeó Fly ni se miraron logs de producción.
- No se corrió `rspec`, Bullet ni `EXPLAIN`.
- El Fail2Ban se marca como probable, no como fallo demostrado.
- El cuerpo exacto de un 500 en producción no se capturó.

---

## Resumen final

- 🔴 Críticos: **0** confirmados
- 🟡 Alto impacto: **7** (rate limit de escrituras anónimas, sesión JWT no revocable, 401 opaco, N+1 del roster, roster sin nombre, CORS de Fly sin origen del front, blobs en disco local)
- 🟢 Medio impacto: **9** (errores mezclados y sin campo, filtros que mienten con 200, algoritmo JWT implícito, reglas de tiempo y nivel, 500 posiblemente HTML, specs faltantes, swagger incompleto, stats que no se revierten)
- ⚪ Bajo impacto: **5** (índice compuesto, cache de canchas, `request_id` en el error, `join_policy` hardcodeado, CSP)

Fortalezas principales:

- Quince endpoints con verbos, status y envoltorios consistentes, strong params cerrados y el creador asignado en el server.
- JWT con expiración, login que no revela si el mail existe, CORS sin `*` ni credentials, y throttle de login testeado.
- Documentación usable: OpenAPI generado desde 49 request specs, README con curl y colección Postman ordenada.

Áreas de mejora principales:

- La sesión no se puede cerrar ni acortar de forma útil para el front: 24 h, sin refresh, y todos los fallos de token son el mismo 401.
- El listado de partidos hace queries de más, y el roster no trae el nombre que la pantalla necesita.
- El rate limit y el CORS de producción cubren el caso feliz de desarrollo, no un cliente real en otro origen ni un flood de requests sin token.
