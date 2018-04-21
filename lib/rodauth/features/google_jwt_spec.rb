# frozen_string_literal: true

require 'spec_helper'


describe Rodauth::Features::GoogleJWT do
  include Rack::Test::Methods

  let(:db) { Sequel::DATABASES.first }

  it 'has a version number' do
    ::Rodauth::Features::GoogleJWT::VERSION.wont_be_nil
  end

  describe 'with default options' do
    let(:app) do
      create_app do
        plugin :rodauth, json: :only do
          enable :jwt, :google_jwt
          accounts_table :users
          require_bcrypt? false
          jwt_secret 'wat'
        end

        route(&:rodauth)
      end
    end

    describe 'with a valid id_token' do
      before do
        mock_fields = {
          'email' => 'hips@dontlie.com',
          'given_name' => 'hips',
          'family_name' => 'dont lie',
          'picture' => 'http://hips.dont.lie',
          'domain' => 'a@b.c'
        }

        Rodauth::GoogleJWT::TOKEN_VALIDATOR.stub :check, mock_fields do
          json_post '/google-jwt', id_token: 'hipsdontlie'
        end
      end

      it "creates user if it doesn't exist" do
        db[:users][email: 'hips@dontlie.com']
          .reject { |k, _| k == :id }
          .must_equal(
            email: 'hips@dontlie.com',
            first_name: 'hips',
            last_name: 'dont lie',
            picture: 'http://hips.dont.lie'
          )
      end

      it "doesn't create or change a user if it already exists" do
        mock_fields = {
          'email' => 'hips@dontlie.com',
          'given_name' => 'something',
          'family_name' => 'else',
          'picture' => 'http://wat.com',
          'domain' => 'x@y.z'
        }

        Rodauth::GoogleJWT::TOKEN_VALIDATOR.stub :check, mock_fields do
          json_post '/google-jwt', id_token: 'hipsdontlie'
        end

        db[:users][email: 'hips@dontlie.com']
          .reject { |k, _| k == :id }
          .must_equal(
            email: 'hips@dontlie.com',
            first_name: 'hips',
            last_name: 'dont lie',
            picture: 'http://hips.dont.lie'
          )
      end

      it 'responds 200 ok' do
        last_response.must_be :ok?
      end

      it 'returns a jwt token with the user id' do
        body = last_response.body
        user_id = db[:users].first(email: 'hips@dontlie.com')[:id]
        expected_jwt = JWT.encode({ account_id: user_id }, 'wat')
        body.must_equal({ jwt: expected_jwt }.to_json)
        user_id = JWT.decode(
          JSON.parse(body)['jwt'],
          'wat',
          true
        ).first['account_id']
        db[:users][id: user_id][:email].must_equal 'hips@dontlie.com'
      end
    end

    it "doesn't authorize user if id_token is not valid" do
      mock_error = proc { raise ::GoogleIDToken::SignatureError, 'yes they do' }
      Rodauth::GoogleJWT::TOKEN_VALIDATOR.stub :check, mock_error do
        json_post '/google-jwt', id_token: 'hipsdontlie'
      end

      last_response.must_be :unauthorized?
      last_response.body.must_equal({ errors: ['yes they do'] }.to_json)
    end

    it "doesn't authorize user if there's no id_token param" do
      json_post '/google-jwt'
      last_response.must_be :unauthorized?
      last_response.body.must_equal({
        errors: ['The id_token parameter is not present']
      }.to_json)
    end
  end


  describe 'with custom param_token' do
    let(:app) do
      create_app do
        plugin :rodauth, json: :only do
          enable :jwt, :google_jwt
          accounts_table :users
          require_bcrypt? false
          jwt_secret 'wat'
          token_param 'custom_id_token'
        end

        route(&:rodauth)
      end
    end

    describe 'with a valid custom_id_token' do
      before do
        mock_fields = {
          'email' => 'hips@dontlie.com',
          'given_name' => 'hips',
          'family_name' => 'dont lie',
          'picture' => 'http://hips.dont.lie',
          'domain' => 'a@b.c'
        }

        Rodauth::GoogleJWT::TOKEN_VALIDATOR.stub :check, mock_fields do
          json_post '/google-jwt', custom_id_token: 'hipsdontlie'
        end
      end

      it 'responds 200 ok' do
        last_response.must_be :ok?
      end
    end
  end


  describe 'with custom domain_blacklist' do
    let(:app) do
      create_app do
        plugin :rodauth, json: :only do
          enable :jwt, :google_jwt
          accounts_table :users
          require_bcrypt? false
          jwt_secret 'wat'
          domain_blacklist ['baddomain.com']
        end

        route(&:rodauth)
      end
    end

    describe 'with a user from baddomain.com' do
      before do
        mock_fields = {
          'email' => 'hips@baddomain.com',
          'given_name' => 'hips',
          'family_name' => 'dont lie',
          'picture' => 'http://hips.dont.lie',
          'domain' => 'a@b.c'
        }

        Rodauth::GoogleJWT::TOKEN_VALIDATOR.stub :check, mock_fields do
          json_post '/google-jwt', id_token: 'hipsdontlie'
        end
      end

      it 'is not authorized' do
        last_response.must_be :unauthorized?
      end

      it 'returns the error message' do
        last_response.body.must_equal({
          errors: ['Accounts from this domain are not allowed to sign in.']
        }.to_json)
      end
    end

    describe 'with a user from another domain' do
      before do
        mock_fields = {
          'email' => 'hips@dontlie.com',
          'given_name' => 'hips',
          'family_name' => 'dont lie',
          'picture' => 'http://hips.dont.lie',
          'domain' => 'a@b.c'
        }

        Rodauth::GoogleJWT::TOKEN_VALIDATOR.stub :check, mock_fields do
          json_post '/google-jwt', id_token: 'hipsdontlie'
        end
      end

      it 'responds 200 ok' do
        last_response.must_be :ok?
      end
    end
  end


  describe 'with custom domain_whitelist' do
    let(:app) do
      create_app do
        plugin :rodauth, json: :only do
          enable :jwt, :google_jwt
          accounts_table :users
          require_bcrypt? false
          jwt_secret 'wat'
          domain_whitelist ['gooddomain.com']
        end

        route(&:rodauth)
      end
    end


    describe 'with a user from gooddomain.com' do
      before do
        mock_fields = {
          'email' => 'hips@gooddomain.com',
          'given_name' => 'hips',
          'family_name' => 'dont lie',
          'picture' => 'http://hips.dont.lie',
          'domain' => 'a@b.c'
        }

        Rodauth::GoogleJWT::TOKEN_VALIDATOR.stub :check, mock_fields do
          json_post '/google-jwt', id_token: 'hipsdontlie'
        end
      end

      it 'responds 200 ok' do
        last_response.must_be :ok?
      end
    end


    describe 'with a user from another domain' do
      before do
        mock_fields = {
          'email' => 'hips@dontlie.com',
          'given_name' => 'hips',
          'family_name' => 'dont lie',
          'picture' => 'http://hips.dont.lie',
          'domain' => 'a@b.c'
        }

        Rodauth::GoogleJWT::TOKEN_VALIDATOR.stub :check, mock_fields do
          json_post '/google-jwt', id_token: 'hipsdontlie'
        end
      end

      it 'is not authorized' do
        last_response.must_be :unauthorized?
      end

      it 'returns the error message' do
        last_response.body.must_equal({
          errors: ['Accounts from this domain are not allowed to sign in.']
        }.to_json)
      end
    end
  end
end
