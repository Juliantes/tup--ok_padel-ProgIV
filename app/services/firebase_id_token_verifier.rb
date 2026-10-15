# frozen_string_literal: true

require "net/http"
require "openssl"

class FirebaseIdTokenVerifier
  class VerificationError < StandardError; end

  CERTS_URL = "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"
  CERTS_CACHE_KEY = "firebase/securetoken/x509_certs"
  CERTS_CACHE_TTL = 1.hour

  def self.verify(id_token)
    new.verify(id_token)
  end

  def verify(id_token)
    raise VerificationError, "missing token" if id_token.blank?

    project_id = firebase_project_id
    expected_issuer = "https://securetoken.google.com/#{project_id}"

    _payload, header = JWT.decode(id_token, nil, false)
    kid = header["kid"]
    raise VerificationError, "missing key id" if kid.blank?

    public_key = public_key_for(kid)
    payload, = JWT.decode(id_token, public_key, true, algorithm: "RS256")

    validate_claims!(payload, project_id:, expected_issuer:)
    payload
  rescue JWT::DecodeError, JWT::ExpiredSignature => e
    raise VerificationError, e.message
  end

  private

  def firebase_project_id
    project_id = ENV["FIREBASE_PROJECT_ID"].presence
    return project_id if project_id

    raise VerificationError, "FIREBASE_PROJECT_ID is not configured"
  end

  def validate_claims!(payload, project_id:, expected_issuer:)
    raise VerificationError, "invalid issuer" unless payload["iss"] == expected_issuer
    raise VerificationError, "invalid audience" unless payload["aud"] == project_id
    raise VerificationError, "email missing" if payload["email"].blank?
    unless payload["email_verified"] == true || payload["email_verified"] == "true"
      raise VerificationError, "email not verified"
    end
  end

  def public_key_for(kid)
    certs = fetch_certs
    pem = certs[kid]
    raise VerificationError, "unknown signing key" if pem.blank?

    OpenSSL::X509::Certificate.new(pem).public_key
  end

  def fetch_certs
    Rails.cache.fetch(CERTS_CACHE_KEY, expires_in: CERTS_CACHE_TTL) do
      download_certs
    end
  rescue VerificationError
    Rails.cache.delete(CERTS_CACHE_KEY)
    raise
  end

  def download_certs
    uri = URI(CERTS_URL)
    response = Net::HTTP.get_response(uri)
    raise VerificationError, "unable to fetch Firebase certificates" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue JSON::ParserError
    raise VerificationError, "invalid Firebase certificate response"
  end
end
