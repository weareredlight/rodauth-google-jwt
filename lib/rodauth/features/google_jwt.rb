# frozen_string_literal: true

require 'google-id-token'
require 'googleauth'
require 'rodauth'
require 'sequel'

require_relative 'google_jwt/version'


module Rodauth
  module Features
    Feature.define(:google_jwt, :GoogleJWT) do
      class NoTokenError < StandardError; end

      const_set :CLIENT_ID, ::Google::Auth::ClientId.new(
        ENV['GOOGLE_CLIENT_ID'],
        ENV['GOOGLE_CLIENT_SECRET']
      ).freeze

      const_set :TOKEN_VALIDATOR, ::GoogleIDToken::Validator.new


      auth_value_method :token_param, 'id_token'
      auth_value_method :domain_whitelist, []
      auth_value_method :domain_blacklist, []


      def validate(payload)
        errors = []
        domain = payload['email']
        domain = domain[domain.index('@') + 1..-1]

        if domain_blacklist.include?(domain) ||
           (domain_whitelist.any? && !domain_whitelist.include?(domain))
          errors << 'Accounts from this domain are not allowed to sign in.'
        end

        errors
      end


      def create_user(new_user_data)
        fields = {
          first_name: new_user_data['given_name'],
          last_name: new_user_data['family_name'],
          picture: new_user_data['picture']
        }

        db[accounts_table]
          .select(:id)[email: new_user_data['email']]
          &.[](:id) ||
          db[accounts_table]
            .insert(fields.merge(email: new_user_data['email']))
      end


      route do |r|
        begin
          if r.params[token_param].nil? || r.params[token_param].empty?
            raise NoTokenError, "The #{token_param} parameter is not present"
          end

          payload = Rodauth::GoogleJWT::TOKEN_VALIDATOR.check(
            r.params[token_param],
            Rodauth::GoogleJWT::CLIENT_ID.id,
            Rodauth::GoogleJWT::CLIENT_ID.id
          )
          errors = validate payload

          if errors.none?
            session[session_key] = create_user(payload)
            response['Authorization'] = session_jwt
            response['Access-Control-Expose-Headers'] = 'Authorization'
            '' # The token is returned in the Authorization header
          else
            response.status = 401
            { errors: errors }
          end
        rescue ::GoogleIDToken::SignatureError, NoTokenError => e
          response.status = 401
          { errors: [e.message] }
        end
      end
    end
  end
end
