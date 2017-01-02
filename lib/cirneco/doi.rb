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

    desc "decode DOI", "decode DOI encoded using Crockford base32 algorithm"
    def decode(doi)
      number = decode_doi(doi)

      if number > 0
        puts "DOI #{doi} was encoded with #{number}"
      else
        puts "DOI #{doi} could not be decoded"
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

    desc "name DOCUMENT", "name document"
    method_option :length, :type => :numeric
    method_option :lower_limit, :type => :numeric
    method_option :split, :type => :numeric, :default => 4
    method_option :namespace, :default => 'MS-'
    method_option :opt_in, :type => :boolean
    def name(filepath)
      if File.directory?(filepath)
        response = update_all_accession_numbers(filepath, options)
      else
        response = update_accession_number(filepath, options)
      end

      puts response
    end

    desc "mint DOCUMENT", "mint document"
    method_option :sitepath, :default => ENV['SITE_SITEPATH']
    method_option :authorpath, :default => ENV['SITE_AUTHORPATH']
    method_option :referencespath, :default => ENV['SITE_REFERENCESPATH']
    method_option :source_dir
    method_option :index_dir
    method_option :csl, :default => ENV['SITE_CSLPATH']
    method_option :number, :aliases => '-n'
    method_option :username, :default => ENV['MDS_USERNAME']
    method_option :password, :default => ENV['MDS_PASSWORD']
    method_option :prefix, :default => ENV['PREFIX']
    method_option :sandbox, :type => :boolean, :force => false
    def mint(url)
      response = mint_dois_for_all_urls(url, options)
      puts response
    end

    desc "mint and hide DOCUMENT", "mint and hide document"
    method_option :sitepath, :default => ENV['SITE_SITEPATH']
    method_option :authorpath, :default => ENV['SITE_AUTHORPATH']
    method_option :referencespath, :default => ENV['SITE_REFERENCESPATH']
    method_option :source_dir
    method_option :index_dir
    method_option :csl, :default => ENV['SITE_CSLPATH']
    method_option :number, :aliases => '-n'
    method_option :username, :default => ENV['MDS_USERNAME']
    method_option :password, :default => ENV['MDS_PASSWORD']
    method_option :prefix, :default => ENV['PREFIX']
    method_option :sandbox, :type => :boolean, :force => false
    def mint_and_hide(url)
      response = mint_and_hide_dois_for_all_urls(url, options)
      puts response
    end

    desc "hide DOCUMENT", "hide document"
    method_option :sitepath, :default => ENV['SITE_SITEPATH']
    method_option :authorpath, :default => ENV['SITE_AUTHORPATH']
    method_option :referencespath, :default => ENV['SITE_REFERENCESPATH']
    method_option :source_dir
    method_option :index_dir
    method_option :csl, :default => ENV['SITE_CSLPATH']
    method_option :bibliography, :default => ENV['SITE_REFERENCESPATH']
    method_option :username, :default => ENV['MDS_USERNAME']
    method_option :password, :default => ENV['MDS_PASSWORD']
    method_option :sandbox, :type => :boolean, :force => false
    def hide(url)
      response = hide_dois_for_all_urls(url, options)
      puts response
    end
  end
end
