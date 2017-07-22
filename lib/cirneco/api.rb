require 'uri'
require 'maremma'

module Cirneco
  module Api
    def post_metadata(data, options={})
      return OpenStruct.new(body: { "errors" => [{ "title" => "Username or password missing" }] }) unless options[:username].present? && options[:password].present?

      mds_url = options[:sandbox] ? 'https://mds.test.datacite.org' : 'https://mds.datacite.org'

      url = "#{mds_url}/metadata"
      Maremma.post(url, content_type: 'application/xml;charset=UTF-8', data: data, username: options[:username], password: options[:password])
    end

    def get_metadata(doi, options={})
      return OpenStruct.new(body: { "errors" => [{ "title" => "Username or password missing" }] }) unless options[:username].present? && options[:password].present?

      mds_url = options[:sandbox] ? 'https://mds.test.datacite.org' : 'https://mds.datacite.org'

      url = "#{mds_url}/metadata/#{doi}"
      Maremma.get(url, accept: 'application/xml', username: options[:username], password: options[:password], raw: true)
    end

    def delete_metadata(doi, options={})
      return OpenStruct.new(body: { "errors" => [{ "title" => "Username or password missing" }] }) unless options[:username].present? && options[:password].present?

      mds_url = options[:sandbox] ? 'https://mds.test.datacite.org' : 'https://mds.datacite.org'

      url = "#{mds_url}/metadata/#{doi}"
      Maremma.delete(url, username: options[:username], password: options[:password])
    end

    def put_doi(doi, options={})
      return OpenStruct.new(body: { "errors" => [{ "title" => "Username or password missing" }] }) unless options[:username].present? && options[:password].present?

      payload = "doi=#{doi}\nurl=#{options[:url]}"

      mds_url = options[:sandbox] ? 'https://mds.test.datacite.org' : 'https://mds.datacite.org'

      url = "#{mds_url}/doi/#{doi}"
      Maremma.put(url, content_type: 'text/plain;charset=UTF-8', data: payload, username: options[:username], password: options[:password])
    end

    def get_doi(doi, options={})
      return OpenStruct.new(body: { "errors" => [{ "title" => "Username or password missing" }] }) unless options[:username].present? && options[:password].present?

      mds_url = options[:sandbox] ? 'https://mds.test.datacite.org' : 'https://mds.datacite.org'

      url = "#{mds_url}/doi/#{doi}"
      Maremma.get(url, username: options[:username], password: options[:password])
    end

    def get_dois(options={})
      return OpenStruct.new(body: { "errors" => [{ "title" => "Username or password missing" }] }) unless options[:username].present? && options[:password].present?

      mds_url = options[:sandbox] ? 'https://mds.test.datacite.org' : 'https://mds.datacite.org'

      url = "#{mds_url}/doi"
      response = Maremma.get(url, username: options[:username], password: options[:password])
      response.body["data"] = response.body["data"].split("\n") if response.body["data"].present?
      response
    end

    def post_media(doi, options={})
      return OpenStruct.new(body: { "errors" => [{ "title" => "Username or password missing" }] }) unless options[:username].present? && options[:password].present?

      payload = options[:raw] ? options[:media] : options[:media].map { |m| "#{m[:mime_type]}=#{m[:url]}" }.join("\n")

      mds_url = options[:sandbox] ? 'https://mds.test.datacite.org' : 'https://mds.datacite.org'

      url = "#{mds_url}/media/#{doi}"
      Maremma.post(url, content_type: 'text/plain;charset=UTF-8', data: payload, username: options[:username], password: options[:password])
    end

    def get_media(doi, options={})
      return OpenStruct.new(body: { "errors" => [{ "title" => "Username or password missing" }] }) unless options[:username].present? && options[:password].present?

      mds_url = options[:sandbox] ? 'https://mds.test.datacite.org' : 'https://mds.datacite.org'

      url = "#{mds_url}/media/#{doi}"
      response = Maremma.get(url, accept: 'application/xml', username: options[:username], password: options[:password])
      if response.body["data"].present? && !options[:raw]
        response.body["data"] = response.body["data"].split("\n").map do |m|
          mime_type, url = m.split('=', 2)
          { mime_type: mime_type, url: url }
        end
      end
      response
    end
  end
end
