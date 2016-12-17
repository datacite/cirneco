require 'base32/crockford'
require 'securerandom'
require 'bergamasco'
require 'time'

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

    # currently only supports markdown files with YAML header
    def register_file(filepath, options={})
      filename = File.basename(filepath)
      return "File #{filename} ignored: not a markdown file" unless File.extname(filepath) == ".md"

      file = IO.read(filepath)

      if options[:unregister]
        doi = nil
      else
        prefix = options[:prefix] || ENV['PREFIX']
        doi = encode_doi(prefix, options)
      end

      updated_file = Bergamasco::Markdown.update_file(file, { "doi" => doi })

      if updated_file != file
        IO.write(filepath, updated_file)

        datapath = options[:datapath] || ENV['DATAPATH'] || "data/doi.yml"
        data = Bergamasco::Markdown.read_yaml(datapath) || []
        data = [data] if data.is_a?(Hash)
        new_data = [{ "filename" => filename, "doi" => doi, "date" => Time.now.utc.iso8601 }]
        Bergamasco::Markdown.write_yaml(datapath, data + new_data)
      end

      if doi.nil?
        "DOI removed from #{filename}"
      elsif updated_file != file
        "DOI #{doi} added to #{filename}"
      else
        "DOI #{doi} found in #{filename}"
      end
    end

    def register_all_files(folderpath, options={})
      Dir.glob("#{folderpath}/*.md").map do |filepath|
        register_file(filepath, options)
      end.join("\n")
    end

    def create_work_from_yaml(metadata:, **options)
      return "Error" unless ["doi", "author", "title", "date", "summary"].all? { |k| metadata.key? k }

      creators = Array(metadata["author"])

      publisher = options[:publisher] || ENV['SITE_TITLE']
      publication_year = metadata["date"][0..3].to_i

      resource_type = metadata["type"] || options[:type] || ENV['SITE_DEFAULT_TYPE'] || "BlogPosting"
      resource_type_general = resource_type == "Dataset" ? "Dataset" : "Text"

      license_name = options[:license_name] || ENV['SITE_LICENCE_NAME'] || "Creative Commons Attribution"
      license_url = options[:license_url] # || ENV['SITE_LICENCE_URL'] || "https://creativecommons.org/licenses/by/4.0/"

      descriptions = [{ value: metadata["summary"], description_type: "Abstract" }]

      contributor = options[:hosting_institution] || ENV['SITE_HOSTING_INSTITUTION']
      contributors = [{ literal: contrbutor }]

      Cirneco::Work.new(doi: metadata["doi"], creators: creators, title: metadata["title"], publisher: publisher, publication_year: publication_year, resource_type: { value: resource_type, resource_type_general: resource_type_general }, rights: [{ value: license_name, rights_uri: license_url }], subjects: Array(metadata["tags"], descriptions: descriptions, contributors: contributors) )
    end
  end
end
