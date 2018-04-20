# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rodauth/features/google_jwt/version'

# rubocop:disable Metrics/BlockLength
Gem::Specification.new do |spec|
  # rubocop:enable Metrics/BlockLength
  spec.name          = 'rodauth-google-jwt'
  spec.version       = Rodauth::Features::GoogleJWT::VERSION
  spec.authors       = ['Tony Goncalves']
  spec.email         = ['tonyfg.pt@gmail.com']

  spec.summary       = 'Write a short summary, because RubyGems requires one.'
  spec.description   = 'Write a longer description or delete this line.'
  spec.homepage      = 'http://example.com'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'google-id-token', '~> 1.4.2'
  spec.add_dependency 'googleauth', '~> 0.6.2'
  spec.add_dependency 'jwt', '~> 2.1.0'
  spec.add_dependency 'rodauth', '~> 1.16.0'
  spec.add_dependency 'sequel', '~> 5.7.1'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'roda'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'
end
