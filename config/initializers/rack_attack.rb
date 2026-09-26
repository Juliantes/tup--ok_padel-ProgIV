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

      user_id_from_token(token)
    end
  end

  # Escritura sin token o con Bearer inválido: 20 requests por minuto por IP
  throttle("write/ip", limit: 20, period: 1.minute) do |req|
    next unless req.post? || req.patch? || req.put? || req.delete?

    token = req.env["HTTP_AUTHORIZATION"]&.split(" ")&.last
    if token.blank?
      req.ip
    elsif user_id_from_token(token).nil?
      req.ip
    end
  end

  # Lectura autenticada: 100 requests por minuto por usuario
  throttle("read/user", limit: 100, period: 1.minute) do |req|
    if req.get?
      token = req.env["HTTP_AUTHORIZATION"]&.split(" ")&.last
      next nil if token.blank?

      user_id_from_token(token)
    end
  end

  # Lectura sin token o con Bearer inválido: 60 requests por minuto por IP
  throttle("read/ip", limit: 60, period: 1.minute) do |req|
    next unless req.get?

    if req.env["HTTP_AUTHORIZATION"].blank?
      req.ip
    else
      token = req.env["HTTP_AUTHORIZATION"]&.split(" ")&.last
      req.ip if user_id_from_token(token).nil?
    end
  end

  ### Blocklist (Fail2Ban) ###
  blocklist("block banned IPs") do |req|
    fail2ban_banned?(req.ip)
  end

  ### Responses ###
  self.throttled_responder = lambda do |req|
    record_fail2ban_throttle!(req.ip)

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

  FAIL2BAN_MAX_THROTTLES = 10
  FAIL2BAN_WINDOW = 10.minutes
  FAIL2BAN_BAN_TIME = 1.hour

  def self.user_id_from_token(token)
    JsonWebToken.decode(token)[:user_id]
  rescue JsonWebToken::Error
    nil
  end

  def self.record_fail2ban_throttle!(ip)
    store = cache.store
    count_key = "#{cache.prefix}:fail2ban:throttle:#{ip}"
    count = store.increment(count_key, 1, expires_in: FAIL2BAN_WINDOW)
    count = 1 if count.nil?

    cache.write("fail2ban:ban:#{ip}", true, FAIL2BAN_BAN_TIME) if count > FAIL2BAN_MAX_THROTTLES
  end

  def self.fail2ban_banned?(ip)
    cache.read("fail2ban:ban:#{ip}").present?
  end
end
