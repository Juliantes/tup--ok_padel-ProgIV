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
