---

description: "Task list template for feature implementation (Ok Padel API)"
---

# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Tests are **REQUIRED** per constitution principle II — include request/model (and job/mailer) specs for every behavior introduced or changed.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Models**: `app/models/`, specs in `spec/models/`
- **API**: `app/controllers/api/v1/`, views `app/views/api/v1/`, specs `spec/requests/api/v1/`
- **Jobs/Mailers**: `app/jobs/`, `app/mailers/`, specs en `spec/jobs/`, `spec/mailers/`
- **Migrations**: `db/migrate/`
- **OpenAPI**: `swagger/v1/swagger.yaml` vía `bundle exec rake rswag:specs:swaggerize`
- **Frontend (otro repo)**: documentar en tasks como `tup--padel-match-/src/app/...` cuando aplique

<!--
  ============================================================================
  IMPORTANT: The tasks below are SAMPLE TASKS for illustration purposes only.

  The /speckit-tasks command MUST replace these with actual tasks based on:
  - User stories from spec.md (with their priorities P1, P2, P3...)
  - Feature requirements from plan.md
  - Entities from data-model.md
  - Endpoints from contracts/

  DO NOT keep these sample tasks in the generated tasks.md file.
  ============================================================================
-->

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create project structure per implementation plan
- [ ] T002 [P] Migrations/schema per data-model.md in `db/migrate/`
- [ ] T003 [P] Routes in `config/routes.rb` if new API surface

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T004 Shared model changes / concerns in `app/models/`
- [ ] T005 [P] Base request spec helpers or shared examples if needed
- [ ] T006 Authorization/policy hooks for API if applicable

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - [Title] (Priority: P1) 🎯 MVP

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 1 (REQUIRED — write first, expect RED)

- [ ] T010 [P] [US1] Request spec in `spec/requests/api/v1/...` with rswag blocks
- [ ] T011 [P] [US1] Model spec in `spec/models/...` for validations/callbacks

### Implementation for User Story 1

- [ ] T012 [US1] Model(s) in `app/models/`
- [ ] T013 [US1] Controller action(s) in `app/controllers/api/v1/`
- [ ] T014 [US1] Jbuilder views in `app/views/api/v1/`
- [ ] T015 [US1] Jobs/mailers if applicable

**Checkpoint**: User Story 1 fully functional; request specs green

---

## Phase 4: User Story 2 - [Title] (Priority: P2)

**Goal**: [Brief description]

**Independent Test**: [How to verify]

### Tests for User Story 2 (REQUIRED)

- [ ] T018 [P] [US2] Request/model specs for US2

### Implementation for User Story 2

- [ ] T020 [US2] Implementation paths per plan.md

**Checkpoint**: User Stories 1 AND 2 independently testable

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Quality gates and documentation (constitution)

- [ ] TXXX [P] Update `docs/` or `AGENTS.md` deuda if new debt introduced
- [ ] TXXX Regenerate OpenAPI if API changed: `bundle exec rake rswag:specs:swaggerize`
- [ ] TXXX Run `bundle exec rspec`
- [ ] TXXX Run `bundle exec rubocop`
- [ ] TXXX Run `bundle exec brakeman -q`
- [ ] TXXX Run `bundle exec bundler-audit check`
- [ ] TXXX Validate `quickstart.md` scenarios if present

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories
- **User Stories (Phase 3+)**: Depend on Foundational; prefer P1 → P2 → P3
- **Polish (Final Phase)**: After desired user stories complete

### Within Each User Story

- Tests MUST be written and FAIL before implementation when feasible
- Models before controllers; controllers before swagger regenerate
- Commit after logical groups (user runs git)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to user story for traceability
- Avoid vague tasks and same-file conflicts across parallel [P] tasks
