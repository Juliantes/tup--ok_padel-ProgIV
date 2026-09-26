# Ok Padel

Aplicación web para gestionar clubes, canchas y partidos de pádel. TP1 de Programación IV: back-office administrativo y API JSON para la app de jugadores.

![CI](https://img.shields.io/github/actions/workflow/status/Juliantes/tup--ok_padel-ProgIV/ci.yml?branch=main&label=CI)
![Ruby](https://img.shields.io/badge/Ruby-3.4.10-red)
![Rails](https://img.shields.io/badge/Rails-8.1.3-red)
![License](https://img.shields.io/github/license/Juliantes/tup--ok_padel-ProgIV)

## Descripción del proyecto

**Ok Padel** es una plataforma orientada a clubes y jugadores: reserva de canchas, armado de partidos, niveles, reseñas y estadísticas. La temática del trabajo práctico es el ecosistema real de un club de pádel (gestión + experiencia del jugador).

**Alcance del TP1 (esta entrega):**

- **Back-office** (`/admin`): CRUD de clubes, canchas y usuarios; consulta/edición de partidos y gestión de jugadores en el roster (sin alta/baja de partidos desde admin).
- **API REST JSON** (`/api/v1`): login con JWT, perfil, canchas activas, partidos (listado, detalle, alta, join/leave, mis partidos, marcar jugado) y **resultados** (listar reportes, reportar, borrar el propio).
- **Web pública:** home, registro e inicio de sesión con Devise.
- **Emails:** mail de bienvenida al registrarse (`UserMailer#welcome`).

Wireframes y flujos de pantalla: [docs/wireframe/](docs/wireframe/) (HTML interactivo y PNGs).

El modelo incluye entidades para **TP2** (mensajes, reseñas, etc.): migradas y seedeadas donde aplica, pero **sin API ni pantallas** en esta entrega. Los **resultados de partido** y **stats** sí forman parte del TP1 (API + admin).

## Stack tecnológico

| Tecnología | Versión | Uso |
|------------|---------|-----|
| Ruby | 3.4.10 | Lenguaje |
| Rails | 8.1.3 | Framework web |
| PostgreSQL | 14+ (CI: 16) | Base de datos |
| Puma | (Gemfile) | Servidor HTTP |
| Hotwire (Turbo + Stimulus) | — | Interacción web |
| Bootstrap | — | UI back-office y web |
| Devise | — | Autenticación web (sesión) |
| JWT (`jwt` gem) | — | Autenticación API |
| Jbuilder | — | Serialización JSON |
| Solid Queue | — | Cola de jobs (mail async) |
| Solid Cache / Solid Cable | — | Cache y Action Cable en producción |
| Propshaft + importmap | — | Assets JS |
| Pagy | — | Paginación en admin |
| Active Storage | — | Avatares y fotos de canchas |
| RSpec, FactoryBot, Faker, Shoulda | — | Tests |
| rswag (rswag-api, rswag-ui, rswag-specs) | — | OpenAPI / Swagger UI (`/api-docs`) |
| RuboCop (omakase), Brakeman, bundler-audit | — | Calidad y seguridad |
| Fly.io | — | Deploy en producción (`fly.toml`) |
| letter_opener | — | Preview de mails en desarrollo |

## Requisitos previos

- **Ruby 3.4.10** (ver `.ruby-version`)
- **PostgreSQL 14+** en ejecución
- **Bundler**
- **(Opcional)** [Fly CLI](https://fly.io/docs/flyctl/install/) para deploy a Fly.io

## Instalación paso a paso

```bash
# 1. Clonar
git clone https://github.com/Juliantes/tup--ok_padel-ProgIV.git
cd tup--ok_padel-ProgIV

# 2. Dependencias
bundle install

# 3. Base de datos (ver nota debajo sobre variables de entorno)

# 4. Credenciales Rails (si aún no tenés master.key)
# bin/rails credentials:edit  # requiere config/master.key

# 5. Crear y migrar
bin/rails db:prepare

# 6. Datos demo
bin/rails db:seed

# 7. Servidor
bin/rails s
```

> **⚠️ Configuración de base de datos:** `config/database.yml` lee las credenciales desde variables de entorno. Para desarrollo local:
>
> ```bash
> export DATABASE_PASSWORD=tu_password_local
> ```
>
> O usá `DATABASE_URL`:
>
> ```bash
> export DATABASE_URL="postgres://postgres:tu_password@localhost:5432/ok_padel_development"
> ```

**Jobs en desarrollo:** `development` usa **Solid Queue** (`config.active_job.queue_adapter = :solid_queue`). No hay `Procfile.dev`. Para procesar mails encolados con `deliver_later`, tareas recurrentes (`config/recurring.yml`) y otros jobs, en **otra terminal**:

```bash
bin/jobs
```

Sin el worker, los jobs quedan en cola hasta que ejecutes `bin/jobs` o uses `perform_now` / `deliver_now` en consola.

### Publicar en GitHub (primera vez)

Si el repositorio remoto aún no existe, desde la raíz del proyecto (con [GitHub CLI](https://cli.github.com/) autenticado):

```bash
gh auth login
gh repo create ok_padel --public --source=. --remote=origin --push
```

Remoto configurado: `https://github.com/Juliantes/tup--ok_padel-ProgIV.git`. Si usás otro usuario u organización, actualizá `git remote set-url origin …` y los badges del encabezado.

## Variables de entorno

| Variable | Entorno | Uso |
|----------|---------|-----|
| `DATABASE_USERNAME` | dev / test | Usuario de PostgreSQL (default: `postgres`) |
| `DATABASE_PASSWORD` | dev / test | Password de PostgreSQL (default: vacío) |
| `DATABASE_HOST` | dev / test | Host de PostgreSQL (default: `localhost`) |
| `DATABASE_PORT` | dev / test | Puerto de PostgreSQL (default: `5432`) |
| `DATABASE_URL` | CI / production (Fly) | URL completa de PostgreSQL (Neon en producción) |
| `RAILS_MASTER_KEY` | production (Fly) | Descifra `config/credentials.yml.enc` |
| `APP_HOST` | production | Host público para links en mails (default: `okpadel.example`) |
| `MAILER_FROM` | todos | Remitente (default: `Ok Padel <no-reply@okpadel.local>`) |
| `MAILER_REPLY_TO` | todos | Reply-To (default: `soporte@okpadel.local`) |
| `MAILER_LOGO_URL` | todos | URL absoluta del logo en el layout HTML del mail (opcional) |
| `SMTP_*` | production | SMTP real (ver sección Emails) |
| `RAILS_MAX_THREADS` | opcional | Pool de conexiones (default 5) |
| `AUTO_APPROVE_AFTER_HOURS` | opcional | Horas sin reportes nuevos antes de auto-cerrar un partido en disputa (default: `48`) |
| `JOIN_CUTOFF_HOURS` | opcional | Mínimo de horas antes del inicio para unirse a un partido con `time_slot` (default: `1`) |
| `LEAVE_CUTOFF_HOURS` | opcional | Mínimo de horas antes del inicio para salir de un partido con `time_slot` (default: `2`) |
| `PLAYED_CUTOFF_HOURS` | opcional | Máximo de horas antes del inicio para marcar `played` con `time_slot` (default: `24`) |
| `CORS_ORIGINS` | opcional | Orígenes permitidos para CORS (CSV). Default en dev: `http://localhost:3001,http://localhost:5173`. En producción: dominio(s) del front-end, p. ej. `https://okpadel.com,https://www.okpadel.com` |

## CORS y rate limiting

El front-end externo (otro origen) consume la API con **JWT en header** (sin cookies). CORS y límites de abuso están activos en todos los entornos.

### CORS (`rack-cors`)

- Configuración: `config/initializers/cors.rb`.
- Rutas: `/api/*` (métodos GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD).
- Orígenes: variable `CORS_ORIGINS` (lista separada por comas). Si no está definida, se usan `http://localhost:3001` y `http://localhost:5173`.
- Headers expuestos al navegador: `Authorization`, `Retry-After`.
- No se usa `credentials: true` ni `origins "*"`.

Verificar con curl:

```bash
curl -i -H "Origin: http://localhost:3001" http://localhost:3000/api/v1/courts
```

Deberías ver `Access-Control-Allow-Origin: http://localhost:3001` en la respuesta.

### Rate limiting (`rack-attack`)

- Configuración: `config/initializers/rack_attack.rb`.
- **Backend de contadores:** `Rails.cache` (Solid Cache en producción; `memory_store` en desarrollo). No se requiere Redis.
- **Safelist:** `GET /up` (health check) y peticiones `OPTIONS` (preflight CORS).
- **Límites (por minuto):**
  - `POST /api/v1/login`: 5 por IP.
  - Escritura sin token o con Bearer inválido (POST/PATCH/PUT/DELETE): 20 por IP.
  - Escritura autenticada (JWT válido): 30 por usuario.
  - Lectura sin token o con Bearer inválido (GET): 60 por IP.
  - Lectura autenticada (GET con JWT válido): 100 por usuario.
- Tras muchos 429, Fail2Ban puede bloquear la IP 1 hora (10 throttles en 10 minutos).
- Respuesta **429:** JSON `{ "error": "Too many requests. Please retry later." }` y header `Retry-After` (segundos hasta el próximo bucket).

Probar el límite de login:

```bash
for i in $(seq 1 6); do
  curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:3000/api/v1/login \
    -H "Content-Type: application/json" \
    -d '{"email":"x@y.com","password":"wrong"}'
done
```

El sexto código debería ser `429`.

## Auto-aprobación de resultados

Si un partido queda en estado **reported** (disputa sin consenso estricto), `AutoApproveResultsJob` puede cerrarlo automáticamente cuando el **último reporte** supera el umbral configurado.

- **Umbral:** `ENV["AUTO_APPROVE_AFTER_HOURS"]` (default `48`).
- **Ganador:** mayoría simple entre firmas de sets (`set_signature`); empate → grupo con el reporte más antiguo.
- **Stats:** se aplican una vez vía `apply_stats_from!` (igual que el consenso manual).
- **Marca:** `matches.auto_approved_at`; en admin aparece el badge **Auto**.
- **Tras auto-aprobación:** no se admiten reportes nuevos (`Match result is finalized`).

El job está programado en `config/recurring.yml` (**cada hora**, en `development` y `production`). Requiere el worker:

```bash
bin/jobs
```

Prueba manual en consola:

```bash
bin/rails runner "AutoApproveResultsJob.perform_now"
```

## Credenciales de acceso (seeds)

Contraseña común de demo: **`password123`**

| Rol | Email | Acceso web |
|-----|-------|------------|
| Admin (back-office) | admin@okpadel.local | `/admin` (solo rol `admin`) |
| Dueño de club | owner@okpadel.local | `/` — login Devise; **no** tiene acceso a `/admin` |
| Jugador | player@okpadel.local | `/` |
| Jugador 2 | player2@okpadel.local | `/` |
| Jugador 3 | player3@okpadel.local | `/` |
| Jugador 4 | player4@okpadel.local | `/` |

**Enlaces útiles (desarrollo):**

| Recurso | URL |
|---------|-----|
| Back-office | http://localhost:3000/admin |
| Login | http://localhost:3000/users/sign_in |
| Registro | http://localhost:3000/users/sign_up |
| Home | http://localhost:3000/ |
| Health check | http://localhost:3000/up |

### Autenticación: web vs API

| Canal | Mecanismo | Uso |
|-------|-----------|-----|
| Web | Devise (cookie de sesión) | Registro, login, home, admin |
| API | JWT en header `Authorization: Bearer <token>` | Cliente JSON (app móvil / SPA) |

El token JWT expira a las **24 horas** (`JsonWebToken.encode`, claim `exp`).

## Modelo de datos

Diagrama de entidades del dominio (TP1 + modelado para evolución del TP):

```mermaid
erDiagram
  User ||--o{ UserRole : has
  User ||--o| PlayerStat : has
  User ||--o{ Club : owns
  User ||--o{ Match : creates
  User ||--o{ MatchPlayer : plays
  User ||--o{ Review : writes
  User ||--o{ Review : receives
  User ||--o{ Message : sends
  User ||--o{ Message : receives
  Club ||--o{ Court : has
  Court ||--o{ TimeSlot : has
  Court ||--o{ Match : hosts
  Match ||--o{ MatchPlayer : roster
  Match ||--o| MatchResult : result
  Match ||--o{ Review : context
  Match ||--o{ Message : chat
  TimeSlot ||--o{ Match : schedules

  User {
    bigint id PK
    string email
    string name
    string phone
    int self_level
    decimal average_level
    decimal average_stars
    text bio
  }
  UserRole {
    bigint user_id FK
    string role
  }
  Club {
    bigint owner_id FK
    string name
    string address
    string phone
    string email
  }
  Court {
    bigint club_id FK
    string name
    int court_type
    decimal price_per_hour
    int status
  }
  TimeSlot {
    bigint court_id FK
    int day_of_week
    time start_time
    time end_time
    boolean is_available
  }
  Match {
    bigint court_id FK
    bigint creator_id FK
    bigint time_slot_id FK
    datetime date
    int duration
    int status
    int level_required
    int roster_mode
  }
  MatchPlayer {
    bigint match_id FK
    bigint user_id FK
    int team
    int status
    bigint approved_by_id FK
    datetime joined_at
    datetime cancelled_at
  }
  MatchResult {
    bigint match_id FK
    bigint reported_by_id FK
    boolean forced_by_admin
  }
  MatchSet {
    bigint match_result_id FK
    int order
    int team_a_games
    int team_b_games
  }
  Review {
    bigint reviewer_id FK
    bigint reviewed_user_id FK
    bigint match_id FK
    int level_rating
    int stars
    text comment
  }
  Message {
    bigint sender_id FK
    bigint receiver_id FK
    bigint match_id FK
    text content
    boolean is_group_chat
  }
  PlayerStat {
    bigint user_id FK
    int wins
    int losses
    int current_streak
    int best_streak
    decimal win_rate
  }
```

**Active Storage:** `User` → `has_one_attached :avatar`; `Court` → `has_one_attached :image`.

**Resumen por entidad:**

- **User** — Cuenta Devise; nivel declarado, promedios y bio; contadores de partidos.
- **UserRole** — Roles: `admin`, `player`, `club_owner` (un usuario puede tener varios).
- **Club** — Club de pádel; pertenece a un `club_owner`.
- **Court** — Cancha (indoor/outdoor), precio/hora y estado (`active` / etc.).
- **TimeSlot** — Franja horaria recurrente por día de semana en una cancha.
- **Match** — Partido en fecha/cancha; nivel requerido y modo de roster.
- **MatchPlayer** — Inscripción al partido, equipo, estado y aprobaciones.
- **MatchResult** — Reporte de resultado de un jugador (varios por partido; consenso por mayoría de firmas de sets).
- **MatchSet** — Marcador de un set dentro de un reporte (`order`, games por equipo).
- **Review** — Reseña post-partido (TP2).
- **Message** — Mensajería entre jugadores / chat de partido (TP2).
- **PlayerStat** — Victorias, rachas y win rate. Se actualizan una sola vez al alcanzar consenso.

## Documentación de la API (Swagger)

**Extra del TP1 (sección 4):** documentación OpenAPI generada con [rswag](https://github.com/rswag/rswag) a partir de los request specs.

- **UI interactiva:** con el servidor en marcha, abrí [http://localhost:3000/api-docs](http://localhost:3000/api-docs).
- **Especificación:** `swagger/v1/swagger.yaml` (versionada en el repo).
- **Regenerar** tras cambiar los bloques `path` / `response` en `spec/requests/api/v1/*_spec.rb`:

  ```bash
  bundle exec rake rswag:specs:swaggerize
  ```

Los 15 endpoints de `api/v1` están documentados con schemas alineados a los Jbuilder de `app/views/api/v1/`.

## API v1

**Postman:** colección en [`postman/`](postman/) (20 requests con tests; 15 operaciones en OpenAPI). En Desktop, abrí la **raíz del repo** clonado (p. ej. `tup--ok_padel-ProgIV`) y usá **Run collection**; por terminal: `bin/postman-run` (Newman). Guía: [docs/postman/README.md](docs/postman/README.md).

Base URL en desarrollo: `http://localhost:3000`

**Autenticación:** header `Authorization: Bearer <token>` en endpoints protegidos.

**Login:** `POST /api/v1/login` con JSON `{ "email", "password" }` → `{ "token", "user" }`.

**Errores:** cuerpo `{ "error": "<mensaje>", "request_id": "<uuid>" }` con el status HTTP correspondiente (`request_id` en respuestas que usan `render_error` del API base). Los mensajes de la API están en **inglés** (`Invalid credentials`, `Not found`, etc.). Un `401` de autenticación JWT usa un código: `token_missing` (sin header `Authorization: Bearer`), `token_invalid` (no decodifica o el usuario no existe) o `token_expired`. Filtros inválidos en `GET /api/v1/matches` → `400` (`invalid status`, `invalid date format`, etc.).

**Validaciones (`422`):** cuando falla `ActiveRecord` (crear partido, join con cupo lleno, `PATCH /profile`, etc.) el cuerpo es `{ "error": "unprocessable_entity", "errors": { "<campo>": ["mensaje", ...] }, "request_id": "..." }`. Los mensajes en `errors` van en inglés. Errores de negocio puntuales (p. ej. `too late to join`) siguen usando solo `error` con un string.

### Endpoints

| Método | Path | Auth | Descripción |
|--------|------|------|-------------|
| POST | `/api/v1/login` | No | Login; devuelve JWT y usuario |
| GET | `/api/v1/profile` | Sí | Perfil del usuario autenticado |
| PATCH | `/api/v1/profile` | Sí | Actualizar `name`, `phone`, `self_level`, `bio` |
| GET | `/api/v1/courts` | No | Listar canchas **activas** |
| GET | `/api/v1/courts/:id` | No | Detalle de cancha activa |
| GET | `/api/v1/matches` | No | Listar partidos **open/full** (filtros y paginación) |
| GET | `/api/v1/matches/:id` | No | Detalle de partido |
| POST | `/api/v1/matches` | Sí | Crear partido (`auto_join` opcional, default `true`) |
| POST | `/api/v1/matches/:id/join` | Sí | Unirse al partido |
| DELETE | `/api/v1/matches/:id/leave` | Sí | Salir del partido (soft delete) |
| POST | `/api/v1/matches/:id/played` | Sí | Marcar el partido como jugado sin resultado (jugador activo) |
| GET | `/api/v1/matches/:match_id/match_results` | No | Reportes del partido y consenso |
| POST | `/api/v1/matches/:match_id/match_results` | Sí | Reportar resultado (jugador activo) |
| DELETE | `/api/v1/matches/:match_id/match_results/:id` | Sí | Borrar el propio reporte |
| GET | `/api/v1/me/matches` | Sí | Partidos del usuario (inscripto o creador) |

**Paginación (listados de partidos):** query `page` (default 1), `per_page` (default 20, máx. 50). Respuesta incluye `meta` con `current_page`, `per_page`, `total_pages`, `total_count`. La API v1 incluye `Pagy::Method` en `Api::V1::BaseController` (misma API que el back-office: `pagy(:offset, ...)`).

### Ejemplos

#### POST `/api/v1/login`

```bash
curl -s -X POST http://localhost:3000/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"email":"player@okpadel.local","password":"password123"}'
```

Respuesta `200`:

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 3,
    "name": "Jugador Demo",
    "email": "player@okpadel.local",
    "phone": "1100000003",
    "self_level": 4,
    "category_label": "4ta",
    "bio": "Jugador de prueba",
    "average_level": "0.0",
    "average_stars": "0.0",
    "matches_played": 0
  }
}
```

Errores: `401` → `{ "error": "Invalid credentials" }`; credenciales ausentes → `400` (parameter missing).

#### GET `/api/v1/profile`

```bash
TOKEN="<jwt>"
curl -s http://localhost:3000/api/v1/profile \
  -H "Authorization: Bearer $TOKEN"
```

Respuesta `200`:

```json
{
  "user": {
    "id": 3,
    "name": "Jugador Demo",
    "email": "player@okpadel.local",
    "phone": "1100000003",
    "self_level": 4,
    "category_label": "4ta",
    "bio": "Jugador de prueba",
    "average_level": "0.0",
    "average_stars": "0.0",
    "matches_played": 0
  }
}
```

Errores: `401` → `{ "error": "token_missing" }`, `{ "error": "token_invalid" }` o `{ "error": "token_expired" }`.

#### PATCH `/api/v1/profile`

```bash
curl -s -X PATCH http://localhost:3000/api/v1/profile \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Jugador Actualizado","bio":"Nueva bio"}'
```

Respuesta `200`: mismo shape que GET profile.

Errores: `422` → `{ "error": "unprocessable_entity", "errors": { "self_level": ["is not included in the list"] }, "request_id": "..." }`; `401` sin auth.

#### GET `/api/v1/courts`

```bash
curl -s http://localhost:3000/api/v1/courts
```

Respuesta `200`:

```json
{
  "courts": [
    {
      "id": 1,
      "name": "Cancha 1",
      "description": "Indoor · Césped sintético",
      "court_type": "indoor",
      "price_per_hour": 8000.0,
      "status": "active",
      "club": {
        "id": 1,
        "name": "Ok Padel Club",
        "address": "Av. Siempre Viva 742, Buenos Aires"
      }
    }
  ]
}
```

(`image_url` aparece solo si la cancha tiene imagen adjunta.)

#### GET `/api/v1/courts/:id`

```bash
curl -s http://localhost:3000/api/v1/courts/1
```

Respuesta `200`: objeto `{ "court": { ... } }` con el mismo partial que en el listado.

Errores: `404` → `{ "error": "Not found" }` (id inexistente o cancha no activa).

#### POST `/api/v1/matches`

Usá una `date` **futura** (el ejemplo asume que corrés el curl antes de diciembre de 2026).

```bash
TOKEN="<jwt>"
curl -s -X POST http://localhost:3000/api/v1/matches \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "court_id": 1,
    "date": "2026-12-15T10:00:00-03:00",
    "duration": 90,
    "roster_mode": "pairs",
    "level_required": "fifth",
    "auto_join": true
  }'
```

Respuesta `201`:

```json
{
  "match": {
    "id": 1,
    "date": "2026-12-15T10:00:00.000-03:00",
    "duration": 90,
    "status": "open",
    "roster_mode": "pairs",
    "level_required": "fifth",
    "join_policy": "auto",
    "court": { "id": 1, "name": "Cancha 1", "club_id": 1 },
    "creator": { "id": 3, "name": "Jugador Demo" },
    "match_players": [
      {
        "id": 1,
        "user_id": 3,
        "team": "team_a",
        "status": "confirmed",
        "joined_at": "2026-09-20T12:00:00.000-03:00",
        "user": { "id": 3, "name": "Jugador Demo" }
      }
    ],
    "players_count": 1,
    "max_players": 4,
    "time_slot": null,
    "match_results": [],
    "consensus": null
  }
}
```

Errores: `401` sin auth; `422` validaciones del modelo (`error` + `errors` por campo).

**Ventanas de tiempo** (solo si el partido tiene `time_slot`; sin slot no aplican): no se puede `join` con menos de **1 h** al inicio (`too late to join`); no se puede `leave` con menos de **2 h** (`too late to leave`); no se puede `played` con más de **24 h** de anticipación (`too early to mark as played`). Opcional: `JOIN_CUTOFF_HOURS`, `LEAVE_CUTOFF_HOURS`, `PLAYED_CUTOFF_HOURS`.

El detalle (`show_details`) ya no incluye `match_result` (objeto o `null`). Pasa a `match_results` (array) y `consensus` (`null` si no hay mayoría).

### Sistema de resultados

Cada jugador activo puede cargar un marcador. El partido guarda **varios** `match_results` (único por `match_id` + `reported_by_id`).

**Consenso**

- 1 reporte: consenso **provisorio**. El partido pasa a `completed` y se aplican las stats.
- 2 o más: hace falta **mayoría estricta** (más del 50% de reportes con la misma firma de sets, p. ej. `6-4,6-4`).
- Sin mayoría: el partido queda en `reported`. Ahí el jugador puede reemplazar su reporte.
- Con consenso ya cerrado (`completed`): no se puede volver a reportar el mismo marcador.
- Un partido válido requiere sets completos según `matches.best_of` (3 o 5); el ganador se calcula de los sets reportados.
- Al cerrar consenso se aplican stats de forma incremental (`matches.stats_applied_at`). Si un jugador **borra** su reporte (`DELETE` propio, según reglas de estado), se ejecuta `PlayerStat.recalculate_for` para los jugadores del partido: wins, losses y rachas se **recalculan** desde el historial de partidos `completed`, no con un simple deshacer del último incremento.

**Marcar como jugado:** `POST /api/v1/matches/:id/played` pasa el partido a `completed` sin marcador. Responde `422` si ya está `completed` **y** hay consenso.

Si el índice único de reportes falla por datos viejos duplicados: `bin/rails db:reset`.

#### POST `/api/v1/matches/:id/match_results`

```bash
TOKEN="<jwt>"
curl -s -X POST http://localhost:3000/api/v1/matches/1/match_results \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"sets":[{"team_a_games":6,"team_b_games":4},{"team_a_games":6,"team_b_games":4}]}'
```

Respuesta `201`:

```json
{
  "match": {
    "id": 1,
    "status": "completed",
    "match_results": [
      {
        "id": 10,
        "sets": [
          { "order": 1, "team_a_games": 6, "team_b_games": 4 },
          { "order": 2, "team_a_games": 6, "team_b_games": 4 }
        ],
        "winner_team": "team_a",
        "reported_by": { "id": 3, "name": "Jugador Demo" },
        "created_at": "2026-09-22T20:00:00-03:00"
      }
    ],
    "consensus": {
      "signature": "6-4,6-4",
      "votes": 1,
      "total": 1,
      "sets": [
        { "order": 1, "team_a_games": 6, "team_b_games": 4 },
        { "order": 2, "team_a_games": 6, "team_b_games": 4 }
      ]
    }
  },
  "results": [
    {
      "id": 10,
      "sets": [
        { "order": 1, "team_a_games": 6, "team_b_games": 4 },
        { "order": 2, "team_a_games": 6, "team_b_games": 4 }
      ],
      "winner_team": "team_a",
      "reported_by": { "id": 3, "name": "Jugador Demo" },
      "created_at": "2026-09-22T20:00:00-03:00"
    }
  ],
  "consensus": {
    "signature": "6-4,6-4",
    "votes": 1,
    "total": 1,
    "sets": [
      { "order": 1, "team_a_games": 6, "team_b_games": 4 },
      { "order": 2, "team_a_games": 6, "team_b_games": 4 }
    ]
  }
}
```

Errores: `401` sin auth; `422` sin `sets` (`sets is required`), si quien reporta no es jugador activo (`Reporter is not an active player`), sets inválidos (validación del modelo) o ya reportó sin disputa (`You already reported a result`).

`GET /api/v1/matches/:id/match_results` es público y responde `{ "results", "consensus", "total" }`.

`DELETE` solo borra el reporte propio: `403` si es de otro, `404` si no existe.

## Back-office

- **URL:** `/admin`
- **Acceso:** usuarios con rol **`admin`** (`User#admin?`). Otros roles (p. ej. `club_owner`) usan la web pública pero **no** entran al back-office.
- **Autenticación:** Devise (sesión web).
- **Layout:** `admin.html.erb` con Bootstrap.
- **Paginación:** Pagy en listados.

**Funcionalidad:**

| Recurso | Operaciones |
|---------|-------------|
| Clubs | CRUD completo |
| Courts | CRUD completo |
| Time Slots | CRUD completo (anidado bajo Court) |
| Users | CRUD completo |
| Matches | Index, show, edit, update; forzar resultado; marcar jugado sin resultado |
| Match players | Alta/baja en roster (anidado bajo match) |
| Match results | Editar y borrar reportes (anidado bajo match; listado en show del partido) |

**Match results management** (en el detalle del partido, `/admin/matches/:id`):

- Ver todos los reportes de jugadores, consenso provisional o disputa.
- Editar o borrar un reporte individual.
- **Force result:** el admin fija el marcador oficial (`forced_by_admin`), cierra el partido y aplica estadísticas sin esperar consenso.
- **Mark as played (no result):** completa el partido sin marcador ni stats.

## Emails

### Desarrollo

En `development`, Action Mailer usa **letter_opener**: al registrarse un usuario, el mail de bienvenida se encola con `deliver_later` y, al procesarse el job (`bin/jobs`), se abre en una pestaña del navegador (no se envía por SMTP real).

**Disparo:** callback `after_create_commit :send_welcome_email` en `User` → `UserMailer.welcome(self).deliver_later`.

### Probar manualmente

```ruby
bin/rails c
UserMailer.welcome(User.last).deliver_now
```

Para encolado asíncrono: `UserMailer.welcome(User.last).deliver_later` y ejecutar `bin/jobs` en otra terminal.

### Variables de entorno (mail)

| Variable | Uso |
|----------|-----|
| `APP_HOST` | Host público en producción para links en mails (default: `okpadel.example`) |
| `MAILER_FROM` | Remitente (default: `Ok Padel <no-reply@okpadel.local>`) |
| `MAILER_REPLY_TO` | Reply-To (default: `soporte@okpadel.local`) |
| `MAILER_LOGO_URL` | URL absoluta del logo en el layout HTML (opcional; si no está, no se muestra imagen) |
| `SMTP_ADDRESS` | Servidor SMTP (opcional, producción) |
| `SMTP_PORT` | Puerto SMTP (opcional, default sugerido `587`) |
| `SMTP_USERNAME` | Usuario SMTP (opcional) |
| `SMTP_PASSWORD` | Contraseña SMTP (opcional) |
| `SMTP_DOMAIN` | Dominio HELO (opcional) |
| `SMTP_AUTHENTICATION` | Mecanismo de auth, p. ej. `plain` (opcional) |

Logo de ejemplo:

```bash
MAILER_LOGO_URL=https://tu-host/assets/logo.png
```

### Producción (SMTP)

En `config/environments/production.rb` están comentados `delivery_method :smtp` y `smtp_settings` leyendo las variables anteriores. Descomentá ambos bloques y configurá las ENV en el servidor para enviar correo real. Los mails usan `default_url_options` con `APP_HOST` y `https`.

### Seeds y mails

`db:seed` crea usuarios y dispara el mail de bienvenida en cada alta. Para silenciar entregas durante seeds:

```ruby
ActionMailer::Base.perform_deliveries = false
# ... crear usuarios ...
ActionMailer::Base.perform_deliveries = true
```

**TP2 (planificado):** mail de confirmación de partido (`MatchMailer`) — ver [AGENTS.md](AGENTS.md).

## Testing

```bash
bundle exec rspec
```

- **344 examples, 0 failures** (misma suite que CI)
- Cobertura: modelos, requests (API, admin, Devise, CORS, rate limiting), mailers, jobs
- CI: GitHub Actions en cada push/PR a `main` (job `test` con PostgreSQL 16 y `DATABASE_URL`)

## Calidad y seguridad

Comandos locales:

```bash
bundle exec rubocop                # estilo (0 offenses objetivo)
bundle exec brakeman -q            # análisis estático Rails (0 warnings objetivo)
bundle exec bundler-audit check    # vulnerabilidades en gems
bin/importmap audit                # auditoría JS (importmap)
```

**CI (`.github/workflows/ci.yml`):**

| Job | Qué ejecuta |
|-----|-------------|
| `scan_ruby` | `bin/brakeman`, `bin/bundler-audit` |
| `scan_js` | `bin/importmap audit` |
| `test` | `bin/rails db:test:prepare`, `bundle exec rspec` |
| `lint` | `bin/rubocop -f github` |

## Deploy

**URL de producción:** https://ok-padel-tup.fly.dev

> ⚠️ **Nota:** el deploy actual está en el plan **trial** de Fly.io (sin tarjeta de crédito). La URL puede dejar de responder cuando el trial se agote (2h de VM o 7 días, lo que pase primero).
>
> **Alternativas si la URL deja de responder:**
> - Redeployar en Fly: `fly deploy -a ok-padel-tup` (requiere cuenta con crédito).
> - Migrar a Render (free tier real, se duerme pero no cobra).
> - Local + ngrok.

La app corre en **Fly.io** (región `gru`) con imagen Docker del `Dockerfile`, proceso **web** (`bin/thrust` en `:8080` → Puma en `:3000`) y **worker** (`bin/jobs` para Solid Queue y jobs recurrentes). En cada deploy, `release_command` ejecuta `bin/rails db:prepare` (migraciones primary + Solid).

`config/deploy.yml` (Kamal) queda como referencia histórica; no se usa en el deploy actual.

### Secretos y variables en Fly

Configurar antes del primer deploy (no commitear valores):

| Variable | Uso |
|----------|-----|
| `DATABASE_URL` | Connection string de Neon (pooled o directo) |
| `RAILS_MASTER_KEY` | Contenido de `config/master.key` |
| `APP_HOST` | Host público para mails y URLs (p. ej. `ok-padel-tup.fly.dev`) |
| `CORS_ORIGINS` | Orígenes del front-end (CSV) |
| `AUTO_APPROVE_AFTER_HOURS` | Umbral de auto-aprobación de resultados (opcional; default `48`) |

Opcional: `MAILER_*`, `SMTP_*` (ver sección Emails).

```bash
fly secrets set DATABASE_URL="..." RAILS_MASTER_KEY="..." APP_HOST="ok-padel-tup.fly.dev" CORS_ORIGINS="..." -a ok-padel-tup
```

### Deploy y operación

```bash
fly deploy -a ok-padel-tup
```

Tras el primer deploy, escalar web y worker (Solid Queue requiere el proceso `worker`):

```bash
fly scale count web=1 worker=1 -a ok-padel-tup
```

Comandos útiles:

```bash
fly logs -a ok-padel-tup
fly status -a ok-padel-tup
fly ssh console -a ok-padel-tup
fly secrets list -a ok-padel-tup
```

**Seeds en producción (una vez):**

```bash
fly ssh console -a ok-padel-tup -C "bin/rails db:seed"
```

Validar configuración local: `fly config validate`.

Documentación: [fly.io/docs](https://fly.io/docs/).

## Estructura del proyecto

```
app/
  controllers/
    admin/           # back-office
    api/v1/          # API JSON
    concerns/        # JwtAuthenticatable
  models/
    concerns/        # PlayerCategory, PhoneValidatable, ImageAttachable
  mailers/
  views/
    admin/
    api/v1/          # Jbuilder
    layouts/
  services/          # JsonWebToken
config/
  locales/           # es, devise.es, mailers.es
  environments/
  deploy.yml         # Kamal (referencia histórica)
fly.toml             # Fly.io (producción)
db/
  migrate/
  seeds.rb
spec/
  models/, requests/, mailers/
docs/
  wireframe/
  postman/           # guía Postman Desktop / Newman
postman/             # colección YAML + JSON y environment
```

## Documentación adicional

- [AGENTS.md](AGENTS.md) — contexto para agentes de IA y deuda técnica (p. ej. MatchMailer TP2)
- [docs/postman/README.md](docs/postman/README.md) — Postman Desktop, Collection Runner y `bin/postman-run`
- [docs/wireframe/](docs/wireframe/) — wireframes (`ok-padel-wireframe.html`, PNGs de flujos)
- [`docs/auditoria-api-v1.md`](docs/auditoria-api-v1.md) — Auditoría completa de la API v1

## Licencia

[MIT](LICENSE) © 2026 Juliantes

## Autor

Juliantes — TP1 Programación IV — TUP 2026

Saludos
