require 'thor'
require 'bolognese'

require_relative 'api'
require_relative 'utils'
require_relative 'base'

module Cirneco
  class Doi < Thor
    include Cirneco::Base
    include Cirneco::Api
    include Cirneco::Utils
    include Bolognese::Utils
    include Bolognese::DoiUtils

    desc "get DOI", "get handle url for DOI"
    method_option :username, :default => ENV['MDS_USERNAME']
    method_option :password, :default => ENV['MDS_PASSWORD']
    method_option :sandbox, :type => :boolean, :force => false
    method_option :limit, :type => :numeric, :default => 25
    def get(doi)
      if doi == "all"
        response = get_dois(options)
      else
        response = get_doi(doi, options)
      end

      if response.body["errors"]
        puts "Error: " + response.body["errors"].first.fetch("title", "An error occured")
      elsif doi == "all"
        puts response.body["data"][0...options[:limit]]
      else
        puts response.body["data"]
      end
    end

    desc "put DOI", "put handle url for DOI"
    method_option :username, :default => ENV['MDS_USERNAME']
    method_option :password, :default => ENV['MDS_PASSWORD']
    method_option :sandbox, :type => :boolean, :force => false
    method_option :url
    def put(doi)
      response = put_doi(doi, options)

      if response.body["errors"]
        puts "Error: " + response.body["errors"].first.fetch("title", "An error occured")
      else
        puts response.body["data"]
      end
    end

    desc "put DOIs", "put handle url for multiple DOIs"
    method_option :username, :default => ENV['MDS_USERNAME']
    method_option :password, :default => ENV['MDS_PASSWORD']
    method_option :sandbox, :type => :boolean, :force => false
    def post(file)
      data = JSON.parse(IO.read(file))
      count = 0
      data.each do |json|
        doi = doi_from_url(json["@id"])
        url = json["@url"]
        next unless doi.present? && url.present?

        response = put_doi(doi, options.merge(url: url))

        if response.body["errors"]
          puts "Error: " + response.body["errors"].first.fetch("title", "An error occured")
        else
          puts response.headers["Location"]
          count += 1
        end
      end

      puts "#{count} DOIs registered/updated."
    end

    desc "generate DOI", "generate a DOI name"
    method_option :prefix, :default => ENV['PREFIX']
    method_option :number, :aliases => '-n'
    def generate
      if options[:prefix]
        puts encode_doi(options[:prefix], number: options[:number])
      else
        puts "No PREFIX provided. Use --prefix option or PREFIX ENV variable"
      end
    end

    desc "generate DOI", "generate a DOI name"
    method_option :lower_limit, :type => :numeric, :default => 0
    method_option :namespace, :default => 'MS-'
    method_option :number, :aliases => '-n'
    def accession_number
      puts generate_accession_number(options)
    end

    desc "decode DOI", "decode DOI encoded using base32-url algorithm"
    def decode(doi)
      number = decode_doi(doi)

      if number > 0
        puts "DOI #{doi} was encoded with #{number}"
      else
        puts "DOI #{doi} could not be decoded"
      end
    end

    desc "check DOI", "check DOI using base32-url checksum"
    def check(doi)
      if decode_doi(doi) > 0
        puts "Checksum for #{doi} is valid"
      else
        puts "Checksum for #{doi} is not valid"
      end
    end
  end
end
