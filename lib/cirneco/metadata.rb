require "thor"
require 'active_support/all'

require_relative 'api'
require_relative 'utils'
require_relative 'file_utils'
require_relative 'base'

module Cirneco
  class Metadata < Thor
    include Cirneco::Base
    include Cirneco::Api
    include Cirneco::Utils
    include Cirneco::FileUtils

    desc "get DOI", "get metadata for DOI"
    method_option :username, :default => ENV['MDS_USERNAME']
    method_option :password, :default => ENV['MDS_PASSWORD']
    method_option :sandbox, :type => :boolean, :force => false
    def get(doi)
      response = get_metadata(doi, options)

      if response.body["errors"]
        puts "Error: " + response.body["errors"].first.fetch("title", "An error occured")
      else
        filename  = doi.split("/", 2).last + ".xml"
        content = response.body["data"]
        IO.write(filename, content)
        puts "Metadata for #{doi} saved as #{filename}"
      end
    end

    desc "post DOI", "post metadata for DOI"
    method_option :username, :default => ENV['MDS_USERNAME']
    method_option :password, :default => ENV['MDS_PASSWORD']
    method_option :sandbox, :type => :boolean, :force => false
    def post(file)
      data = IO.read(file)
      response = post_metadata(data, options)

      if response.body["errors"]
        puts "Error: " + response.body["errors"].first.fetch("title", "An error occured")
      else
        puts response.headers["Location"]
      end
    end

    desc "delete DOI", "hide metadata for DOI"
    method_option :username, :default => ENV['MDS_USERNAME']
    method_option :password, :default => ENV['MDS_PASSWORD']
    method_option :sandbox, :type => :boolean, :force => false
    def delete(doi)
      response = delete_metadata(doi, options)

      if response.body["errors"]
        puts "Error: " + response.body["errors"].first.fetch("title", "An error occured")
      else
        puts response.body["data"]
      end
    end
  end
end
