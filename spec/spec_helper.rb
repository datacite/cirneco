require 'bundler/setup'
Bundler.setup

require 'simplecov'
SimpleCov.start

require 'cirneco'
require 'maremma'
require 'rspec'
require 'rack/test'
require 'webmock/rspec'
require 'rspec/xsd'
require 'nokogiri'
require 'vcr'

RSpec.configure do |config|
  config.order = :random
  config.include RSpec::XSD
  config.include WebMock::API
  config.include Rack::Test::Methods
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

VCR.configure do |c|
  mds_token = Base64.encode64("#{ENV['MDS_USERNAME']}:#{ENV['MDS_PASSWORD'].to_s}").rstrip

  c.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  c.hook_into :webmock
  c.ignore_localhost = true
  c.ignore_hosts 'codeclimate.com'
  c.filter_sensitive_data("<MDS_TOKEN>") { mds_token }
  c.configure_rspec_metadata!
end

def fixture_path
  File.expand_path("../fixtures", __FILE__) + '/'
end
