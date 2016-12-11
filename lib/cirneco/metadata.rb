require "thor"
require 'active_support/all'

require_relative 'api'
require_relative 'utils'
require_relative 'base'

module Cirneco
  class Metadata < Thor
    include Cirneco::Base
    include Cirneco::Api
    include Cirneco::Utils

  end
end
