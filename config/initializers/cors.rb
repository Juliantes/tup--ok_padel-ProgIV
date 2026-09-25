# Orígenes desde ENV (CSV). Fallback a localhost para dev.
default_origins = [
  "http://localhost:3001", # React
  "http://localhost:5173"  # Vite
]

origins = ENV.fetch("CORS_ORIGINS", default_origins.join(","))
             .split(",")
             .map(&:strip)
             .reject(&:empty?)

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*origins)

    resource "/api/*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      expose: [ "Authorization", "Retry-After" ],
      max_age: 600
  end
end
