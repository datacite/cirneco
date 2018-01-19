require 'bolognese'
require_relative 'api'
require_relative 'utils'
require_relative 'base'

module Cirneco
  class Work < Bolognese::Metadata
    include Cirneco::Base
    include Cirneco::Api
    include Cirneco::Utils

    attr_reader :media, :username, :password

    def initialize(input: nil, from: nil, **options)
      @media = options[:media]
      @username = options[:username]
      @password = options[:password]

      return super(input: input, from: from, doi: options[:doi])
    end
  end
end
