require "thor"
require 'active_support/all'
require 'bolognese'

require_relative 'api'
require_relative 'utils'
require_relative 'base'

module Cirneco
  class Metadata < Thor
    include Cirneco::Base
    include Cirneco::Api
    include Cirneco::Utils
    include Bolognese::DoiUtils

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

    desc "put DOIs", "put metadata for multiple DOIs"
    method_option :username, :default => ENV['MDS_USERNAME']
    method_option :password, :default => ENV['MDS_PASSWORD']
    method_option :sandbox, :type => :boolean, :force => false
    def put(file)
      data = JSON.parse(IO.read(file))
      count = 0
      data.each do |json|
        doi = doi_from_url(json["@id"])
        next unless doi.present?

        response = put_metadata(doi, options.merge(data: json.to_json))

        if response.body["errors"]
          puts "Error: " + response.body["errors"].first.fetch("title", "An error occured")
        else
          puts response.headers["Location"]
          count += 1
        end
      end

      puts "#{count} DOIs registered/updated."
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
