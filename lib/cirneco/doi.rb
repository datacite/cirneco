require "thor"
require 'active_support/all'

require_relative 'api'
require_relative 'utils'
require_relative 'base'

module Cirneco
  class Doi < Thor
    include Cirneco::Base
    include Cirneco::Api
    include Cirneco::Utils

    desc "get DOI", "get handle url for DOI"
    def get(doi)
      get_doi(doi)
    end

    desc "command", "an example task"
    def command
      puts "I'm a thor task!"
    end
  end
end
