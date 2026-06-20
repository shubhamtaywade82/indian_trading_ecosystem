# frozen_string_literal: true

require "rotp"

module Dhan
  module Auth
    module Strategies
      class Totp < Base
        URL = "https://auth.dhan.co/app/generateAccessToken"

        def call
          client_id = client_id_from_env
          pin       = ENV.fetch("DHAN_PIN")
          totp_code = ROTP::TOTP.new(ENV.fetch("DHAN_TOTP_SECRET")).now

          response = Faraday.post(URL) do |req|
            req.params = {
              dhanClientId: client_id,
              pin: pin,
              totp: totp_code
            }
          end

          raise "TOTP auth failed (status=#{response.status}): #{response.body}" unless response.success?

          body = parse_json_body!(response.body)
          token, expiry_raw = extract_totp_credentials!(body)

          normalize_response(token: token, expiry: Time.zone.parse(expiry_raw))
        end

        private

        def parse_json_body!(raw)
          JSON.parse(raw)
        rescue JSON::ParserError => e
          raise "TOTP response was not valid JSON (#{e.class}): #{raw.to_s[0, 200]}"
        end

        def extract_totp_credentials!(body)
          raise "TOTP response was not a JSON object" unless body.is_a?(Hash)

          if error_payload?(body)
            msg = body["message"].presence || body["errorMessage"].presence || "unknown error"
            raise "TOTP auth rejected: #{msg}"
          end

          token = body["accessToken"].presence || body["access_token"].presence
          expiry_raw = body["expiryTime"].presence || body["expires_at"].presence

          raise "TOTP response missing access token" if token.blank?
          raise "TOTP response missing expiry time" if expiry_raw.blank?

          [token, expiry_raw]
        end

        def error_payload?(body)
          body["status"].to_s.casecmp("error").zero?
        end

        def client_id_from_env
          ENV["DHAN_CLIENT_ID"].presence || ENV["CLIENT_ID"].presence ||
            raise(KeyError, "key not found: neither DHAN_CLIENT_ID nor CLIENT_ID is set")
        end
      end
    end
  end
end
