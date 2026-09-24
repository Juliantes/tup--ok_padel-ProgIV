# Guía para agentes — Ok Padel

## Mailers

- **Base:** `ApplicationMailer` define `from` / `reply_to` vía `ENV` (`MAILER_FROM`, `MAILER_REPLY_TO`) con fallbacks locales, layout `mailer` (HTML + texto) e helper `app_url` para armar URLs con `action_mailer.default_url_options`.
- **i18n:** textos en `config/locales/mailers.es.yml` bajo `es.mailers.<mailer>.<acción>`. Los mails de dominio usan `I18n.with_locale(:es)`.
- **Convención:** `<Entidad>Mailer#<acción>` → vistas en `app/views/<entidad>_mailer/<acción>.{html,text}.erb`.
- **Disparo:** preferir `deliver_later` (en producción, `ActionMailer::MailDeliveryJob` sobre **solid_queue**; en desarrollo, adapter por defecto de Active Job).
- **Logo:** el layout HTML muestra el logo solo si `Rails.application.config.x.mailer_logo_url` está definido (`MAILER_LOGO_URL` en `config/initializers/mailer.rb`).

### Deuda técnica planificada — Parte 2 (MatchMailer)

1. Crear `app/mailers/match_mailer.rb` heredando de `ApplicationMailer`.
2. Implementar acción `match_confirmed` (u equivalente al evento de negocio acordado).
3. Completar claves en `config/locales/mailers.es.yml` → `mailers.match_mailer.match_confirmed` (hoy placeholder / TODO).
4. Agregar `app/views/match_mailer/match_confirmed.html.erb` y `.text.erb` reutilizando layout e i18n.
5. Disparar el mail desde el flujo de confirmación de partido (callback o hook existente), con `deliver_later`.
6. Añadir `spec/mailers/match_mailer_spec.rb` (mismo nivel que `user_mailer_spec.rb`).
7. Documentar en README (sección Emails) el nuevo mail y variables si aplica.
8. Verificar cola/jobs en producción y no romper contratos `api/v1`.

## Deuda planificada — TimeSlots

1. **Soft-delete:** considerar agregar `deleted_at` + scope `.kept` +
   `soft_delete!` + `restore!`. Aplica a admin, API de matches
   (jbuilder `time_slot`), seeds y front-end TP2. Actualmente el delete
   es hard delete con `dependent: :nullify` (los partidos pierden la
   referencia al slot pero siguen existiendo con su `date` y `duration`).
2. **Validación de solapamiento:** evitar dos time_slots de la misma
   cancha el mismo día con horarios superpuestos. Actualmente el modelo
   solo valida `end_time > start_time`.

### Deuda planificada — Sprint 1.5 (API matches avanzada)

1. **`join_policy`:** migración y enum en `Match` (`auto`, `approval_required`, etc.), niveles `auto_confirm_levels`, endpoint de aprobación de solicitudes pendientes; reemplazar `"join_policy": "auto"` hardcodeado en `_match.json.jbuilder`.
2. **Política de tiempo restante:** reglas de negocio para `leave`, `join` y cancelación según horas/minutos antes del `date` del partido.
3. **Transferencia de responsabilidad del creador:** cuando el creador sale con jugadores activos restantes, designar nuevo responsable o bloquear según reglas acordadas.

### Deuda planificada — Sprint 3 (resultados)

1. ~~**Auto-aprobación por tiempo:**~~ `AutoApproveResultsJob` + `matches.auto_approved_at` (ver README).
2. **Reversión de stats al borrar un reporte:** hoy se aplican una sola vez (`matches.stats_applied_at`) y no se revierten. El primer reporte provisorio puede dejar stats distintas del consenso final.
3. ~~**Admin fuerza consenso (Sprint 3b):**~~ implementado en admin (`force_result`).
4. **Admin sets UI:** formularios de edición y force con hasta 5 slots fijos (no filas dinámicas); sets vacíos se ignoran vía `reject_if` en nested attributes.

### Deuda planificada — Sprint 3b (admin resultados)

1. **Force result no revierte stats:** si el admin fuerza un marcador, `stats_applied_at` queda fijado; cambiar o borrar el reporte forzado no revierte `player_stats`.
2. **Delete de reporte en match cerrado:** permitido desde admin; las stats no se revierten.
3. **Reopen:** no hay flujo de reapertura; si se agrega, no debe asumir reversión de stats.
4. ~~**`approved_at` en `match_results`:**~~ eliminada (migración `RemoveApprovedAtFromMatchResults`).

## Deuda técnica resuelta (Sprint de deuda)

- ~~`approved_at`~~ dropped de `match_results`.
- ~~`:unprocessable_entity`~~ → `:unprocessable_content` (controllers + request specs; handler `unprocessable_entity` en `Api::V1::BaseController` solo por nombre interno).
- ~~`database.yml`~~ migrado a ENV (sin password hardcodeada, sin bloques duplicados).
- ~~`ENV.fetch` para `OK_PADEL_DATABASE_PASSWORD`~~ → `ENV[]` (evita `KeyError` al evaluar el ERB del YAML en dev/test).
- ~~Auto-aprobación por tiempo~~ → `AutoApproveResultsJob`, `config/recurring.yml`, `AUTO_APPROVE_AFTER_HOURS`.
- **Development:** `config.active_job.queue_adapter = :solid_queue` (misma DB que la app; sin `solid_queue.connects_to`).

### Variables de entorno requeridas

**Desarrollo:** `DATABASE_PASSWORD` (o `DATABASE_URL`). Opcionales: `DATABASE_USERNAME`, `DATABASE_HOST`, `DATABASE_PORT`.

**Producción:** `OK_PADEL_DATABASE_PASSWORD`, `RAILS_MASTER_KEY`, `APP_HOST`; opcional `MAILER_*`, `SMTP_*`; deploy Kamal: `KAMAL_REGISTRY_PASSWORD`.

Detalle completo en README → Variables de entorno.

## Configuración y convenciones (repo)

- **Base de datos:** `config/database.yml` sin credenciales en código. Producción usa `ENV["OK_PADEL_DATABASE_PASSWORD"]` (nil en dev si no está seteada; la conexión PG en prod falla si falta).
- **HTTP 422:** usar `status: :unprocessable_content` en controllers y `have_http_status(:unprocessable_content)` en request specs (Rack 3.2+).

### Deuda pendiente (features / calidad)

- **Reversión de stats** al borrar reporte de match (ver Sprint 3 / 3b arriba).
- **`match_player` flaky specs** si vuelven a aparecer en CI.

## Estado de calidad
- `bundle exec rspec` → 293 examples, 0 failures (verde).
- `bundle exec rubocop` → 0 offenses ✅
- `bundle exec brakeman -q` → 0 warnings ✅

## Regla operativa
Antes de cerrar cualquier sprint:
1. `bundle exec rspec` verde.
2. `bundle exec rubocop` sin ofensas nuevas.
3. `bundle exec brakeman -q` sin warnings nuevos.
Si hay ofensas nuevas, se arreglan en el mismo sprint.
