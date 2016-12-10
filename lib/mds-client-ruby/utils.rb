require 'base32/crockford'

module MdsClientRuby
  module Utils
    def get_dois_by_prefix(options={})
      response = get_dois(options)

      if response.body["data"].present?
        response.body["data"] = response.body["data"].select { |doi| doi.start_with?(ENV['PREFIX']) }
      end
      response
    end

    def get_number_of_latest_doi(options={})
      response = get_dois_by_prefix(options)

      if response.body["data"].present?
        response.body["data"] = response.body["data"].map { |doi| decode_doi(doi) }
                                                     .sort
                                                     .last
      end
      response
    end

    def get_next_doi(options={})
      response = get_number_of_latest_doi(options)
      number = response.body["data"].to_i + 1
      encode_doi(number)
    end

    def decode_doi(doi)
      prefix, string = doi.split('/', 2)
      Base32::Crockford.decode(string, checksum: true).to_i
    end

    def encode_doi(number)
      return nil unless ENV['PREFIX'].present?

      ENV['PREFIX'] + "/" + Base32::Crockford.encode(number, split: 4, length: 8, checksum: true)
    end
  end
end
