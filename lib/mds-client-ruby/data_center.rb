require 'active_support/all'
require 'nokogiri'
require 'sanitize'

require_relative 'api'
require_relative 'utils'
require_relative 'base'

module MdsClientRuby
  class DataCenter
    include MdsClientRuby::Base
    include MdsClientRuby::Api
    include MdsClientRuby::Utils

    attr_accessor :prefix, :username, :password

    def initialize(prefix:, username:, password:, **options)
      @prefix = prefix
      @username = username
      @password = password
    end
  end
end
