require 'active_support/all'
require 'nokogiri'
require 'bolognese'

require_relative 'api'
require_relative 'utils'
require_relative 'base'

module Cirneco
  class DataCenter
    include Cirneco::Base
    include Cirneco::Api
    include Cirneco::Utils
    include Bolognese::Utils
    include Bolognese::DoiUtils

    attr_accessor :prefix, :username, :password

    def initialize(prefix:, username:, password:, **options)
      @prefix = prefix
      @username = username
      @password = password
    end
  end
end
