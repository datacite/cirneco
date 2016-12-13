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
      Dotenv.load! env_file
    end

    def self.exit_on_failure?
      true
    end

    desc "doi SUBCOMMAND", "doi commands"
    subcommand "doi", Cirneco::Doi

    desc "metadata SUBCOMMAND", "metadata commands"
    subcommand "metadata", Cirneco::Metadata

    desc "media SUBCOMMAND", "media commands"
    subcommand "media", Cirneco::Media
  end
end
