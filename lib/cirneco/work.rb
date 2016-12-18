require 'active_support/all'
require 'nokogiri'

require_relative 'api'
require_relative 'utils'
require_relative 'base'

module Cirneco
  class Work
    include Cirneco::Base
    include Cirneco::Api
    include Cirneco::Utils

    attr_accessor :doi, :url, :creators, :title, :publisher, :publication_year, :resource_type, :version, :related_identifiers, :rights_list, :descriptions, :contributors, :subjects, :media, :username, :password, :validation_errors

    def initialize(metadata, **options)
      @doi = metadata.fetch("doi", nil)
      @url = metadata.fetch("url", nil)
      @creators = metadata.fetch("creators", nil)
      @title = metadata.fetch("title", nil)
      @publisher = metadata.fetch("publisher", nil)
      @publication_year = metadata.fetch("publication_year", nil)
      @resource_type = metadata.fetch("resource_type", nil)
      @version = metadata.fetch("version", nil)
      @rights_list = metadata.fetch("rights_list", nil)
      @subjects = metadata.fetch("subjects", nil)
      @descriptions = metadata.fetch("descriptions", nil)
      @contributors = metadata.fetch("contributors", nil)
      @related_identifiers = metadata.fetch("related_identifiers", nil)

      @media = options.fetch(:media, nil)

      @username = options.fetch(:username, nil)
      @password = options.fetch(:password, nil)
    end

    SCHEMA = File.expand_path("../../../resources/kernel-4.0/metadata.xsd", __FILE__)

    def has_required_elements?
      doi && creators && title && publisher && publication_year && resource_type
    end

    def data
      return nil unless has_required_elements?

      Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.send(:'resource', root_attributes) do
          insert_work(xml)
        end
      end.to_xml
    end

    def insert_work(xml)
      insert_identifier(xml)
      insert_creators(xml)
      insert_titles(xml)
      insert_publisher(xml)
      insert_publication_year(xml)
      insert_resource_type(xml)
      insert_subjects(xml)
      insert_contributors(xml)
      insert_related_identifiers(xml)
      insert_version(xml)
      insert_rights_list(xml)
      insert_descriptions(xml)
    end

    def insert_identifier(xml)
      xml.identifier(doi, 'identifierType' => "DOI")
    end

    def insert_creators(xml)
      return nil unless creators.present?

      xml.creators do
        creators.each do |creator|
          xml.creator do
            insert_person(xml, creator, "creator")
          end
        end
      end
    end

    def insert_contributors(xml)
      return nil unless contributors.present?

      xml.contributors do
        contributors.each do |contributor|
          xml.contributor("contributorType" => contributor[:contributor_type]) do
            insert_person(xml, contributor, "contributor")
          end
        end
      end
    end

    def insert_person(xml, person, type)
      person_name = [person[:family_name], person[:given_name], person[:literal]].compact.join(", ")

      xml.send(:'creatorName', person_name) if type == "creator"
      xml.send(:'contributorName', person_name) if type == "contributor"
      xml.send(:'givenName', person[:given_name]) if person[:given_name].present?
      xml.send(:'familyName', person[:family_name]) if person[:family_name].present?
      xml.nameIdentifier(person[:orcid], 'schemeURI' => 'http://orcid.org/', 'nameIdentifierScheme' => 'ORCID') if person[:orcid].present?
    end

    def insert_titles(xml)
      xml.send(:'titles') do
        insert_title(xml)
      end
    end

    def insert_title(xml)
      xml.title(title)
    end

    def insert_publisher(xml)
      xml.publisher(publisher)
    end

    def insert_publication_year(xml)
      xml.publicationYear(publication_year)
    end

    def insert_subjects(xml)
      return xml unless subjects.present?

      xml.subjects do
        subjects.each do |subject|
          xml.subject(subject)
        end
      end
    end

    def insert_resource_type(xml)
      xml.resourceType(resource_type[:value], 'resourceTypeGeneral' => resource_type[:resource_type_general])
    end

    def insert_version(xml)
      return xml unless version.present?

      xml.version(version)
    end

    def insert_related_identifiers(xml)
      return xml unless related_identifiers.present?

      xml.relatedIdentifiers do
        related_identifiers.each do |related_identifier|
          xml.relatedIdentifier(related_identifier[:value], 'relatedIdentifierType' => related_identifier[:related_identifier_type], 'relationType' => related_identifier[:relation_type])
        end
      end
    end

    def insert_rights_list(xml)
      return xml unless rights_list.present?

      xml.rightsList do
        rights_list.each do |rights|
          xml.rights(rights[:value], 'rightsURI' => rights[:rights_uri])
        end
      end
    end

    def insert_descriptions(xml)
      return xml unless descriptions.present?

      xml.descriptions do
        descriptions.each do |description|
          xml.description(description[:value], 'descriptionType' => description[:description_type])
        end
      end
    end

    def without_control(s)
      r = ''
      s.each_codepoint do |c|
        if c >= 32
          r << c
        end
      end
      r
    end

    def root_attributes
      { :'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        :'xsi:schemaLocation' => 'http://datacite.org/schema/kernel-4 http://schema.datacite.org/meta/kernel-4/metadata.xsd',
        :'xmlns' => 'http://datacite.org/schema/kernel-4' }
    end

    def schema
      Nokogiri::XML::Schema(open(SCHEMA))
    end

    def validation_errors
      @validation_errors ||= schema.validate(Nokogiri::XML(data)).map { |error| error.to_s }
    end
  end
end
