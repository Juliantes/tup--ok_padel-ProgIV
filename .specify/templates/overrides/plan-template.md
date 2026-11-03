# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]

**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command; its definition describes the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

**Language/Version**: Ruby 3.4.10, Rails 8.1.3

**Primary Dependencies**: Devise, JWT, Jbuilder, Solid Queue, Solid Cache, rack-cors, rack-attack, rswag

**Storage**: PostgreSQL (Neon en producción vía `DATABASE_URL`)

**Testing**: RSpec (models, requests, jobs, mailers); rswag en `spec/requests/api/v1/`; factories en `spec/factories/`

**Target Platform**: Fly.io (procesos `web` + `worker`), desarrollo local Puma

**Project Type**: web-service (API JSON `/api/v1`) + admin Hotwire

**Performance Goals**: [domain-specific or N/A for this feature]

**Constraints**: Sin breaking changes en contratos Swagger sin acuerdo; HTTP 422 → `:unprocessable_content`; CORS vía `CORS_ORIGINS`

**Scale/Scope**: [feature-specific]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [ ] **I. Contrato API**: ¿Hay endpoints nuevos/cambiados? → Jbuilder + request spec rswag + regenerar `swagger/v1/swagger.yaml`
- [ ] **II. Tests**: ¿Qué request/model/job/mailer specs se agregan o actualizan?
- [ ] **III. Alcance**: ¿El plan evita refactors fuera de la feature?
- [ ] **IV. Seguridad**: ¿Secrets solo vía ENV? ¿Auth/rate limit considerados?
- [ ] **V. Multi-repo**: ¿Se documenta impacto en `tup--padel-match-` si aplica?

## Frontend impact (tup--padel-match-)

Completar solo si la feature expone o cambia contrato API o flujos compartidos:

| Área | Rutas / archivos previstos | Notas |
|------|---------------------------|-------|
| Pantallas | `src/app/...` | [list or N/A] |
| Servicios API | `src/app/core/api/...` | [list or N/A] |
| i18n | `public/i18n/` | [keys or N/A] |

**Frontend spec link**: [N/A o ruta relativa al otro repo / mismo nombre de rama acordado]

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
└── tasks.md             # /speckit-tasks (no lo crea /speckit-plan)
```

### Source Code (repository root)

```text
app/
├── models/
├── controllers/api/v1/
├── views/api/v1/          # Jbuilder
├── jobs/
├── mailers/
└── services/              # si aplica

spec/
├── requests/api/v1/
├── models/
├── jobs/
├── mailers/
└── swagger_helper.rb

swagger/v1/swagger.yaml
db/migrate/                # si aplica
config/routes.rb
docs/                      # si aplica auditoría API
```

**Structure Decision**: Rails monolith Ok Padel; serialización JSON vía Jbuilder; documentación OpenAPI vía rswag.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| | | |
