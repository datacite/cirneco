require 'spec_helper'

describe MdsClientRuby::Work, vcr: true do
  let(:doi) { "10.5072/example-full"}
  let(:creators) { [{ given_name: "Elizabeth", family_name: "Miller", orcid: "0000-0001-5000-0007" }] }
  let(:title) { "Full DataCite XML Example" }
  let(:publisher) { "DataCite" }
  let(:publication_year) { 2014 }
  let(:resource_type) { { value: "XML", resource_type_general: "Software" } }
  let(:subjects) { ["000 computer science"] }
  let(:descriptions) { [{ value: "XML example of all DataCite Metadata Schema v4.0 properties.", description_type: "Abstract" }] }
  let(:rights) { [{ value: "CC0 1.0 Universal", rights_uri: "http://creativecommons.org/publicdomain/zero/1.0/" }] }
  let(:url) { "http://www.datacite.org" }
  let(:media) { [{ mime_type: "application/pdf", url:"http://www.datacite.org/mds-client-ruby-test.pdf" }]}
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:fixture_path) { "spec/fixtures/" }
  let(:samples_path) { "resources/kernel-4.0/samples/" }

  subject { MdsClientRuby::Work.new(doi: doi,
                                    creators: creators,
                                    title: title,
                                    publisher: publisher,
                                    publication_year: publication_year,
                                    resource_type: resource_type,
                                    subjects: subjects,
                                    descriptions: descriptions,
                                    rights: rights) }

  describe 'schema' do
    it 'validates example full' do
      validation_errors = subject.schema.validate(samples_path + 'datacite-example-full-v4.0.xml').map { |error| error.to_s }
      expect(validation_errors).to be_empty
    end

    it 'exists' do
      expect(subject.schema.errors).to be_empty
    end

    it 'validates data' do
      expect(subject.validation_errors).to be_empty
    end

    it 'validates work without resource_type_general with errors' do
      subject.resource_type[:resource_type_general] = nil
      expect(subject.validation_errors).to eq(["Element '{http://datacite.org/schema/kernel-4}resourceType', attribute 'resourceTypeGeneral': [facet 'enumeration'] The value '' is not an element of the set {'Audiovisual', 'Collection', 'Dataset', 'Event', 'Image', 'InteractiveResource', 'Model', 'PhysicalObject', 'Service', 'Software', 'Sound', 'Text', 'Workflow', 'Other'}.", "Element '{http://datacite.org/schema/kernel-4}resourceType', attribute 'resourceTypeGeneral': '' is not a valid value of the atomic type '{http://datacite.org/schema/kernel-4}resourceType'."])
    end

    it 'validates work without title with errors' do
      subject.title = nil
      expect(subject.validation_errors).to eq(["The document has no document element."])
    end
  end
end
