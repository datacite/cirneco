require 'base32/crockford'
require 'securerandom'
require 'bergamasco'
require 'open-uri'
require 'time'

module Cirneco
  module Utils
    # "ZZZZZZZ" decoded as number
    UPPER_LIMIT = 34359738367

    LICENSES = {
      "https://creativecommons.org/licenses/by/4.0/" => "Creative Commons Attribution (CC-BY 4.0)",
      "https://creativecommons.org/publicdomain/zero/1.0/" => "Creative Commons Public Domain Dedication (CC0 1.0)"
    }

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
      number = options[:number].to_s.scan(/\d+/).first.to_i
      number = SecureRandom.random_number(UPPER_LIMIT) unless number > 0
      prefix.to_s + "/" + Base32::Crockford.encode(number, split: 4, length: 8, checksum: true)
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

    def get_accession_number(filepath)
      metadata = Bergamasco::Markdown.read_yaml_for_doi_metadata(filepath)
      metadata.fetch("accession_number", nil).to_s.scan(/\d+/).first.to_i
    end

    def get_all_accession_numbers(folderpath)
      Dir.glob("#{folderpath}/*.md").sort.map do |filepath|
        get_accession_number(filepath)
      end.select { |a| a > 0 }.sort
    end

    def update_accession_number(filepath, options={})
      filename = File.basename(filepath)
      return "File #{filename} ignored: not a markdown or html file" unless %w(.md .html .erb).include?(File.extname(filepath))

      old_metadata = Bergamasco::Markdown.read_yaml_for_doi_metadata(filepath)
      return "File #{filename} ignored: no yaml front matter" unless old_metadata.present?

      return "File #{filename} ignored: no empty accession_number" if options[:opt_in] && !old_metadata.key?("accession_number")

      return "Accession number #{old_metadata["accession_number"]} not changed for #{filename}" if old_metadata["accession_number"]

      if old_metadata["doi"].present?
        number = decode_doi(old_metadata["doi"])
        options[:number] = number if number > 0
      else
        folderpath = File.dirname(filepath)
        options[:registered_numbers] = get_all_accession_numbers(folderpath)
      end

      accession_number = generate_accession_number(options)

      new_metadata = Bergamasco::Markdown.update_file(filepath, "accession_number" => accession_number)
      "Accession number #{new_metadata["accession_number"]} generated for #{filename}"
    end

    def update_all_accession_numbers(folderpath, options={})
      Dir.glob("#{folderpath}/*.md").sort.map do |filepath|
        update_accession_number(filepath, options)
      end
    end

    # fetch schema.org metadata in JSON-LD format to mint DOI
    def mint_doi_for_url(url, options={})
      filename, build_path, source_path = filepath_from_url(url, options)

      metadata = generate_metadata_for_work(build_path, options)
      return "DOI #{metadata["doi"]} not changed for #{filename}" if metadata["doi"] && metadata["date_issued"]

      response = post_metadata_for_work(metadata, options)
      return "Errors for DOI #{metadata["doi"]}: #{response.body['errors'].first['title']}\n" if response.body['errors'].present?

      new_metadata = Bergamasco::Markdown.update_file(source_path, "doi" => metadata["doi"], "published" => true)
      "DOI #{new_metadata["doi"]} minted for #{filename}"
    end

    # fetch schema.org metadata in JSON-LD format to mint DOI
    def mint_and_hide_doi_for_url(url, options={})
      filename, build_path, source_path = filepath_from_url(url, options)

      metadata = generate_metadata_for_work(build_path, options)
      return "DOI #{metadata["doi"]} not changed for #{filename}" if metadata["doi"] && metadata["date_issued"]

      response = post_metadata_for_work(metadata, options)
      return "Errors for DOI #{metadata["doi"]}: #{response.body['errors'].first['title']}\n" if response.body['errors'].present?

      new_metadata = Bergamasco::Markdown.update_file(source_path, "doi" => metadata["doi"], "published" => false)
      "DOI #{new_metadata["doi"]} minted and hidden for #{filename}"
    end

    # fetch schema.org metadata in JSON-LD format to mint DOI
    # DOIs are never deleted, but we can remove the metadata from the DataCite index
    def hide_doi_for_url(url, options={})
      filename, build_path, source_path = filepath_from_url(url, options)

      metadata = generate_metadata_for_work(build_path, options)
      return "No DOI for #{filename}" unless metadata["doi"]
      return "DOI #{metadata["doi"]} not active for #{filename}" unless metadata["date_issued"]

      response = hide_metadata_for_work(metadata, options)
      return "Errors for DOI #{metadata["doi"]}: #{response.body['errors'].first['title']}\n" if response.body['errors'].present?

      new_metadata = Bergamasco::Markdown.update_file(source_path, "published" => false)
      "DOI #{metadata["doi"]} hidden for #{filename}"
    end

    def mint_dois_for_all_urls(url, options={})
      urls = get_urls_for_works(url)
      urls.map do |u|
        mint_doi_for_url(u, options)
      end.join("\n")
    end

    def mint_and_hide_dois_for_all_urls(url, options={})
      urls = get_urls_for_works(url)
      urls.map do |u|
        mint_and_hide_doi_for_url(u, options)
      end.join("\n")
    end

    def hide_dois_for_all_urls(url, options={})
      urls = get_urls_for_works(url)
      urls.map do |u|
        hide_doi_for_url(u, options)
      end.join("\n")
    end

    def get_urls_for_works(url)
      doc = Nokogiri::HTML(open(url))
      json = doc.at_xpath("//script[@type='application/ld+json']")
      return [url] unless json.present?

      metadata = ActiveSupport::JSON.decode(json.text)
      metadata.fetch("hasPart", []).map { |p| p["@id"] } + [url]
    end

    def generate_metadata_for_work(url, options={})
      doc = Nokogiri::HTML(open(url))
      json = doc.at_xpath("//script[@type='application/ld+json']")
      return "Error: no schema.org metadata found" unless json.present?

      metadata = ActiveSupport::JSON.decode(json.text)

      return "Error: required metadata missing" unless ["name", "author", "publisher", "datePublished", "@type"].all? { |k| metadata.key? k }

      # required metadata
      if /(http|https):\/\/(dx\.)?doi\.org\/(\w+)/.match(metadata["@id"])
        uri = Addressable::URI.parse(metadata["@id"])
        metadata["doi"] = uri.path[1..-1].upcase
      end

      metadata["title"] = metadata["name"]

      metadata["creators"] = format_authors(metadata["author"])

      metadata["publisher"] = metadata.fetch("publisher", {}).fetch("name", nil)
      metadata["publication_year"] = metadata.fetch("datePublished", "")[0..3].to_i

      resource_type_general = case metadata["@type"]
        when "Dataset" then "Dataset"
        when "Blog" then "Collection"
        when "Code" then "Software"
        else "Text"
        end

      metadata["resource_type"] = { value: metadata["@type"],
                                    resource_type_general: resource_type_general }

      # recommended metadata

      # use alternate_identifier to generate DOI
      metadata["alternate_identifier"] = metadata["alternateName"]

      if metadata["description"].present?
        metadata["descriptions"] = [{ value: metadata["description"], description_type: "Abstract" }]
      end

      # use default version 1.0
      metadata["version"] ||= "1.0"

      # fetch reference metadata if available
      metadata["related_identifiers"] = get_related_identifiers(metadata)

      if metadata["license"].present?
        value = LICENSES.fetch(metadata["license_url"], nil)
        metadata["rights_list"] = [{ value: value, rights_uri: metadata["license"] }] if value.present?
      end

      if metadata["keywords"].present?
        metadata["subjects"] = Array(metadata["keywords"].split(", ")).select { |k| k != "featured" }
      end

      metadata["media"] = format_media(metadata)

      metadata["date_created"] = metadata["dateCreated"]
      metadata["date_issued"] = metadata["datePublished"]
      metadata["date_updated"] = metadata["dateModified"]

      metadata = metadata.extract!(*%w(doi alternate_identifier url creators title
        publisher publication_year resource_type descriptions version rights_list
        subjects date_issued date_created date_updated related_identifiers media))
    end

    def post_metadata_for_work(metadata, options={})
      prefix = options[:prefix] || ENV['PREFIX']
      metadata["doi"] ||= encode_doi(prefix, number: metadata["alternate_identifier"])

      work = Cirneco::Work.new(metadata)
      return work.validation_errors if work.validation_errors.body["errors"].present?

      response = work.post_metadata(work.data, options)
      return response unless response.status == 201

      response = work.put_doi(metadata["doi"], options.merge(url: metadata["url"]))
      return response unless response.status == 201

      if work.media.present?
        work.post_media(metadata["doi"], options.merge(media: work.media))
      else
        response
      end
    end

    def post_and_hide_metadata_for_work(metadata, options={})
      prefix = options[:prefix] || ENV['PREFIX']
      metadata["doi"] ||= encode_doi(prefix, number: metadata["alternate_identifier"])

      work = Cirneco::Work.new(metadata)
      return work.validation_errors if work.validation_errors.body["errors"].present?

      response = work.post_metadata(work.data, options)
      return response unless response.status == 201

      response = work.put_doi(metadata["doi"], options.merge(url: metadata["url"]))
      return response unless response.status == 201

      response = work.delete_metadata(metadata["doi"], options)
      return response unless response.status == 201

      if work.media.present?
        work.post_media(metadata["doi"], options.merge(media: work.media))
      else
        response
      end
    end

    def hide_metadata_for_work(metadata, options={})
      prefix = options[:prefix] || ENV['PREFIX']
      metadata["doi"] ||= encode_doi(prefix, number: metadata["alternate_identifier"])

      work = Cirneco::Work.new(metadata)
      return work.validation_errors if work.validation_errors.body["errors"].present?

      work.delete_metadata(metadata["doi"], options)
    end

    def generate_metadata_for_jats(url, options={})
      doc = Nokogiri::HTML(open(url))
      json = doc.at_xpath("//script[@type='application/ld+json']")
      return "Error: no schema.org metadata found" unless json.present?

      metadata = ActiveSupport::JSON.decode(json.text)

      return "Error: required metadata missing" unless ["name", "author", "publisher", "datePublished", "@type"].all? { |k| metadata.key? k }

      # required metadata
      if /(http|https):\/\/(dx\.)?doi\.org\/(\w+)/.match(metadata["@id"])
        uri = Addressable::URI.parse(metadata["@id"])
        metadata["doi"] = uri.path[1..-1].upcase
      end

      metadata["title"] = metadata["name"]
      metadata["author"] = format_authors(metadata["author"]).map do |a|
        { "given_name" => a[:given_name],
          "family_name" => a[:family_name],
          "name" => a[:name],
          "orcid" => a[:orcid] }.compact
      end

      metadata["publisher"] = metadata.fetch("publisher", {}).fetch("name", nil)
      metadata["tags"] = metadata["keywords"].to_s.split(", ").select { |k| k != "featured" }
      metadata["date"] = metadata.fetch("datePublished", "")
      metadata["publication_year"] = metadata.fetch("date", "")[0..3].to_i
      metadata["publication_month"] = metadata.fetch("date", "")[5..6].to_i
      metadata["publication_day"] = metadata.fetch("date", "")[8..9].to_i

      if metadata["description"].present?
        metadata["descriptions"] = [{ value: metadata["description"], description_type: "Abstract" }]
      end

      # use default version 1.0
      metadata["version"] ||= "1.0"

      # fetch reference metadata if available
      metadata["related_identifiers"] = get_related_identifiers(metadata)

      if metadata["license"].present?
        metadata["license_name"] = LICENSES.fetch(metadata["license"], nil)
        metadata["license_url"] = metadata["license"]
      end

      metadata = metadata.extract!(*%w(publisher doi tags title author date
        publication_year publication_month publication_day license_name
        license_url))
    end

    def generate_jats_for_url(url, options={})
      filename, build_path, source_path = filepath_from_url(url, options)
      metadata = generate_metadata_for_jats(build_path, options)
      file = IO.read(source_path)
      content = Bergamasco::Markdown.split_yaml_frontmatter(file).last
      text = Bergamasco::Markdown.join_yaml_frontmatter(metadata, content)

      xml = Bergamasco::Pandoc.convert_to_jats(text, options)

      if metadata["doi"].present?
        xmlname = metadata["doi"].split('/', 2).last + ".xml"
      else
        xmlname = filename.gsub(/\.html\.(erb|md)/, ".xml")
      end

      xmlpath = build_path.gsub("index.html", xmlname)
      IO.write(xmlpath, xml)

      "JATS XML written for #{filename}"
    end

    def generate_jats_for_all_urls(url, options={})
      urls = get_urls_for_works(url)
      urls.map do |u|
        generate_jats_for_url(u, options)
      end.join("\n")
    end

    def url_from_path(site_url, filepath)
      site_url.to_s.chomp("\\") + "/" + File.basename(filepath)[0..-9] + "/"
    end

    def format_authors(authors)
      Array(authors).map do |author|
        orcid = orcid_from_url(author["@id"])
        name = (author["givenName"].present? || author["familyName"].present?) ? nil : author["name"]

        { :given_name => author["givenName"],
          :family_name => author["familyName"],
          :name => name,
          :orcid => orcid }.compact
      end
    end

    def get_related_identifiers(metadata)
      citations = Array(metadata["citation"])
      parent = [metadata["isPartOf"]].compact.map { |r| r.merge("relation_type" => "IsPartOf") }
      children = Array(metadata["hasPart"]).map { |r| r.merge("relation_type" => "HasPart") }

      (citations + parent + children).map do |r|
        id = r.fetch("@id", "")
        relation_type = r.fetch("relation_type", "References")

        if /(http|https):\/\/(dx\.)?doi\.org\/(\w+)/.match(id)
          uri = Addressable::URI.parse(id)
          value = uri.path[1..-1].upcase
          type = "DOI"
        elsif /(http|https):\/\//.match(id)
          uri = Addressable::URI.parse(id)
          value = uri.normalize.to_s
          type = "URL"
        else
          type = nil
        end

        {
          value: value,
          related_identifier_type: type,
          relation_type: relation_type
        }
      end.select { |t| t[:related_identifier_type].present? }
    end

    def format_media(metadata)
      [metadata["encoding"]].compact.map do |m|
        { mime_type: m["fileFormat"],
          url: m["@id"] }
      end
    end

    def filepath_from_url(url, options={})
      if doi_from_url(url)
        response = Maremma.head(url, limit: 0)
        url = response.headers.fetch("Location", "")
      end

      uri = Addressable::URI.parse(url.gsub(Dir.pwd + options[:build_dir].to_s, "")
                                      .gsub(/index\.html$/, "")
                                      .gsub(/\/$/, ""))
      basename = File.basename(uri.path, ".html").presence || "index"

      if basename.starts_with?("index")
        filename = basename + ".html.erb"
        source_path = Dir.pwd + options[:source_dir].to_s + filename
        build_path = Dir.pwd + options[:build_dir].to_s + basename + ".html"
      else
        filename = basename + ".html.md"
        source_path = Dir.pwd + options[:source_dir].to_s + options[:posts_dir].to_s + filename
        build_path = Dir.pwd + options[:build_dir].to_s + basename + "/index.html"
      end
      [filename, build_path, source_path]
    end

    def doi_from_url(url)
      return nil unless url.present?

      if /(http|https):\/\/(dx\.)?doi\.org\/(\w+)/.match(url)
        uri = Addressable::URI.parse(url)
        uri.path[1..-1].upcase
      elsif url.starts_with?("doi:")
        url[4..-1].upcase
      end
    end

    def orcid_from_url(url)
      return nil unless url.present?

      Array(/\Ahttp:\/\/orcid\.org\/(.+)/.match(url)).last
    end
  end
end
