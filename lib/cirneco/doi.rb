require "thor"

require_relative 'api'
require_relative 'utils'
require_relative 'base'

module Cirneco
  class Doi < Thor
    include Cirneco::Base
    include Cirneco::Api
    include Cirneco::Utils

    desc "get DOI", "get handle url for DOI"
    method_option :username, :default => ENV['MDS_USERNAME']
    method_option :password, :default => ENV['MDS_PASSWORD']
    method_option :sandbox, :type => :boolean, default: true
    def get(doi)
      if doi == "all"
        response = get_dois(options)
      else
        response = get_doi(doi, options)
      end

      if response.body["errors"]
        puts "Error: " + response.body["errors"].first.fetch("title", "An error occured")
      else
        puts response.body["data"]
      end
    end

    desc "generate PREFIX", "generate a DOI name"
    method_option :prefix, :default => ENV['PREFIX']
    method_option :number, :type => :numeric, :aliases => '-n'
    def generate
      if options[:prefix]
        puts encode_doi(options[:prefix], number: options[:number])
      else
        puts "No PREFIX provided. Use --prefix option or PREFIX ENV variable"
      end
    end

    desc "check DOI", "check DOI using Crockford base32 checksum"
    def check(doi)
      if decode_doi(doi) > 0
        puts "Checksum for #{doi} is valid"
      else
        puts "Checksum for #{doi} is not valid"
      end
    end
  end
end
