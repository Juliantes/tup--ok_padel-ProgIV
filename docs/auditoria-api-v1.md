# Auditoría de API v1 — Ok Padel

**Fecha:** 2026-09-26
**Árbol leído:** `main` @ `47b762e` (`docs: document recalculate_for deuda as planned tech debt`)
**Alcance:** 15 operaciones de `api/v1`. No se modificó código de la app.
**Host público:** `https://ok-padel-tup.fly.dev` (consultado el mismo día; ver sección 6 y el apartado de deploy).

`docs/api-audit.md` archiva una revisión anterior, de antes de `16c00ad`. Este informe describe el código actual. Donde el host de Fly no coincide con ese código, se marca aparte.

No se reejecutó `rspec`, Brakeman, Bullet ni `EXPLAIN` en la auditoría original. Tras los fixes P1/P2 de abajo, la suite local quedó en **343 examples, 0 failures** (2026-09-26).

### Fixes P1 cerrados (2026-09-26, post-auditoría)

| Hallazgo | Cambio | Spec |
|----------|--------|------|
| Bearer inválido sin throttle (escritura) | `write/ip` cuenta también cuando hay header pero `user_id_from_token` es `nil` | `rate_limiting_spec.rb` — 21.º POST con `Bearer invalid` → 429 |
| Fail2Ban roto | Contador en `throttled_responder` + `blocklist("block banned IPs")` vía cache de Rack::Attack | `rate_limiting_spec.rb` — 16.º 429 de login → 17.º POST → 403 |
| `join_policy` inválido → 500 | `enum :join_policy, ..., validate: true` en `Match` | `matches_spec.rb` — `join_policy: "nope"` → 422 + `errors.join_policy` |
| GET con Bearer inválido sin throttle | `read/ip` cuenta IP si el token no decodifica (mismo patrón que `write/ip`) | `rate_limiting_spec.rb` — 61.º GET `/courts` con `Bearer invalid` → 429 |
| Enums inválidos → 500 | `validate: true` en enums de `Match` y `Court`; `MatchPlayer#team` con `allow_nil` | `matches_spec.rb` — `join_policy` / `roster_mode` / `level_required` → 422 |

Fly **no** se redesplegó (sigue la demo antigua). `MatchResult#winner_team` es un método calculado (no hay enum en DB).

---

## Resumen ejecutivo

La API v1 en el repo es un JSON REST chico y coherente: 15 operaciones, JWT HS256 con expiración y códigos de 401 distintos, strong params cerrados, errores de validación por campo en inglés, paginación con tope, OpenAPI generado desde los request specs y una colección Postman que recorre el flujo de jugador. No aparece mass assignment de `creator_id` / `email` / roles, ni SQL interpolado, ni CORS con `*` o `credentials`.

Lo que la separa de una API de producción real es la sesión (token opaco de 24 h, sin logout ni revocación) y campos de negocio (`join_policy`, `level_required`) que se guardan y se devuelven sin cambiar el `join`. Además, el proceso que responde hoy en Fly no es este árbol: un `GET /api/v1/profile` sin token devuelve `{"error":"Unauthorized"}` y `GET /api/v1/matches?status=nope` responde 200 con lista vacía, que es el contrato anterior a `16c00ad`.

---

## 1. Inventario de endpoints

Definidos en `config/routes.rb` (líneas 26–44). Auth = header `Authorization: Bearer <token>`, salvo los `skip_before_action :authenticate_api_user!`.

| # | Método | Path | Auth | Propósito | Éxito | Errores que arma el controller |
|---|--------|------|------|-----------|-------|--------------------------------|
| 1 | POST | `/api/v1/login` | No | Login; JWT + usuario | 200 | 401 `Invalid credentials` (mail inexistente o password incorrecta, mismo texto) |
| 2 | GET | `/api/v1/profile` | Sí | Perfil del token | 200 | 401 `token_missing` / `token_invalid` / `token_expired` |
| 3 | PATCH | `/api/v1/profile` | Sí | Actualiza `name`, `phone`, `self_level`, `bio` | 200 | 401, 422 con `errors` por campo |
| 4 | GET | `/api/v1/courts` | No | Canchas `active`, con club | 200 (304 si el ETag coincide) | — |
| 5 | GET | `/api/v1/courts/:id` | No | Detalle de cancha activa | 200 | 404 si no existe o no está activa |
| 6 | GET | `/api/v1/matches` | No | Partidos `open` y `full` | 200 + `meta` | 400 si el filtro no parsea |
| 7 | GET | `/api/v1/matches/:id` | No | Detalle, cualquier status | 200 | 404 |
| 8 | POST | `/api/v1/matches` | Sí | Crea partido; `creator` = usuario actual | 201 | 401, 422 de modelo (enums inválidos vía `validate: true`) |
| 9 | POST | `/api/v1/matches/:id/join` | Sí | Inscripción (`team` obligatorio en `pairs`) | 200 | 401, 404, 422 |
| 10 | DELETE | `/api/v1/matches/:id/leave` | Sí | Baja lógica (`status: cancelled` en el jugador) | 200 | 401, 404 si no está inscripto, 422 |
| 11 | POST | `/api/v1/matches/:id/played` | Sí | Marca `completed` sin marcador | 200 | 401, 422 |
| 12 | GET | `/api/v1/matches/:match_id/match_results` | No | Reportes + consenso | 200 | 404 |
| 13 | POST | `/api/v1/matches/:match_id/match_results` | Sí | Reporta sets (jugador activo) | 201 | 401, 422 |
| 14 | DELETE | `/api/v1/matches/:match_id/match_results/:id` | Sí | Borra el propio reporte (solo en `reported`; admin sin ese límite) | 200 | 401, 403, 404, 422 |
| 15 | GET | `/api/v1/me/matches` | Sí | Creados o con inscripción activa, cualquier status | 200 + `meta` | 401, 400 en filtros |

No hay 204. El único 403 de la API es borrar el resultado de otro. Un 500 no capturado lo atiende `ErrorsController` con `public/500.json`.

### Parámetros

**Login.** Body: `email`, `password`.

**Profile PATCH.** Body: `name`, `phone`, `self_level`, `bio`. `email`, password y roles no están en el `permit` (`users_controller.rb` líneas 20–22). Hay spec de que `email` se ignora.

**Courts.** Path `id`. Sin query.

**Matches index y `me/matches`.** Query: `status`, `court_id`, `date` (ISO 8601), `page`, `per_page` (default 20, valores `< 1` pasan a 20, máximo 50). En el listado público el scope base ya es `open`/`full`. Un `status` que existe en el enum pero no es `open` ni `full` (por ejemplo `cancelled`) no es 400: el validador lo deja pasar y el filtro devuelve `scope.none` → 200 con lista vacía (`matches_controller.rb` líneas 172–178 y 140–146). Un `status` desconocido (`nope`) sí es 400.

**Create match.** Body: `court_id`, `time_slot_id`, `date`, `duration` (entero 1–240), `roster_mode` (`pairs` | `individual`), `level_required`, `auto_join` (default `true`), `join_policy` (`auto` | `manual` | `auto_by_level`, default `auto`). El creador lo asigna el controller.

**Join.** `team` (`team_a` | `team_b`), body o query. Obligatorio si `roster_mode` es `pairs`.

**Played / leave.** Solo el id del partido.

**Report result.** Body: `sets: [{ team_a_games, team_b_games }]`. Sets con ambos juegos en blanco se descartan. `MatchSet` exige `order` 1–5 y un marcador de set válido (`app/models/match_set.rb` líneas 4–29).

### Forma de las respuestas (según Jbuilder; el ejemplo de canchas sí se capturó en Fly)

Login (`sessions/create.json.jbuilder`):

```json
{ "token": "<jwt>", "user": { "id": 1, "name": "...", "email": "...", "phone": "...", "self_level": 4, "category_label": "...", "bio": null, "average_level": "0.0", "average_stars": "0.0", "matches_played": 0 } }
```

Listado de partidos (`matches/index.json.jbuilder` + `_match.json.jbuilder`):

```json
{
  "matches": [{
    "id": 1, "date": "2026-09-28T00:00:00Z", "duration": 90, "status": "open",
    "roster_mode": "pairs", "level_required": "fifth", "join_policy": "auto",
    "court": { "id": 1, "name": "Cancha 1", "club_id": 1 },
    "creator": { "id": 2, "name": "..." },
    "match_players": [{
      "id": 1, "user_id": 2, "team": "team_a", "status": "confirmed",
      "joined_at": "...", "user": { "id": 2, "name": "..." }
    }],
    "players_count": 1, "max_players": 4
  }],
  "meta": { "current_page": 1, "per_page": 20, "total_pages": 1, "total_count": 1 }
}
```

Detalle, create, join, leave y played envuelven `{ "match": { ... } }` con `time_slot`, `match_results` y `consensus` (`show_details: true`).

Error de `render_error`:

```json
{ "error": "token_expired", "request_id": "..." }
```

Error de validación de modelo (`render_record_errors`):

```json
{ "error": "unprocessable_entity", "errors": { "self_level": ["is not included in the list"] }, "request_id": "..." }
```

En Fly, el 26 sep 2026, `GET /api/v1/courts` respondió 200 con tres canchas activas del seed (sin `image_url`). `GET /api/v1/matches?per_page=1` respondió un partido `full` **sin** el objeto `user` dentro de `match_players`. Ese roster es el Jbuilder anterior a `16c00ad`, no el del árbol leído.

### Reglas de negocio que el cliente tiene que conocer

- El listado público solo muestra `open` y `full`. El detalle y los resultados son públicos para cualquier id, incluso `cancelled` o `completed`.
- `join_policy` se persiste y se devuelve. `MatchPlayer.enroll` siempre deja `status: confirmed` (`match_player.rb` líneas 25–40). No hay lectura de `join_policy` ni de `level_required` fuera del `permit` y del enum (`grep` en `app/`). Un partido `manual` se une igual que uno `auto`.
- Ventanas: `JOIN_CUTOFF_HOURS` (default 1), `LEAVE_CUTOFF_HOURS` (default 2), `PLAYED_CUTOFF_HOURS` (default 24) en `Match#joinable?` / `#leavable?` / `#playable?`. Si no hay `time_slot`, las tres devuelven `true`.
- En `pairs`, join sin `team` → 422 `"Team is required in pairs mode"`.
- Leave del creador en `confirmed` o `completed` → 422. Si el creador sale y no queda nadie activo, el partido pasa a `cancelled`. El `creator_id` no se transfiere.
- `played` lo puede llamar cualquier jugador activo y pone `completed` aunque no haya marcador. Si ya está `completed` y hay consenso → 422.
- Un jugador activo reporta una vez. Si el partido no está `reported`, el segundo reporte → 422. Un solo reporte ya es consenso provisional (`Match#consensus_result`).
- Borrar un reporte recalcula stats con `PlayerStat.recalculate_for` (síncrono, historial completo). Admin puede borrar en `completed`; el reporter no.

---

## 2. Diseño REST y consistencia

**Lo que está bien.** Recursos en plural y snake_case (`/courts`, `/matches`, `/match_results`), versión en el path, GET de lectura, POST de alta, PATCH de update parcial, DELETE de baja. 201 en create de partido y de resultado. 401 / 403 / 404 / 422 se usan con el significado correcto en los casos que el controller arma a propósito. El envoltorio es estable: `user`, `court`/`courts`, `match`/`matches`, `results`.

**Acciones que no son recursos.** `login`, `profile`, `me/matches`, `join`, `leave` y `played`. Para 15 endpoints es razonable. Google las nombraría como custom methods (`:join`). No hace falta reescribirlas.

**DELETE con cuerpo.** Leave y delete de resultado responden 200 con el partido actualizado, no 204. El cuerpo es el contrato útil; conviene dejarlo documentado.

**Dos sobres de error.** `render_error` pone un string en `error`. `render_record_errors` pone el código `unprocessable_entity` y un hash `errors`. El README (líneas 389–391) describe los dos. Un 422 de `"too late to join"` y un 422 de `self_level` no tienen la misma forma. El 429 de Rack::Attack es `{ "error": "..." }` sin `request_id` (`rack_attack.rb` líneas 74–86).

**Filtro a medias.** `status=nope` → 400 `invalid status`. `status=cancelled` en el listado público → 200 y `total_count: 0`, porque `cancelled` es una clave del enum y después `apply_status_filter` la descarta con `scope.none`. El front no distingue “no hay cancelados en el listado público” de “mandé un status que este endpoint no lista”.

**Paginación.** Solo `GET /matches` y `GET /me/matches`. Canchas (3 en el seed de Fly) y resultados no paginan. `per_page=100` se recorta a 50 y responde 200 (hay spec). `per_page=0` cae al default 20, no es 400. No verifiqué el overflow de Pagy (`page` mayor que `total_pages`).

**Versionado.** `/api/v1` en la URL alcanza. Header de versión (estilo GitHub) no aporta mientras el único cliente se pueda desplegar junto con el server. Un breaking change abre `/api/v2` y deja v1 hasta que el front del TP2 deje de usarla.

---

## 3. Autenticación y autorización

El token se firma con `secret_key_base`, algoritmo **HS256** explícito y `exp` a 24 horas:

```7:21:app/services/json_web_token.rb
  def self.encode(payload, exp = 24.hours.from_now)
    payload = payload.dup
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY, "HS256")
  end

  def self.decode(token)
    body = JWT.decode(token, SECRET_KEY, true, algorithm: "HS256")[0]
    ActiveSupport::HashWithIndifferentAccess.new(body)
  rescue JWT::ExpiredSignature
    raise ExpiredSignature
  rescue JWT::DecodeError
    raise InvalidToken
  end
```

El concern distingue tres 401:

```10:20:app/controllers/concerns/jwt_authenticatable.rb
  def authenticate_api_user!
    token = bearer_token
    return render_error("token_missing", status: :unauthorized) if token.blank?

    payload = JsonWebToken.decode(token)
    @current_user = User.find_by(id: payload[:user_id])
    render_error("token_invalid", status: :unauthorized) unless @current_user
  rescue JsonWebToken::ExpiredSignature
    render_error("token_expired", status: :unauthorized)
  rescue JsonWebToken::InvalidToken
    render_error("token_invalid", status: :unauthorized)
  end
```

Hay spec de `token_expired` a las 25 horas (`users_spec.rb`). El header tiene que empezar con `Bearer `; otro esquema cae en `token_missing`.

No hay refresh token, no hay `jti`, no hay denylist y no hay `DELETE /login` ni `DELETE /session`. Logout en el cliente solo puede borrar el token local; el server lo acepta hasta `exp`. La API no permite cambiar la contraseña (`user_params` no incluye `password`), así que un cambio por Devise (HTML) tampoco invalida JWTs ya emitidos. No lo probé contra Devise en runtime.

No hay Pundit ni CanCan. La autorización está en el controller:

- Cualquier usuario autenticado crea partidos, se une y reporta.
- Solo un jugador activo marca `played` o reporta.
- Solo el autor borra su resultado, salvo `current_user.admin?` (403 si no).
- Roles `club_owner` no cambian nada en la API. El back-office es HTML con Devise (`devise :database_authenticatable, :registerable, :recoverable`). No hay `POST /api/v1/users` ni recuperación de contraseña en JSON.

Login: mismo texto `"Invalid credentials"` si el mail no existe o la contraseña falla (`sessions_controller.rb` líneas 6–16), alineado con Devise `paranoid` (`devise.rb` línea 93). El límite es **5 POST /api/v1/login por minuto por IP**. En Fly, el sexto POST con credenciales inválidas respondió **429** `{"error":"Too many requests. Please retry later."}`. No hay límite por cuenta: muchas IPs pueden probar la misma casilla.

**Lo que Fly hace hoy con el 401.** `GET /api/v1/profile` sin token respondió `{"error":"Unauthorized"}` sin `request_id`. Eso es `jwt_authenticatable.rb` de antes de `16c00ad`, no el concern citado arriba.

---

## 4. Validaciones y manejo de errores

Strong params están acotados. No se puede asignar `creator_id`, `status`, `email`, password ni roles por la API. El `team` de join no acepta `status` del cliente: `enroll` fuerza `confirmed`.

| Capa | Qué cubre |
|------|-----------|
| Controller | Presencia de `sets`, equipo en pairs, jugador activo, autor del reporte, creador que no puede irse, cortes de tiempo, formato de filtros |
| Modelo | Duración, día del time slot, cupo (4), equipo en pairs, score de set, unicidad de teléfono y de reporte |
| DB | Check `duration > 0 AND duration <= 240`, uniques de email/phone, `(match_id, user_id)`, `(match_id, reported_by_id)` |

`Api::V1::BaseController` fuerza locale `:en` (`force_english_locale`) y `config/locales/en.yml` tiene los mensajes de validación usados (`blank`, `taken`, `inclusion`, …). Los strings escritos a mano también están en inglés. El locale por defecto de la app sigue siendo `:es` (`application.rb` línea 37); no aplica a estos controllers.

404 de `RecordNotFound` es `"Not found"` más `request_id`. Leave, si no hay inscripción activa, lanza ese error a propósito (404, no 422).

`ParameterMissing` → 400 con `exception.message`. No hay spec que lo dispare. Login usa `permit`, no `require`: un body vacío es 401, no 400.

**Enums inválidos → 422 (cerrado 2026-09-26).** `validate: true` en los enums de `Match` (`status`, `roster_mode`, `join_policy`, `level_required`), `MatchPlayer` (`status`; `team` con `validate: { allow_nil: true }` para modo individual) y `Court` (`court_type`, `status`). Valores desconocidos en el POST de partido devuelven `errors` por campo. Specs en `matches_spec.rb`. `Match#status` y `level_required` comparten la clave simbólica `open` con valor `0` en ambos enums; no hay conflicto.

**Nota:** `MatchResult#winner_team` no es un enum de Active Record (se calcula desde los sets); no aplica `validate: true` ahí.

**`RecordNotUnique`.** Dos joins concurrentes del mismo usuario pueden chocar con el unique `(match_id, user_id)` entre el `find_by` y el `create!`. No hay `rescue_from`. Sería 500, no 422. No lo reproduje.

**500.** `config.exceptions_app = routes` y `ErrorsController < ActionController::API` lee `public/404.json`, `422.json` y `500.json`. Un error no capturado de la API responde JSON. El mismo controller también atiende los errores del admin HTML: una página del back-office que caiga en 500 responde JSON, no HTML. Logs de producción: STDOUT con tag `request_id`, nivel `info` por default. El stack no se filtra al cliente.

El 429 y el 403 de Fail2Ban no pasan por `render_error`, así que no llevan `request_id`. El header `x-request-id` sí viaja (visto en Fly).

---

## 5. Performance

No hay gem Bullet ni `EXPLAIN`. Esto es lectura del código, más dos tiempos observados en Fly.

**Listado de partidos (código actual).** `includes(:court, :creator, match_players: :user)` y el Jbuilder recorre `match.match_players.reject(&:cancelled?)`, o sea la asociación ya cargada, no `active_match_players` (que sigue siendo un `where` y haría otra query). El N+1 de roster que describía la auditoría anterior está cerrado en este árbol. En Fly el JSON del listado **no** trae `user.name`, así que ese host todavía renderiza el partial viejo, que además llamaba `active_match_players` dos veces por partido.

**Detalle.** `load_match_for_detail` precarga `match_results: :reported_by` y no precarga `match_sets`. El partial recorre `match_result.match_sets`. `consensus_result` vuelve a cargar resultados con `includes(:match_sets)`. Con como máximo un reporte por jugador el costo es chico (unas pocas queries extra por show, no por página).

**Canchas.** `Court.includes(:club)` está bien. `court.image.attached?` no usa `with_attached_image`: una query de Active Storage por cancha si hay blobs. En Fly las tres canchas no traían `image_url` (el partial solo lo agrega si hay attachment).

**Índices que sirven al listado.** `matches(status, date)`, `matches(date, court_id)`, `matches(creator_id)`, `match_players(user_id)`, unique `(match_id, user_id)`. El index público filtra por status y ordena por `date`; el compuesto `(status, date)` ya está en `db/schema.rb` línea 129.

**Paginación.** `per_page` limitado a 50 (`matches_controller.rb` líneas 215–218).

**Caché.** `GET /courts` usa `stale?(etag: @courts, public: true)` y hay spec de 304. El show de cancha no. No hay `Cache-Control` de aplicación en partidos. Solid Cache en producción es el backend de Rack::Attack (`production.rb` línea 50), no un cache de estos JSON. En Fly, `GET /api/v1/courts` trajo `etag` y `cache-control: max-age=0, private, must-revalidate`. Ese `private` es el default de Rails más `Rack::ETag` sobre el body; `stale?(public: true)` habría marcado la respuesta `public`. Otra señal de que el controller actual de canchas no es el que está sirviendo.

**Jobs.** El request hace cupo, consenso y stats de como máximo 4 jugadores en línea. Mail de bienvenida va con `deliver_later`. `AutoApproveResultsJob` está en cola. El DELETE de un reporte llama `PlayerStat.recalculate_for` en el request (historial completo del usuario). Aceptable para el volumen del TP; si el DELETE se vuelve lento, el candidato es un job, no cambiar la semántica de rachas.

**Payload.** El listado omite `time_slot`, resultados y consenso. El detalle los incluye. El roster del código actual trae `user.id` y `user.name`, sin email.

**Tiempos en Fly (una muestra, máquina que puede estar dormida).** `fly.toml` tiene `auto_stop_machines = "stop"` y `min_machines_running = 0`. El primer `GET /api/v1/courts` de la sesión tardó **7,4 s** (`x-runtime`); los siguientes requests de la misma pasada estuvieron entre **0,6 s y 1,3 s**. No es un benchmark. Sirve para decir que el cold start de la VM trial se nota.

---

## 6. Seguridad

Brakeman en 0 warnings y bundler-audit en 0 vulnerabilidades figuran en `AGENTS.md`. No los reejecuté. Esto es lo que el código y el host muestran además de eso.

| Control | Estado en el repo | Visto en Fly el 2026-09-26 |
|---------|-------------------|----------------------------|
| SQL crudo en `app/` | No aparece `find_by_sql` ni `where` con string interpolado | — |
| Mass assignment | `permit` corto; `creator` se setea en el server; spec de `email` ignorado | No probado (haría falta login real) |
| CORS | Orígenes por `CORS_ORIGINS`. Default `localhost:3001` y `localhost:5173`. Sin `*`, sin `credentials: true`. Solo `/api/*` | `Origin: http://localhost:3001` y `Origin: http://evil.example` **no** recibieron `Access-Control-Allow-Origin`. No pude leer el secret |
| Login throttle | 5/min/IP, con spec | El 6.º POST inválido → 429 |
| Escritura sin token | 20/min/IP si no hay header `Authorization` | No medido (no quise martillar el host) |
| Escritura con JWT válido | 30/min/usuario | No medido |
| Lectura anónima / autenticada | 60/min/IP y 100/min/usuario | No medido |
| Logs | `filter_parameters` incluye `:passw`, `:email`, `:token`, `:secret`. `:phone` no está | No vi logs de Fly |
| TLS | `force_ssl = true`; Fly `force_https = true` | `strict-transport-security: max-age=63072000; includeSubDomains` |
| Headers | No redefinidos en el repo; `load_defaults 8.1` | En `/up` y en la API: `x-frame-options: SAMEORIGIN`, `x-content-type-options: nosniff`, `referrer-policy: strict-origin-when-cross-origin`, `x-permitted-cross-domain-policies: none`, `x-xss-protection: 0` |
| CSP | `content_security_policy.rb` enforcing, con `unsafe_inline` en script y style | En `/api/v1/courts` y `/up` no vino `Content-Security-Policy`. En `/api-docs/index.html` vino la política de **Rswag UI** (`validator.swagger.io`, fonts de Google), no la del initializer |
| JWT | HS256 explícito, exp 24 h, secreto = `secret_key_base` | El 401 público sigue siendo el texto viejo `Unauthorized` |

**Escritura con Bearer inválido (cerrado 2026-09-26).** El throttle `write/ip` cuenta requests POST/PATCH/PUT/DELETE sin token **o** con token que no decodifica a un `user_id` (`user_id_from_token` → `nil`). El 21.º `POST /api/v1/matches` con `Bearer invalid` responde 429. `write/user` sigue contando solo tokens válidos.

**Lectura con Bearer inválido (cerrado 2026-09-26).** `read/ip` aplica el mismo criterio que `write/ip`: GET sin token o con token que no decodifica cuenta por IP (60/min). El 61.º `GET /api/v1/courts` con `Bearer invalid` → 429. `read/user` sigue contando solo JWT válidos.

**Fail2Ban (cerrado 2026-09-26).** Se eliminó el blocklist que miraba `match_type == :throttle` (imposible: blocklist corre antes que throttle). Cada 429 incrementa un contador por IP en el store de Rack::Attack; tras más de 10 throttles en 10 minutos se escribe `fail2ban:ban:<ip>` y el blocklist `block banned IPs` responde 403 hasta que expire el ban (1 h). Spec: 16 POST login en 429 → siguiente POST → 403.

**`CORS_ORIGINS` no está en `fly.toml`.** Sin esa variable, el código del repo cae a localhost. En el host, localhost tampoco recibió el header. Dos lecturas posibles, y no las pude separar sin el dashboard: el release es anterior a `rack-cors`, o el secret apunta a otro origen. Un browser en un origen no listado no puede llamar la API; curl sí.

**Active Storage** en producción es `:local` (`production.rb` línea 25, `storage.yml` disco `storage/`). `fly.toml` no declara `[mounts]`. Un blob subido por el admin no sobrevive a un restart de la VM. La API no sube imágenes. Hoy las canchas de Fly no tienen `image_url`.

**Host authorization** está comentada en `production.rb` (líneas 87–94). Detrás de Fly el riesgo es bajo. No lo probé con un `Host` falso.

No inspeccioné si Thruster imprime el header `Authorization` en su access log. El log de request de Rails no lo incluye en la línea estándar, y `:token` está filtrado en los parámetros.

---

## 7. Testing

Conteo por bloques `response(...)` de rswag en `spec/requests/api/v1/` (cada uno es un example de contrato). No reejecuté la suite.

| Archivo | `response` rswag | Examples extra en el mismo archivo |
|---------|------------------|-------------------------------------|
| `sessions_spec.rb` | 3 | — |
| `users_spec.rb` | 9 | 1 (`token_expired` a las 25 h; el caso también está dentro de rswag) |
| `courts_spec.rb` | 4 | 1 (304 con `If-None-Match`) |
| `matches_spec.rb` | 33 | 3 (cortes de join / leave / played) |
| `match_results_spec.rb` | 12 | — |
| **Total v1** | **61** | **5** |

Además: `spec/requests/rate_limiting_spec.rb` (9 examples: login 429, write sin token, Bearer inválido en POST y GET → 429, Fail2Ban 403, `/up`, OPTIONS) y `spec/requests/cors_spec.rb` (4: preflight permitido, GET con origen, sin `Origin`, origen rechazado).

Casi todos los `run_test!` assertan campos del JSON, no solo el status. Los creates comprueban el cambio en base.

| Status | Dónde está | Dónde no está |
|--------|------------|---------------|
| 200 / 201 | Happy paths de las 15 operaciones | — |
| 304 | `GET /courts` | El resto de los GET |
| 401 | Login, profile (missing / invalid / expired), create, join, leave, mine, played, report, destroy | — |
| 403 | Delete del resultado ajeno | No hay otro 403 de dominio |
| 404 | Court inactiva o inexistente, match, join, leave, results | — |
| 422 | Profile, create, join, leave, played, report, destroy en partido cerrado, cortes de tiempo | No hay spec de que un 422 de modelo y uno de negocio tengan formas distintas a propósito más allá de profile |
| 400 | Filtros `status`, `date`, `court_id`, `page`, `per_page` inválidos en el index de matches | `ParameterMissing`; `status=cancelled` en el listado público (sería 200) |
| 429 | Login y POST sin token | Throttles de lectura, write/user, y el blocklist |
| 500 | — | Enum inválido |

No hay un request spec que encadene login → crear → unirse → reportar en un solo example. Ese recorrido está en la colección Postman (20 requests, `docs/postman/README.md`). Las factories de usuario, cancha, partido y time slot alcanzan para los casos escritos. No hay factory review de esta auditoría más allá de ver que los specs las usan.

---

## 8. Documentación

Swagger cubre las **15 operaciones** (12 paths en `swagger/v1/swagger.yaml`: courts, courts/{id}, matches, matches/{id}, join, leave, played, me/matches, match_results GET+POST, match_results/{id} DELETE, login, profile GET+PATCH). `bearer_auth`, schemas `Error` y `UnauthorizedError` (`token_missing` / `token_invalid` / `token_expired`), y `servers` con `http://localhost:3000` y `https://ok-padel-tup.fly.dev`. `time_slot_id` y `phone` están en el YAML. Se regenera desde los mismos specs. Swagger UI no tiene basic auth; en este TP es aceptable. La UI en Fly respondió 200 en `/api-docs/index.html` (el `/api-docs` redirige 301).

El README tiene la tabla de los 15 endpoints, el contrato de paginación, las dos formas de error, curl de login, profile, courts, matches y results, y enlaza Postman. Con seed (`player@okpadel.local` / `password123`) y `docs/postman/README.md`, un dev nuevo consume la API **local** en pocos minutos.

Huecos:

- El README describe Fail2Ban; tras el fix de 2026-09-26 el comportamiento coincide con la doc (contador en el responder 429).
- El README no dice que `join_policy` y `level_required` no se aplican en `join`. `AGENTS.md` sí lo deja como deuda del Sprint 1.5.
- La doc describe el contrato de `main`. Fly, hoy, no lo cumple (401 opaco, filtro inválido en 200, roster sin nombre). Quien pruebe la URL pública contra el README va a ver diferencias.
- No verifiqué que `swagger.yaml` de Fly sea el del commit `47b762e`.

---

## 9. Estándares de la industria

| Práctica | JSON:API | Google AIP | Microsoft REST | Stripe | GitHub | Ok Padel (repo) |
|----------|----------|------------|----------------|--------|--------|-----------------|
| Versionado en URL | No lo exige | Major en path | Path o header | Path (`/v1`) | Path y header | `/api/v1` |
| Envoltorio | `{ data, type, id }` | Recurso | Recurso | Objeto de dominio | Objeto de dominio | `{ match: ... }` |
| Errores | `errors[]` + `source` | `google.rpc.Status` | `error.code` + `details` | `error.type`, `code`, `message` | `message` + `documentation_url` | string, o `unprocessable_entity` + `errors` |
| Paginación | `links` + `page[size]` | `page_size` / `page_token` | `nextLink` | cursor | `Link` | `page` + `meta` en dos listados |
| Auth | — | OAuth | Bearer | Bearer, API key | Bearer + scopes | Bearer JWT 24 h |
| Idempotencia | — | — | — | `Idempotency-Key` | — | No |
| Custom actions | Relaciones | `:join` | POST de acción | `POST /v1/.../capture` | Rutas propias | `join`, `leave`, `played` |

Convenciones que ya siguen y conviene conservar: URL versioning, sustantivos en plural, verbos HTTP correctos, 401 vs 403, Bearer, paginación con metadatos en los dos listados grandes, códigos de token distintos, y validaciones por campo.

Lo que se puede adoptar sin reescribir clientes actuales:

1. **Un solo sobre de error**, con `code` estable y `message` humano: `{ "error": { "code": "too_late_to_join", "message": "..." }, "request_id": "..." }`. Acerca el contrato a Stripe/GitHub. Hoy el front tiene que mirar si `error` es una frase, un código de token, o el literal `unprocessable_entity`.
2. **400 también cuando `status` es un enum que este listado no acepta**, no solo cuando el string es desconocido.
3. ~~**Enums inválidos → 422**~~ — `validate: true` en modelos de dominio expuestos por la API (`Match`, `MatchPlayer`, `Court`).
4. Dejar JSON:API, cursores e `Idempotency-Key` para una v2. En 15 endpoints no pagan el costo. La idempotencia importaría si crear un partido pasara a cobrar la cancha.

---

## 10. Mejoras priorizadas

| Pri | Tipo | Mejora | Impacto | Esfuerzo | Archivos |
|-----|------|--------|---------|----------|----------|
| P0 | 🔴 | Redesplegar Fly con `main` (`47b762e` o posterior). El host público responde el contrato previo a `16c00ad`: 401 `Unauthorized` sin `request_id`, filtro inválido en 200, roster sin `user.name`. Quien evalúe la URL no está viendo esta API | Alto | S | `fly.toml` / pipeline de deploy. No es un cambio de código |
| P1 | 🟡 | Access token corto + refresh, o denylist en logout y al cambiar la contraseña en Devise. Hoy el JWT vive 24 h y no se puede invalidar | Alto | L | `json_web_token.rb`, `jwt_authenticatable.rb`, `sessions_controller.rb`, tabla o Solid Cache |
| P1 | ✅ | ~~Contar por IP escrituras con Bearer inválido~~ | — | — | **Hecho 2026-09-26** — `rack_attack.rb`, `rate_limiting_spec.rb` |
| P1 | ✅ | ~~GET con Bearer inválido sin throttle~~ | — | — | **Hecho 2026-09-26** — `read/ip`, `rate_limiting_spec.rb` |
| P1 | ✅ | ~~Enums inválidos → 500~~ | — | — | **Hecho 2026-09-26** — `validate: true` en `Match` / `MatchPlayer` / `Court` |
| P1 | 🟡 | Hacer cumplir `join_policy` (`manual`, `auto_by_level`) y `level_required` en `join`, o dejar de aceptarlos en el POST hasta que existan. Hoy se persisten y el roster entra `confirmed` igual | Alto (contrato) | M | `matches_controller.rb`, `match_player.rb`, specs. Deuda ya anotada en `AGENTS.md` |
| P1 | 🟡 | Registro y reset de contraseña en JSON, si el cliente del TP2 no va a usar los forms HTML de Devise | Alto si hay SPA | M | rutas `api/v1`, mailers ya existentes |
| P1 | 🟡 | Fijar `CORS_ORIGINS` en Fly con el origen real del front y volver a medir el header. En el host, `localhost:3001` no lo recibió | Alto si hay SPA en otro origen | S | secret de Fly, `config/initializers/cors.rb` |
| P2 | ✅ | ~~Fail2Ban que cuente 429 de verdad~~ | — | — | **Hecho 2026-09-26** — `rack_attack.rb`, `rate_limiting_spec.rb` |
| P2 | 🟡 | Unificar el 422 de negocio (`"too late to join"`) con el 422 de modelo (`errors` por campo), en un solo idioma y un solo código | Medio | M | `base_controller.rb`, controllers de matches y results, specs, README |
| P2 | 🟡 | `status` del listado público fuera de `open`/`full` → 400, no 200 vacío | Medio | S | `matches_controller.rb`, `matches_spec.rb` |
| P2 | 🟡 | `rescue_from ActiveRecord::RecordNotUnique` → 422 en join | Medio | S | `base_controller.rb` o `enroll` |
| P2 | 🟡 | Precargar `match_sets` en el detalle y `with_attached_image` en canchas | Medio | S | `matches_controller.rb`, `match_results_controller.rb`, `courts_controller.rb` |
| P2 | 🟡 | Active Storage fuera del disco local de la VM el día que las canchas tengan foto | Medio | M | `production.rb`, `storage.yml`, volumen o S3 |
| P2 | 🟡 | Transferir o bloquear al creador que sale de un partido `open`/`full` con jugadores restantes (`creator_id` queda en alguien que ya no está) | Medio | M | `matches_controller.rb`, `match.rb`. Deuda Sprint 1.5 |
| P2 | 🟡 | Mover `PlayerStat.recalculate_for` a un job si el DELETE de reportes se mide lento | Medio | M | `match_result.rb`, Solid Queue. Deuda ya documentada |
| P2 | 🟢 | Specs que faltan: `team` inválido en join, `status=cancelled` en el index público, origen CORS del secret de prod | Medio | S | `spec/requests/` |
| P3 | 🟢 | `request_id` también en el JSON de 429 (el header `x-request-id` ya existe) | Bajo | S | `rack_attack.rb` |
| P3 | 🟢 | Filtrar `:phone` en los logs | Bajo | S | `filter_parameter_logging.rb` |
| P3 | 🟢 | ETag en `GET /courts/:id` (el index ya lo tiene en el repo) | Bajo | S | `courts_controller.rb` |
| P3 | 🟢 | `config.hosts` en producción | Bajo | S | `production.rb` |
| P3 | 🟢 | Paginación de canchas y de resultados cuando el volumen deje de ser el de un club | Bajo | M | controllers y Jbuilder |

No hay un P0 de seguridad en el código de `main`: no queda abierta la API a mass assignment, SQL injection, CORS `*` ni un JWT sin firma. El P0 de esta lista es de **despliegue**: la URL que se presenta no sirve el código que se documenta.

---

## Anexos

### Error base y 422 estructurado

```15:44:app/controllers/api/v1/base_controller.rb
      def render_error(message, status:)
        render json: {
          error: message,
          request_id: request.request_id
        }, status: status
      end
      # ...
      def render_record_errors(record)
        render json: {
          error: "unprocessable_entity",
          errors: record.errors.to_hash,
          request_id: request.request_id
        }, status: :unprocessable_content
      end
```

### Tope de página

```215:218:app/controllers/api/v1/matches_controller.rb
      def api_per_page
        value = params.fetch(:per_page, 20).to_i
        value = 20 if value < 1
        [ value, 50 ].min
      end
```

### Throttle que ignora un Bearer presente e inválido

```25:41:config/initializers/rack_attack.rb
  throttle("write/user", limit: 30, period: 1.minute) do |req|
    if req.post? || req.patch? || req.put? || req.delete?
      token = req.env["HTTP_AUTHORIZATION"]&.split(" ")&.last
      next nil if token.blank?

      user_id_from_token(token)
    end
  end

  throttle("write/ip", limit: 20, period: 1.minute) do |req|
    if (req.post? || req.patch? || req.put? || req.delete?) &&
       req.env["HTTP_AUTHORIZATION"].blank?
      req.ip
    end
  end
```

### Join que no lee la política

```25:28:app/models/match_player.rb
  def self.enroll(match:, user:, **attributes)
    attributes = attributes.symbolize_keys
    attributes[:status] ||= :confirmed
```

### Referencias

- [JSON:API](https://jsonapi.org/)
- [Google API Design Guide](https://cloud.google.com/apis/design)
- [Microsoft REST API Guidelines](https://github.com/microsoft/api-guidelines)
- [Stripe API errors](https://docs.stripe.com/api/errors)
- [GitHub API versions](https://docs.github.com/en/rest/about-the-rest-api/api-versions)
- Contrato local: `README.md` sección API v1, `swagger/v1/swagger.yaml`, `docs/postman/README.md`
- Auditoría anterior (árbol previo a `16c00ad`): `docs/api-audit.md`

### Qué se verificó y qué no

Verificado:

- Lectura de controllers, Jbuilder, modelos, schema, specs, swagger, README, Rack::Attack 6.8.0 y el orden `safelist → blocklist → throttle`.
- `Match.new(join_policy: "nope")` → `ArgumentError` en este árbol.
- Fly, 2026-09-26: `/up` 200 con HSTS y headers de Rails; `GET /api/v1/courts` 200 con 3 canchas; `GET /api/v1/matches?status=nope` **200** lista vacía; `GET /api/v1/matches?per_page=1` con `join_policy: "auto"` y roster **sin** `user`; `GET /api/v1/profile` sin token → `{"error":"Unauthorized"}`; `GET /api/v1/matches/999999` → `{"error":"Not found"}` sin `request_id`; 6.º login inválido → 429; CORS de localhost y de un origen externo sin `Access-Control-Allow-Origin`; `/api-docs/index.html` 200 con la CSP de Rswag.

No verificado:

- Suite completa, Brakeman, Bullet, `EXPLAIN`.
- SHA exacto desplegado en Fly (`git ls-remote` contra GitHub respondió “repository not found” desde este entorno; el repo es privado).
- Valor de `CORS_ORIGINS` y de los logs en el dashboard de Fly.
- POST autenticado con `team` inválido en join (enum validado en modelo, sin request spec dedicado).
- Carrera de `RecordNotUnique`.
- Overflow de Pagy.
- Si Thruster loguea `Authorization`.

---

## Resumen final

Conteos según la tabla de la sección 10 (un ítem = una fila):

- 🔴 Críticos (P0): **1** — Fly sirve un contrato anterior a `main`
- 🟡 Alto impacto (P1): **4** — JWT no revocable, `join_policy` / `level_required` que no se aplican en join, sin registro JSON, CORS del host (Fly sin redeploy)
- 🟢 Medio impacto (P2): **7** — 422 con dos formas, filtro `cancelled` en 200, `RecordNotUnique`, precarga de sets/imágenes, blobs en disco local, creador que sale sin transferir el partido, recálculo de stats en el request, specs/docs de huecos restantes
- ⚪ Bajo impacto (P3): **5** — `request_id` en el 429, phone en logs, ETag del show de cancha, `config.hosts`, paginación de listados chicos

Fortalezas principales:

- Quince endpoints con verbos, status y envoltorios consistentes, strong params cerrados y el creador asignado en el server.
- JWT HS256 con expiración, tres códigos de 401, login que no revela si el mail existe, y throttle de login que en Fly sí responde 429.
- Documentación usable en local: OpenAPI generado desde 61 responses rswag, README con curl y colección Postman de 20 requests.
- Headers de producción reales: HSTS, `nosniff`, `SAMEORIGIN`, `Referrer-Policy`.

Áreas de mejora principales:

- La URL pública no está alineada con `main`. Hasta un redeploy, la auditoría del repo y la demo de Fly son dos APIs.
- La sesión no se cierra en el server.
- El contrato promete `join_policy` y `level_required`, y el `join` los ignora (valores de enum mal escritos ya devuelven 422 en create).
