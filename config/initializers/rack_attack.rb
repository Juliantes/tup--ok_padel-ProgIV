class Rack::Attack
  ### Backend ###
  # Usar Rails.cache (Solid Cache en prod, memory_store en dev/test).
  # NO agregar Redis. Solid Cache ya está configurado.
  self.cache.store = Rails.cache

  ### Safelist ###
  # Health checks (Kamal/Fly/Render) sin límite
  safelist("allow health checks") do |req|
    req.path == "/up"
  end

  # OPTIONS (preflight CORS) sin throttling
  safelist("allow OPTIONS requests") do |req|
    req.options?
  end

  ### Throttles ###

  # Login: 5 intentos por minuto por IP
  throttle("login/ip", limit: 5, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/login" && req.post?
  end

  # Escritura autenticada: 30 requests por minuto por usuario
  throttle("write/user", limit: 30, period: 1.minute) do |req|
    if req.post? || req.patch? || req.put? || req.delete?
      token = req.env["HTTP_AUTHORIZATION"]&.split(" ")&.last
      next nil if token.blank?

      payload = JsonWebToken.decode(token)
      payload[:user_id] if payload
    end
  end

  # Lectura autenticada: 100 requests por minuto por usuario
  throttle("read/user", limit: 100, period: 1.minute) do |req|
    if req.get?
      token = req.env["HTTP_AUTHORIZATION"]&.split(" ")&.last
      next nil if token.blank?

      payload = JsonWebToken.decode(token)
      payload[:user_id] if payload
    end
  end

  # Lectura anónima: 60 requests por minuto por IP
  throttle("read/ip", limit: 60, period: 1.minute) do |req|
    if req.get? && req.env["HTTP_AUTHORIZATION"].blank?
      req.ip
    end
  end

  ### Blocklist (Fail2Ban) ###
  # Bloquear IPs que reciben muchos 429 en poco tiempo
  blocklist("block abusive IPs") do |req|
    Rack::Attack::Fail2Ban.filter(
      "abusers-#{req.ip}",
      maxretry: 10,
      findtime: 10.minutes,
      bantime: 1.hour
    ) do
      req.env["rack.attack.match_type"] == :throttle
    end
  end

  ### Responses ###
  self.throttled_responder = lambda do |req|
    match_data = req.env["rack.attack.match_data"]
    now = match_data[:epoch_time]
    retry_after = match_data[:period] - (now % match_data[:period])

    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [ { error: "Too many requests. Please retry later." }.to_json ]
    ]
  end

  self.blocklisted_responder = lambda do |_req|
    [
      403,
      { "Content-Type" => "application/json" },
      [ { error: "Forbidden" }.to_json ]
    ]
  end
end
