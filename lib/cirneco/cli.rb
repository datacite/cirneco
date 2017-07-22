# encoding: UTF-8

require "thor"

require_relative 'doi'
require_relative 'media'
require_relative 'metadata'

module Cirneco
  class CLI < Thor
    include Cirneco::Base
    include Cirneco::Api
    include Cirneco::Utils

    # load ENV variables from .env file if it exists
    env_file = File.expand_path("../../.env", __FILE__)
    if File.exist?(env_file)
      require 'dotenv'
      Dotenv.overload env_file
    end

    def self.exit_on_failure?
      true
    end

    # from http://stackoverflow.com/questions/22809972/adding-a-version-option-to-a-ruby-thor-cli
    map %w[--version -v] => :__print_version

    desc "--version, -v", "print the version"
    def __print_version
      puts Cirneco::VERSION
    end

    desc "doi SUBCOMMAND", "doi commands"
    subcommand "doi", Cirneco::Doi

    desc "metadata SUBCOMMAND", "metadata commands"
    subcommand "metadata", Cirneco::Metadata

    desc "media SUBCOMMAND", "media commands"
    subcommand "media", Cirneco::Media
  end
end
