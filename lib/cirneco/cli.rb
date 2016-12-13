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

    def self.exit_on_failure?
      true
    end

    desc "hello NAME", "say hello to NAME"
    def hello(name, from=nil)
      puts "from: #{from}" if from
      puts "Hello #{name}"
    end

    desc "parentcommand SUBCOMMAND", "Some Parent Command"
    subcommand "doi", Cirneco::Doi
  end
end
