# Flujo Spec Kit — Ok Padel (backend)

Este repositorio tiene [Spec Kit](https://github.com/github/spec-kit) (`specify init` v1.2.5) con integración Cursor. La gobernanza está en [`.specify/memory/constitution.md`](../.specify/memory/constitution.md).

## Cuándo usar este repo para Spec Kit

| Tipo de feature | Dónde correr Speckit |
|-----------------|----------------------|
| Solo API / admin / jobs | **ok_padel** (este repo) |
| Full-stack (API + app Angular) | **ok_padel** — spec principal en `specs/NNN-nombre/` |
| Solo UI sin cambio de contrato | **tup--padel-match-** (ver su `docs/speckit-workflow.md`) |

En full-stack: contratos en `specs/NNN-*/contracts/`; el frontend referencia esa ruta y la misma **rama git acordada** en ambos repos.

## Comandos (orden recomendado)

1. `/speckit-specify` — descripción de la feature → `specs/NNN-nombre/spec.md`
2. `/speckit-clarify` — si quedan `[NEEDS CLARIFICATION]`
3. `/speckit-plan` — `plan.md`, `research.md`, `data-model.md`, `contracts/`
4. `/speckit-analyze` — consistencia spec / plan / constitution
5. `/speckit-tasks` — `tasks.md`
6. `/speckit-checklist` — opcional, calidad de requisitos
7. `/speckit-implement` — ejecutar tareas (Agent mode)
8. `/speckit-converge` — cerrar brechas spec vs código

El puntero a la feature activa es `.specify/feature.json` (local, gitignored).

## Git multi-repo

- No crear ni cambiar ramas sin acuerdo explícito (nombre + base en **ambos** repos).
- Commits y push los hace el humano salvo pedido explícito al agente.

## Quality gates (backend)

Al cerrar la feature:

```bash
bundle exec rspec
bundle exec rubocop
bundle exec brakeman -q
bundle exec bundler-audit check
```

Si cambió `/api/v1`:

```bash
bundle exec rake rswag:specs:swaggerize
```

## Templates

Overrides del proyecto (no editar `.specify/templates/*.md` core):

- `.specify/templates/overrides/spec-template.md`
- `.specify/templates/overrides/plan-template.md`
- `.specify/templates/overrides/tasks-template.md`

Verificar resolución:

```bash
.specify/scripts/bash/resolve-template.sh plan-template --json
```
