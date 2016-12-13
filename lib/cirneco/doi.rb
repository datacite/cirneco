require "thor"

require_relative 'api'
require_relative 'utils'
require_relative 'base'

module Cirneco
  class Doi < Thor
    include Cirneco::Base
    include Cirneco::Api
    include Cirneco::Utils

    method_option :sandbox, :type => :boolean
    method_option :prefix, :default => ENV['PREFIX']
    method_option :username, :default => ENV['MDS_USERNAME']
    method_option :password, :default => ENV['MDS_PASSWORD']

    desc "get DOI", "get handle url for DOI"
    def get(doi)
      get_doi(doi)
    end

    desc "encode NUMBER", "say hello to NAME"
    def encode(number)
      puts encode_doi(prefix, number)
    end

    desc "command", "an example task"
    def command
      puts "I'm a thor task!"
    end
  end
end
