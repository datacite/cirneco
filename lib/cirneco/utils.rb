require 'base32/crockford'

module Cirneco
  module Utils
    def get_dois_by_prefix(prefix, options={})
      response = get_dois(options)

      if response.body["data"].present?
        response.body["data"] = response.body["data"].select { |doi| doi.start_with?(prefix) }
      end
      response
    end

    def get_number_of_latest_doi(prefix, options={})
      response = get_dois_by_prefix(prefix, options)

      if response.body["data"].present?
        response.body["data"] = response.body["data"].map { |doi| decode_doi(doi) }
                                                     .sort
                                                     .last
      end
      response
    end

    def get_next_doi(prefix, options={})
      response = get_number_of_latest_doi(prefix, options)
      number = response.body["data"].to_i + 1
      encode_doi(prefix, number)
    end

    def decode_doi(doi)
      prefix, string = doi.split('/', 2)
      Base32::Crockford.decode(string, checksum: true).to_i
    end

    def encode_doi(prefix, number)
      prefix + "/" + Base32::Crockford.encode(number, split: 4, length: 8, checksum: true)
    end
  end
end
