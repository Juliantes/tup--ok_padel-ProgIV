# Ok Padel

Aplicación web para gestionar clubes, canchas y partidos de pádel. TP1 de Programación IV: back-office administrativo y API JSON para la app de jugadores.

![CI](https://img.shields.io/github/actions/workflow/status/Juliantes/ok_padel/ci.yml?branch=main&label=CI)
![Ruby](https://img.shields.io/badge/Ruby-3.4.10-red)
![Rails](https://img.shields.io/badge/Rails-8.1.3-red)
![License](https://img.shields.io/github/license/Juliantes/ok_padel)

## Descripción del proyecto

**Ok Padel** es una plataforma orientada a clubes y jugadores: reserva de canchas, armado de partidos, niveles, reseñas y estadísticas. La temática del trabajo práctico es el ecosistema real de un club de pádel (gestión + experiencia del jugador).

**Alcance del TP1 (esta entrega):**

- **Back-office** (`/admin`): CRUD de clubes, canchas y usuarios; consulta/edición de partidos y gestión de jugadores en el roster (sin alta/baja de partidos desde admin).
- **API REST JSON** (`/api/v1`): login con JWT, perfil del jugador, canchas activas y partidos (listado, detalle, alta, join/leave, mis partidos).
- **Web pública:** home, registro e inicio de sesión con Devise.
- **Emails:** mail de bienvenida al registrarse (`UserMailer#welcome`).

Wireframes y flujos de pantalla: [docs/wireframe/](docs/wireframe/) (HTML interactivo y PNGs).

El modelo de datos incluye entidades previstas para **TP2** (mensajes, reseñas, resultados, etc.); en TP1 están migradas, seedeadas donde aplica, pero **sin endpoints API ni pantallas** para la mayoría de ellas.

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
| RuboCop (omakase), Brakeman, bundler-audit | — | Calidad y seguridad |
| Kamal | — | Deploy containerizado (preparado) |
| letter_opener | — | Preview de mails en desarrollo |

## Requisitos previos

- **Ruby 3.4.10** (ver `.ruby-version`)
- **PostgreSQL 14+** en ejecución
- **Bundler**
- **(Opcional)** Docker y acceso a un registry para deploy con Kamal

## Instalación paso a paso

```bash
# 1. Clonar
git clone https://github.com/Juliantes/ok_padel.git
cd ok_padel

# 2. Dependencias
bundle install

# 3. Base de datos
# Ajustá config/database.yml según tu usuario/host de PostgreSQL
# o exportá DATABASE_URL (recomendado; mismo criterio que en CI):
# export DATABASE_URL="postgres://postgres:postgres@localhost:5432/ok_padel_development"

# 4. Credenciales Rails (si aún no tenés master.key)
# bin/rails credentials:edit  # requiere config/master.key

# 5. Crear y migrar
bin/rails db:prepare

# 6. Datos demo
bin/rails db:seed

# 7. Servidor
bin/rails s
```

**Jobs en desarrollo:** no hay `Procfile.dev`. Para procesar mails encolados con `deliver_later` (bienvenida, etc.), en **otra terminal**:

```bash
bin/jobs
```

Sin el worker, los jobs quedan en cola hasta que ejecutes `bin/jobs` o uses `deliver_now` en consola.

### Publicar en GitHub (primera vez)

Si el repositorio remoto aún no existe, desde la raíz del proyecto (con [GitHub CLI](https://cli.github.com/) autenticado):

```bash
gh auth login
gh repo create ok_padel --public --source=. --remote=origin --push
```

Remoto configurado: `https://github.com/Juliantes/ok_padel.git`. Si usás otro usuario u organización, actualizá `git remote set-url origin …` y los badges del encabezado.

## Variables de entorno

| Variable | Entorno | Uso |
|----------|---------|-----|
| `DATABASE_URL` | dev / test / CI | Conexión PostgreSQL (sobreescribe partes de `database.yml`) |
| `OK_PADEL_DATABASE_PASSWORD` | production | Password del rol `ok_padel` en `config/database.yml` |
| `RAILS_MASTER_KEY` | production / Kamal | Descifra `config/credentials.yml.enc` |
| `APP_HOST` | production | Host público para links en mails (default: `okpadel.example`) |
| `MAILER_FROM` | todos | Remitente (default: `Ok Padel <no-reply@okpadel.local>`) |
| `MAILER_REPLY_TO` | todos | Reply-To (default: `soporte@okpadel.local`) |
| `MAILER_LOGO_URL` | todos | URL absoluta del logo en el layout HTML del mail (opcional) |
| `SMTP_*` | production | SMTP real (ver sección Emails) |
| `KAMAL_REGISTRY_PASSWORD` | deploy | Token/password del registry Docker |
| `RAILS_MAX_THREADS` | opcional | Pool de conexiones (default 5) |

> **Nota:** en el repo, `config/database.yml` puede tener credenciales locales hardcodeadas. Para clones nuevos, preferí `DATABASE_URL` o editá el archivo sin commitear secretos reales.

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
    bigint approved_by_id FK
    int team_a_score
    int team_b_score
    int winner_team
    int status
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
- **MatchResult** — Resultado reportado y aprobado (TP2).
- **Review** — Reseña post-partido (TP2).
- **Message** — Mensajería entre jugadores / chat de partido (TP2).
- **PlayerStat** — Victorias, rachas y win rate (TP2).

## API v1

Base URL en desarrollo: `http://localhost:3000`

**Autenticación:** header `Authorization: Bearer <token>` en endpoints protegidos.

**Login:** `POST /api/v1/login` con JSON `{ "email", "password" }` → `{ "token", "user" }`.

**Errores:** cuerpo `{ "error": "<mensaje>" }` con el status HTTP correspondiente. Los mensajes de la API están en **inglés** (`Unauthorized`, `Invalid credentials`, `Not found`, etc.).

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

Errores: `401` → `{ "error": "Unauthorized" }` (sin token, token inválido o expirado).

#### PATCH `/api/v1/profile`

```bash
curl -s -X PATCH http://localhost:3000/api/v1/profile \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Jugador Actualizado","bio":"Nueva bio"}'
```

Respuesta `200`: mismo shape que GET profile.

Errores: `422` → `{ "error": "..." }` (validaciones); `401` sin auth.

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

```bash
TOKEN="<jwt>"
curl -s -X POST http://localhost:3000/api/v1/matches \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "court_id": 1,
    "date": "2026-09-25T10:00:00-03:00",
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
    "date": "2026-09-25T10:00:00.000-03:00",
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
        "joined_at": "2026-09-20T12:00:00.000-03:00"
      }
    ],
    "players_count": 1,
    "max_players": 4,
    "time_slot": null,
    "match_result": null
  }
}
```

Errores: `401` sin auth; `422` validaciones del modelo.

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
| Users | CRUD completo |
| Matches | Index, show, edit, update |
| Match players | Alta/baja en roster (anidado bajo match) |

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

- **161 examples, 0 failures**
- Cobertura: modelos, requests (API, admin, Devise), mailers
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

## Deploy con Kamal

**Estado:** configuración **preparada**, deploy **no realizado** (IP placeholder `192.168.0.1` en `config/deploy.yml`).

**TODO antes del primer deploy:**

1. Reemplazar `192.168.0.1` por IP/host real del servidor.
2. Configurar `registry` (Docker Hub, GHCR, etc.) y `KAMAL_REGISTRY_PASSWORD`.
3. Definir secretos: `RAILS_MASTER_KEY`, `OK_PADEL_DATABASE_PASSWORD` (y accesorios DB si aplica).
4. Revisar `SOLID_QUEUE_IN_PUMA` y workers según carga.

```bash
bin/kamal deploy
```

Documentación: [kamal-deploy.org](https://kamal-deploy.org).

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
  deploy.yml         # Kamal
db/
  migrate/
  seeds.rb
spec/
  models/, requests/, mailers/
docs/
  wireframe/
```

## Documentación adicional

- [AGENTS.md](AGENTS.md) — contexto para agentes de IA y deuda técnica (p. ej. MatchMailer TP2)
- [docs/wireframe/](docs/wireframe/) — wireframes (`ok-padel-wireframe.html`, PNGs de flujos)

## Licencia

[MIT](LICENSE) © 2026 Juliantes

## Autor

Juliantes — TP1 Programación IV — TUP 2026
