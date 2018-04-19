# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'simplecov'
SimpleCov.minimum_coverage 100
SimpleCov.start
require 'minitest/autorun'
require 'minitest/mock'
require 'database_cleaner'
require 'rack/test'
require 'roda'
require 'rodauth'
require 'sequel'

ENV['RACK_ENV'] = 'test'
ENV['GOOGLE_CLIENT_ID'] = 'something'
ENV['GOOGLE_CLIENT_SECRET'] = 'something secret'

DatabaseCleaner.strategy = :transaction
module Minitest
  class Spec
    before :each do
      DatabaseCleaner.start
    end

    after :each do
      DatabaseCleaner.clean
    end
  end
end

Sequel.sqlite
Sequel::DATABASES.first.create_table :users do
  primary_key :id
  String :email, unique: true
  String :first_name
  String :last_name
  String :picture
end

require 'rodauth/features/google_jwt'


def create_app(&block)
  c = Class.new(Roda)
  c.class_eval(&block)
  c
end


def json_post(url, json = nil)
  post(url, json&.to_json, 'CONTENT_TYPE' => 'application/json')
end
