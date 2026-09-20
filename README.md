# tup--ok_padel-ProgIV

Tp 1 from Prog IV

## Getting started

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## Emails

### Desarrollo

En `development`, Action Mailer usa **letter_opener**: al registrarse un usuario, el mail de bienvenida se encola con `deliver_later` y, al procesarse el job, se abre en una pestaña del navegador (no se envía por SMTP real).

### Probar manualmente

```ruby
bin/rails c
UserMailer.welcome(User.last).deliver_now
```

Para ver el encolado asíncrono: `UserMailer.welcome(User.last).deliver_later` y ejecutar el worker de jobs en dev si aplica.

### Variables de entorno

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

### Seeds

`db:seed` crea usuarios y dispara el mail de bienvenida (J1). Para silenciar entregas durante seeds:

```ruby
ActionMailer::Base.perform_deliveries = false
# ... crear usuarios ...
ActionMailer::Base.perform_deliveries = true
```
