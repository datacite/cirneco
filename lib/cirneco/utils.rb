require 'base32/url'
require 'securerandom'
require 'bergamasco'
require 'open-uri'
require 'time'

module Cirneco
  module Utils
    # 32 by the factor of 6
    UPPER_LIMIT = 1073741823

    def get_dois_by_prefix(prefix, options={})
      response = get_dois(options)

      if response.body["data"].present?
        response.body["data"] = response.body["data"].select { |doi| doi.start_with?(prefix) }
      end
      response
    end

    def decode_doi(doi)
      prefix, string = doi.split('/', 2)
      Base32::URL.decode(string, checksum: true).to_i
    end

    def encode_doi(prefix, options={})
      prefix = validate_prefix(prefix)
      return nil unless prefix.present?

      number = options[:number].to_s.scan(/\d+/).join("").to_i
      number = SecureRandom.random_number(UPPER_LIMIT) unless number > 0
      shoulder = options[:shoulder].to_s
      shoulder += "-" if shoulder.present?
      length = 8
      split = 4
      prefix.to_s + "/" + shoulder + Base32::URL.encode(number, split: split, length: length, checksum: true)
    end

    def generate_accession_number(options={})
      lower_limit = options[:lower_limit] || 0
      namespace = options[:namespace] || 'MS-'
      registered_numbers = options[:registered_numbers] || []

      if options[:number]
        number = options[:number].to_s
      else
        begin
          number = SecureRandom.random_number(1000000) + lower_limit
        end while registered_numbers.include? number
        number = number.to_s
      end

      number = number.to_s.rjust(options[:length], '0') if options[:length]

      if options[:split]
        number = number.reverse
        number = number.scan(/.{1,#{options[:split]}}/).map { |x| x.reverse }
        number = number.reverse.join("-")
      end

      namespace + number
    end
  end
end
