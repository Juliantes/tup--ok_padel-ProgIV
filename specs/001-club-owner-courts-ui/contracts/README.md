# Contracts: 001-club-owner-courts-ui

Contratos **canónicos** deben replicarse en `ok_padel/specs/001-club-owner-courts-ui/contracts/` y en Swagger (`bundle exec rake rswag:specs:swaggerize`) cuando se implemente el backend.

## Ya disponibles (consumir sin cambios)

| Método | Ruta | Uso |
|--------|------|-----|
| GET | `/api/v1/clubs` | Listar clubes del dueño |
| GET/POST/PATCH/DELETE | `/api/v1/clubs/:id` | Club (si se usa alta club en UI) |
| GET/POST/PATCH/DELETE | `/api/v1/clubs/:club_id/courts` (+ `:id`) | ABM canchas |
| GET | `/api/v1/clubs/:id/schedule?date=YYYY-MM-DD` | Grilla |

Auth: JWT + rol `club_owner`; errores JSON vía `api-errors.ts`.

## Propuestos (bloquean P3–P4 UI)

Ver [`api-v1-owner-courts-extension.md`](./api-v1-owner-courts-extension.md).

## UI (comportamiento)

Ver [`ui-club-owner-screen.md`](./ui-club-owner-screen.md).
