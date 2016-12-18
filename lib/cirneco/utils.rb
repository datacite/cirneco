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
      end
    end

    def register_all_files(folderpath, options={})
      Dir.glob("#{folderpath}/*.md").map do |filepath|
        register_file(filepath, options)
      end.join("\n")
    end

    def generate_metadata_for_work(filepath, options={})
      metadata = Bergamasco::Markdown.read_yaml_for_doi_metadata(filepath, options.except(:number))

      return "Error: required metadata missing" unless ["author", "title", "date", "summary"].all? { |k| metadata.key? k }

      # read in optional yaml configuration file for site
      sitepath = options[:sitepath] || ENV['SITE_SITEPATH']
      site_options = sitepath.present? ? Bergamasco::Markdown.read_yaml(sitepath) : {}

      # read in optional yaml configuration file for authors
      authorpath = options[:authorpath] || ENV['SITE_AUTHORPATH']
      author_options = authorpath.present? ? Bergamasco::Markdown.read_yaml(authorpath) : {}

      # required metadata
      prefix = options[:prefix] || ENV['PREFIX']
      metadata["doi"] ||= encode_doi(prefix, options)

      site_url = site_options["site_url"] || ENV['SITE_URL']
      metadata["url"] ||= url_from_path(site_url, filepath)

      metadata["creators"] = Array(metadata["author"]).map do |a|
        author = author_options.fetch(a, {})
        if author.present?
          { given_name: author["given"],
            family_name: author["family"],
            orcid: author["orcid"] }
        else
          { literal: a }
        end
      end

      metadata["publisher"] = site_options["publisher"] || ENV['SITE_TITLE']
      metadata["publication_year"] = metadata["date"][0..3].to_i

      metadata["type"] ||= site_options["site_default_type"] || ENV['SITE_DEFAULT_TYPE'] || "BlogPosting"
      resource_type_general = metadata["type"] == "Dataset" ? "Dataset" : "Text"

      metadata["resource_type"] = { value: metadata["type"],
                                    resource_type_general: resource_type_general }

      # recommended metadata
      metadata["descriptions"] = [{ value: metadata["summary"],
                                    description_type: "Abstract" }]

      # use default version 1.0
      metadata["version"] ||= "1.0"

      license_name = site_options.fetch("license", {}).fetch("name", nil) || ENV['SITE_LICENCE_NAME'] || "Creative Commons Attribution"
      license_url = site_options.fetch("license", {}).fetch("url", nil) || ENV['SITE_LICENCE_URL'] || "https://creativecommons.org/licenses/by/4.0/"
      metadata["rights_list"] = [{ value: license_name, rights_uri: license_url }]

      metadata["subjects"] = Array(metadata["tags"]).select { |t| t != "featured" }

      contributor = site_options["site_institution"] || ENV['SITE_INSTITUTION']
      metadata["contributors"] = [{ literal: contributor, contributor_type: "HostingInstitution" }]

      metadata = metadata.extract!(*%w(doi url creators title publisher
        publication_year resource_type descriptions version rights_list subjects contributors
        related_identifiers))
    end

    def url_from_path(site_url, filepath)
      site_url.to_s.chomp("\\") + "/" + File.basename(filepath)[0..-9] + "/"
    end

    def create_work_from_metadata(metadata, options={})
      work = Cirneco::Work.new(metadata)

      filename  = metadata["doi"].split("/", 2).last + ".xml"
      IO.write(filename, work.data)

      work
    end
  end
end
