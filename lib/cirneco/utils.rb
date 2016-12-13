require 'base32/crockford'
require 'securerandom'

module Cirneco
  module Utils
    # "ZZZZZZZ" decoded as number
    UPPER_LIMIT = 34359738367

    def get_dois_by_prefix(prefix, options={})
      response = get_dois(options)

      if response.body["data"].present?
        response.body["data"] = response.body["data"].select { |doi| doi.start_with?(prefix) }
      end
      response
    end

    def decode_doi(doi)
      prefix, string = doi.split('/', 2)
      Base32::Crockford.decode(string, checksum: true).to_i
    end

    def encode_doi(prefix, options={})
      number = options[:number] || SecureRandom.random_number(UPPER_LIMIT)
      prefix.to_s + "/" + Base32::Crockford.encode(number, split: 4, length: 8, checksum: true)
    end
  end
end
