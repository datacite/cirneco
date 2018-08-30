require "thor"
require 'active_support/all'

require_relative 'api'
require_relative 'utils'
require_relative 'base'

module Cirneco
  class Media < Thor
    include Cirneco::Base
    include Cirneco::Api
    include Cirneco::Utils

    desc "get DOI", "get media for DOI"
    method_option :username, :default => ENV['MDS_USERNAME']
    method_option :password, :default => ENV['MDS_PASSWORD']
    method_option :sandbox, :type => :boolean, :force => false
    def get(doi)
      response = get_media(doi, options.merge(raw: true))

      if response.body["errors"]
        puts "Error: " + response.body["errors"].first.fetch("title", "An error occured")
      else
        filename  = doi.split("/", 2).last + ".txt"
        content = response.body["data"]
        IO.write(filename, content)
        puts "Media for #{doi} saved as #{filename}"
      end
    end

    desc "post DOI", "post media for DOI"
    method_option :username, :default => ENV['MDS_USERNAME']
    method_option :password, :default => ENV['MDS_PASSWORD']
    method_option :sandbox, :type => :boolean, :force => false
    method_option :file, :aliases => '-f'
    def post(doi)
      filename  = options[:file] || doi.split("/", 2).last + ".txt"
      data = IO.read(filename)
      response = post_media(doi, data, options.merge(raw: true))

      if response.body["errors"]
        puts "Error: " + response.body["errors"].first.fetch("title", "An error occured")
      else
        puts response.body["data"]
      end
    end
  end
end
