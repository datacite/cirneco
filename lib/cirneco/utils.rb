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
    def mint_doi_for_file(filepath, options={})
      filename = File.basename(filepath)
      return "File #{filename} ignored: not a markdown file" unless File.extname(filepath) == ".md"

      old_metadata = Bergamasco::Markdown.read_yaml_for_doi_metadata(filepath)
      return nil if old_metadata["doi"] && old_metadata["published"]

      metadata = generate_metadata_for_work(filepath, options)
      work = register_work_for_metadata(metadata)

      return "Errors for DOI #{metadata["doi"]}:\n#{work.validation_errors}" if work.validation_errors.present?

      # datapath = options[:datapath] || ENV['DATAPATH'] || "data/doi.yml"
      # data = Bergamasco::Markdown.read_yaml(datapath) || []
      # data = [data] if data.is_a?(Hash)
      # new_data = [{ "filename" => filename, "doi" => doi, "date" => Time.now.utc.iso8601 }]
      # Bergamasco::Markdown.write_yaml(datapath, data + new_data)

      new_metadata = Bergamasco::Markdown.update_file(filepath, "doi" => metadata["doi"], "published" => true)
      "DOI #{new_metadata["doi"]} minted for #{filename}"
    end

    # currently only supports markdown files with YAML header
    # DOIs are never deleted, but we can remove the metadata from the DataCite index
    def hide_doi_for_file(filepath, options={})
      filename = File.basename(filepath)
      return "File #{filename} ignored: not a markdown file" unless File.extname(filepath) == ".md"

      old_metadata = Bergamasco::Markdown.read_yaml_for_doi_metadata(filepath)
      return nil unless old_metadata["doi"] && old_metadata["published"]

      metadata = generate_metadata_for_work(filepath, options)
      work = unregister_work_for_metadata(metadata)

      return "Errors for DOI #{old_metadata["doi"]}:\n#{work.validation_errors}" if work.validation_errors.present?

      # datapath = options[:datapath] || ENV['DATAPATH'] || "data/doi.yml"
      # data = Bergamasco::Markdown.read_yaml(datapath) || []
      # data = [data] if data.is_a?(Hash)
      # new_data = [{ "filename" => filename, "doi" => doi, "date" => Time.now.utc.iso8601 }]
      # Bergamasco::Markdown.write_yaml(datapath, data + new_data)

      new_metadata = Bergamasco::Markdown.update_file(filepath, "published" => false)
      "DOI #{old_metadata["doi"]} hidden for #{filename}"
    end

    def mint_dois_for_all_files(folderpath, options={})
      Dir.glob("#{folderpath}/*.md").map do |filepath|
        mint_doi_for_file(filepath, options)
      end.compact.join("\n")
    end

    def hide_dois_for_all_files(folderpath, options={})
      Dir.glob("#{folderpath}/*.md").map do |filepath|
        hide_doi_for_file(filepath, options)
      end.compact.join("\n")
    end

    def generate_metadata_for_work(filepath, options={})
      sitepath = options[:sitepath] || ENV['SITE_SITEPATH'] || "data/site.yml"
      authorpath = options[:authorpath] || ENV['SITE_AUTHORPATH'] || "data/authors.yml"
      referencespath = options[:referencespath] || ENV['SITE_REFERENCESPATH'] || "data/references.yml"
      # csl = options[:csl] || ENV['SITE_CSL'] || "styles/apa.csl"
      # bibliography = options[:bibliography] || ENV['SITE_REFERENCESPATH'] || "data/references.yml"
      # options = options.merge(csl: csl, bibliography: bibliography)

      metadata = Bergamasco::Markdown.read_yaml_for_doi_metadata(filepath, options.except(:number))

      return "Error: required metadata missing" unless ["author", "title", "date", "summary"].all? { |k| metadata.key? k }

      # read in optional yaml configuration files for site, author and references
      site_options = sitepath.present? ? Bergamasco::Markdown.read_yaml(sitepath) : {}
      author_options = authorpath.present? ? Bergamasco::Markdown.read_yaml(authorpath) : {}
      references = referencespath.present? ? Bergamasco::Markdown.read_yaml(referencespath) : {}

      # required metadata
      prefix = options[:prefix] || site_options["prefix"] || ENV['PREFIX']
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

      metadata["publisher"] = site_options["site_title"] || ENV['SITE_TITLE']
      metadata["publication_year"] = metadata["date"][0..3].to_i

      metadata["type"] ||= site_options["default_type"] || ENV['SITE_DEFAULT_TYPE'] || "BlogPosting"
      resource_type_general = metadata["type"] == "Dataset" ? "Dataset" : "Text"

      metadata["resource_type"] = { value: metadata["type"],
                                    resource_type_general: resource_type_general }

      # recommended metadata
      metadata["descriptions"] = [{ value: metadata["summary"],
                                    description_type: "Abstract" }]

      # use default version 1.0
      metadata["version"] ||= "1.0"

      # fetch reference metadata if available
      metadata["related_identifiers"] = Array(metadata["references"]).map do |r|
        reference = references.fetch(r, {})
        if reference.present?
          if reference["DOI"].present?
            value = reference["DOI"].upcase
            type = "DOI"
          elsif /(http|https):\/\/(dx\.)?doi\.org\/(\w+)/.match(reference["URL"])
            uri = Addressable::URI.parse(reference["URL"])
            value = uri.path[1..-1].upcase
            type = "DOI"
          elsif reference["URL"].present?
            value = reference["URL"]
            type = "URL"
          else
            type = nil
          end
        else
          if /(http|https):\/\/(dx\.)?doi\.org\/(\w+)/.match(r)
            uri = Addressable::URI.parse(r)
            value = uri.path[1..-1].upcase
            type = "DOI"
          elsif /(http|https):\/\//.match(r)
            uri = Addressable::URI.parse(r)
            value = uri.normalize.to_s
            type = "URL"
          else
            type = nil
          end
        end

        {
          value: value,
          related_identifier_type: type,
          relation_type: "References"
        }
      end.select { |t| t[:related_identifier_type].present? }

      license_name = site_options.fetch("license", {}).fetch("name", nil) || ENV['SITE_LICENCE_NAME'] || "Creative Commons Attribution"
      license_url = site_options.fetch("license", {}).fetch("url", nil) || ENV['SITE_LICENCE_URL'] || "https://creativecommons.org/licenses/by/4.0/"
      metadata["rights_list"] = [{ value: license_name, rights_uri: license_url }]

      metadata["subjects"] = Array(metadata["tags"]).select { |t| t != "featured" }

      contributor = site_options["institution"] || ENV['SITE_INSTITUTION']
      metadata["contributors"] = [{ literal: contributor, contributor_type: "HostingInstitution" }]

      metadata["date_issued"] = metadata["date"]

      metadata = metadata.extract!(*%w(doi url creators title publisher
        publication_year resource_type descriptions version rights_list subjects contributors
        date_issued related_identifiers))
    end

    def url_from_path(site_url, filepath)
      site_url.to_s.chomp("\\") + "/" + File.basename(filepath)[0..-9] + "/"
    end

    def register_work_for_metadata(metadata)
      work = Cirneco::Work.new(metadata)

      filename  = metadata["doi"].split("/", 2).last + ".xml"
      IO.write(filename, work.data)

      work
    end

    def unregister_work_for_metadata(metadata)
      work = Cirneco::Work.new(metadata)

      filename  = metadata["doi"].split("/", 2).last + ".xml"
      File.delete(filename) if File.exist?(filename)

      work
    end
  end
end
