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
        url = json["url"]
        next unless doi.present? && url.present?

        response = put_doi(doi, options.merge(url: url))

        if [200, 201].include?(response.status)
          puts "#{doi} registered/updated."
          count += 1
        else
          puts "Error: " + response.body["errors"].first.fetch("title", "An error occured")
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

      unless number.nil?
        puts "DOI #{doi} was encoded with #{number}"
      else
        puts "DOI #{doi} could not be decoded"
      end
    end

    desc "check DOI", "check DOI using base32-url checksum"
    def check(doi)
      unless decode_doi(doi).nil?
        puts "Checksum for #{doi} is valid"
      else
        puts "Checksum for #{doi} is not valid"
      end
    end

    desc "transfer DOIs", "transfer list of DOIs"
    method_option :target,  :type => :string
    method_option :username, :default => ENV['MDS_USERNAME']
    method_option :password, :default => ENV['MDS_PASSWORD']
    method_option :sandbox, :type => :boolean, :force => false
    method_option :jwt, :default => ENV['JWT']
    def transfer(file)
      count = 0
      File.foreach(file) do |line|
        doi = line.rstrip
        next unless doi.present?
        meta = generate_transfer_template(options)

        response = transfer_doi(doi, options.merge(data: meta.to_json))

        if [200, 201].include?(response.status)
          puts "#{doi} Transfered to #{options[:target]}."
          count += 1
        else
          puts "Error: " + response.body["errors"].first.fetch("title", "An error occured")
        end
      end

      puts "#{count} DOIs transfered."
    end

    desc "change DOIs state", "modify states of list of DOIs"
    method_option :operation,  :type => :string
    # method_option :target_state,  :type => :string
    method_option :username, :default => ENV['MDS_USERNAME']
    method_option :password, :default => ENV['MDS_PASSWORD']
    method_option :sandbox, :type => :boolean, :force => false
    method_option :jwt, :default => ENV['JWT']
    def bulk_state_change(file)
      count = 0
      File.foreach(file) do |line|
        doi = line.rstrip
        next unless doi.present?

        # previous_state, operation = case options[:target_state]
        # when "findable"
        #   ["registered", "publish"]
        # when "registered"
        #   ["draft", "register"]
        # when "hide"
        #   [""]
        # end

        previous_state, target_state = case options[:operation]
        when "publish"
          ["registered", "findable"]
        when "register"
          ["draft", "registered"]
        when "hide"
          ["findable", "registered"]
        end

        meta = generate_state_change_template({operation: options[:operation]})

        metadata_reponse = get_rest_doi(doi, options)

        unless [200].include?(metadata_reponse.status)
          puts "#{doi} was not found #{metadata_reponse.status}"
          next
        end
        
        metadata = JSON.parse(metadata_reponse.body.fetch("data", []))
        if metadata.dig("data","attributes","state") == previous_state
          response = update_rest_doi(doi, options.merge(data: meta.to_json))
        else
          puts "#{doi} is in the wrong state for change. #{doi} was not changed"
          next
        end

        if [200, 201].include?(response.status)
          puts "#{doi} Updated to #{target_state}."
          count += 1
        else
          puts "Error: #{doi} " + response.body["errors"].first.fetch("title", "An error occured")
        end
      end

      puts "#{count} DOIs updated."
    end
  end
end
