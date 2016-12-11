# encoding: UTF-8

require "thor"
#require 'active_support/all'

#require_relative 'api'
#require_relative 'utils'
#require_relative 'base'
#require_relative 'doi'

module Cirneco
  class CLI < Thor
    #include MdsClientRuby::Base
    #include MdsClientRuby::Api
    #include MdsClientRuby::Utils

    option :sandbox, :type => :boolean
    option :prefix, :default => ENV['PREFIX']
    option :username, :default => ENV['MDS_USERNAME']
    option :password, :default => ENV['MDS_PASSWORD']

    def self.exit_on_failure?
      true
    end

    desc "hello NAME", "say hello to NAME"
    def hello(name, from=nil)
      puts "from: #{from}" if from
      puts "Hello #{name}"
    end

    #desc "parentcommand SUBCOMMAND", "Some Parent Command"
    #subcommand "doi", MdsClientRuby::CLI::Doi
  end
end
