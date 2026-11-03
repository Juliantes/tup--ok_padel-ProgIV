# Ok Padel API Constitution

## Core Principles

### I. Contrato API primero

Todo cambio bajo `/api/v1` debe mantener coherencia entre Jbuilder, request specs y OpenAPI (rswag). Cada endpoint nuevo o modificado se documenta en `spec/requests/api/v1/` con bloques rswag y se regenera `swagger/v1/swagger.yaml` con `bundle exec rake rswag:specs:swaggerize`. No se rompen contratos documentados sin acuerdo explícito y plan de migración.

### II. Tests obligatorios (NON-NEGOTIABLE)

Request specs para endpoints; model specs para validaciones, scopes y callbacks relevantes; specs de jobs y mailers cuando el flujo los dispare. Respuestas de validación HTTP 422 usan `:unprocessable_content` en controllers y `:unprocessable_content` en specs. Los tests deben fallar antes de la implementación cuando el flujo lo permita (red-green-refactor).

### III. Alcance mínimo y deuda explícita

Diffs pequeños y enfocados en la feature; sin refactors colaterales no pedidos. Deuda técnica nueva se registra en `AGENTS.md` con contexto suficiente para retomarla después.

### IV. Seguridad y configuración

Sin secretos ni credenciales en el repositorio; configuración vía variables de entorno (`config/database.yml`, mailers, CORS, etc.). Endpoints bajo `/api/*` heredan CORS (`rack-cors`) y rate limiting (`rack-attack`). Devise en modo `paranoid` donde aplique. Jobs de correo preferentemente con `deliver_later` (Solid Queue).

### V. Multi-repo y git

El workspace incluye `tup--padel-match-` (Angular). En features full-stack, el spec principal vive en **este repo** (`specs/NNN-*` con `contracts/`). No crear ni cambiar ramas sin acuerdo explícito con el equipo. El agente no ejecuta `git commit` ni `git push` salvo pedido explícito del usuario.

## Additional Constraints

Stack: Ruby 3.4.10, Rails 8.1.3, PostgreSQL, Puma, JWT + Devise, Solid Queue/Cache/Cable en producción. Admin Hotwire + API JSON para la app de jugadores. Referencia operativa detallada: `AGENTS.md` y `README.md`.

## Development Workflow

Flujo Spec Kit recomendado: `/speckit-specify` → `/speckit-clarify` (si hay `[NEEDS CLARIFICATION]`) → `/speckit-plan` → `/speckit-analyze` → `/speckit-tasks` → `/speckit-checklist` (opcional) → `/speckit-implement` → `/speckit-converge`. Guía: `docs/speckit-workflow.md`.

**Quality gates al cerrar una feature** (obligatorios):

- `bundle exec rspec`
- `bundle exec rubocop`
- `bundle exec brakeman -q`
- `bundle exec bundler-audit check`

Si cambió el contrato API: regenerar Swagger como en el principio I.

## Governance

Esta constitution prevalece sobre plantillas genéricas de Spec Kit. Enmiendas requieren actualizar este archivo, incrementar versión semver en el pie y mencionar el cambio en el PR. `AGENTS.md` complementa reglas operativas (mailers, deploy, deuda planificada) y no se duplica aquí salvo principios.

**Version**: 1.0.0 | **Ratified**: 2026-11-03 | **Last Amended**: 2026-11-03
