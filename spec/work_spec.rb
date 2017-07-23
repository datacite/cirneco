require 'spec_helper'

describe Cirneco::Work, vcr: true do
  let(:input) { "https://blog.datacite.org/eating-your-own-dog-food/" }
  let(:media) { [{ mime_type: "application/pdf", url: "http://www.datacite.org/cirneco-test.pdf" }] }
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:fixture_path) { "spec/fixtures/" }
  let(:samples_path) { "resources/kernel-4.0/samples/" }

  subject { Cirneco::Work.new(input: input, from: "schema_org", media: media) }

  describe 'schema' do
    it "BlogPosting" do
      expect(subject.valid?).to be true
      expect(subject.id).to eq("https://doi.org/10.5438/0000-01hc")
      expect(subject.url).to eq("https://blog.datacite.org/eating-your-own-dog-food")
      expect(subject.type).to eq("BlogPosting")
      expect(subject.author).to eq("type"=>"Person", "id"=>"http://orcid.org/0000-0003-1419-2405", "name"=>"Martin Fenner", "givenName"=>"Martin", "familyName"=>"Fenner")
      expect(subject.title).to eq("Eating your own Dog Food")
      expect(subject.alternate_name).to eq("MS-49-3632-5083")
      expect(subject.description["text"]).to start_with("Eating your own dog food")
      expect(subject.keywords).to eq(["datacite", "doi", "metadata", "featured"])
      expect(subject.date_published).to eq("2016-12-20")
      expect(subject.date_modified).to eq("2016-12-20")
      expect(subject.is_part_of).to eq("id"=>"https://doi.org/10.5438/0000-00ss", "type"=>"Blog", "title"=>"DataCite Blog")
      expect(subject.references).to eq([{"id"=>"https://doi.org/10.5438/0012", "type"=>"CreativeWork"}, {"id"=>"https://doi.org/10.5438/55e5-t5c0", "type"=>"CreativeWork"}])
      expect(subject.publisher).to eq("DataCite")
    end

    it 'validates example full' do
      input = samples_path + 'datacite-example-full-v4.0.xml'
      subject = Cirneco::Work.new(input: input, from: "datacite")

      expect(subject.valid?).to be true
      expect(subject.id).to eq("https://doi.org/10.5072/example-full")
      expect(subject.type).to eq("SoftwareSourceCode")
      expect(subject.author).to eq("type"=>"Person", "id"=>"https://orcid.org/0000-0001-5000-0007", "name"=>"Miller, Elizabeth", "givenName"=>"Elizabeth", "familyName"=>"Miller")
      expect(subject.title).to eq([{"lang"=>"en-us", "text"=>"Full DataCite XML Example"}, {"title_type"=>"Subtitle", "lang"=>"en-us", "text"=>"Demonstration of DataCite Properties."}])
      expect(subject.alternate_name).to eq("type"=>"URL", "name"=>"http://schema.datacite.org/schema/meta/kernel-3.1/example/datacite-example-full-v3.1.xml")
      expect(subject.description["text"]).to start_with("XML example of all DataCite Metadata Schema v4.0 properties.")
      expect(subject.keywords).to eq([{"subject_scheme"=>"dewey", "scheme_uri"=>"http://dewey.info/", "text"=>"000 computer science"}])
      expect(subject.date_published).to eq("2014")
      expect(subject.date_modified).to eq("2014-10-17")
      expect(subject.publisher).to eq("DataCite")
    end
  end

  describe 'media' do
    it 'includes media' do
      expect(subject.media).to eq([{:mime_type=>"application/pdf", :url=>"http://www.datacite.org/cirneco-test.pdf"}])
    end
  end
end
