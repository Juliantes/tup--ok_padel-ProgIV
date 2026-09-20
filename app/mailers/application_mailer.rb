# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "Ok Padel <no-reply@okpadel.local>")
  default reply_to: ENV.fetch("MAILER_REPLY_TO", "soporte@okpadel.local")
  layout "mailer"

  helper_method :app_url

  private

  def app_url(path = "/")
    options = Rails.application.config.action_mailer.default_url_options.symbolize_keys
    protocol = options[:protocol] || "http"
    host = options.fetch(:host)
    port = options[:port]

    base = if port.present?
             "#{protocol}://#{host}:#{port}"
    else
             "#{protocol}://#{host}"
    end

    return "#{base}/" if path == "/" || path.blank?

    normalized = path.start_with?("/") ? path : "/#{path}"
    "#{base}#{normalized}"
  end
end
